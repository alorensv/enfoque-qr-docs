# Plan de implementación: Pre-generación de QR y Enrolamiento de Equipos

## Contexto
Actualmente la plataforma genera códigos QR al momento de crear un equipo. El nuevo requerimiento es:

1. **Generación en fábrica**: Crear códigos QR en lote sin equipos asociados
2. **Enrolamiento en bodega**: Asociar un QR pre-generado a un equipo y agregar su información (descripción, documentos, etc.)
3. **Trazabilidad**: Mantener registro de qué códigos están disponibles, asignados o revocados

---

## Análisis del modelo actual

### Entidad `equipment_qr_codes`
La estructura actual **ya soporta este flujo**:
- `equipment_id`: Es nullable, permite QR sin equipo asociado ✓
- `token`: Identificador único del QR
- `assigned_at`: Fecha de asignación a un equipo
- `revoked_at`: Fecha de revocación (si se desactiva)
- `enabled`: Estado activo/inactivo

### Flujo actual
```
Crear Equipo → Generar QR → Asociar QR al equipo
```

### Nuevo flujo propuesto
```
Generar QR en lote (sin equipo) → Imprimir etiquetas → Enrolar equipo usando QR
```

---

## Plan de implementación

### 1. Backend: Endpoints para gestión de QR pre-generados

#### 1.1 Generar códigos QR en lote
**Endpoint**: `POST /qr/generate-batch`

**Payload**:
```json
{
  "quantity": 100,
  "prefix": "FAB-2026" // Opcional, para identificar lotes
}
```

**Respuesta**:
```json
{
  "success": true,
  "generated": 100,
  "batch_id": "batch-abc123",
  "qr_codes": [
    {
      "id": 1,
      "token": "qr_f4e8a9b2c1d3...",
      "url": "https://app.dominio.cl/qr/qr_f4e8a9b2c1d3...",
      "status": "available"
    }
  ]
}
```

**Lógica**:
- Generar N tokens únicos (usando UUID v4 o similar)
- Insertar en `equipment_qr_codes` con `equipment_id = NULL`
- Estado inicial: `enabled = 1`, `assigned_at = NULL`
- Retornar lista de tokens generados

#### 1.2 Listar QR disponibles para enrolamiento
**Endpoint**: `GET /qr/available`

**Query params**:
- `page`: Número de página
- `limit`: Registros por página
- `search`: Buscar por token

**Respuesta**:
```json
{
  "data": [
    {
      "id": 1,
      "token": "qr_f4e8a9b2c1d3...",
      "created_at": "2026-02-15T10:00:00Z",
      "status": "available"
    }
  ],
  "total": 100,
  "page": 1,
  "totalPages": 10
}
```

#### 1.3 Enrolar equipo usando QR pre-generado
**Endpoint**: `POST /equipment/enroll`

**Payload**:
```json
{
  "qr_token": "qr_f4e8a9b2c1d3...",
  "equipment_data": {
    "name": "Turbina Siemens XYZ",
    "serial_number": "SN-12345",
    "model": "XYZ-2000",
    "brand": "Siemens",
    "institution_id": 1,
    "location": "Sala 305",
    "description": "Turbina principal del área de producción"
  }
}
```

**Proceso**:
1. Validar que el `qr_token` existe
2. Validar que el QR no está asignado (`equipment_id IS NULL`)
3. Validar que el QR está activo (`enabled = 1` y `revoked_at IS NULL`)
4. Crear el equipo nuevo
5. Asociar el QR al equipo: `UPDATE equipment_qr_codes SET equipment_id = ?, assigned_at = NOW() WHERE token = ?`
6. Retornar equipo creado con su QR

**Respuesta**:
```json
{
  "success": true,
  "equipment": {
    "id": 123,
    "name": "Turbina Siemens XYZ",
    "serial_number": "SN-12345",
    "qr_code": {
      "token": "qr_f4e8a9b2c1d3...",
      "url": "https://app.dominio.cl/qr/qr_f4e8a9b2c1d3...",
      "assigned_at": "2026-02-23T14:30:00Z"
    }
  }
}
```

#### 1.4 Exportar QR para impresión
**Endpoint**: `GET /qr/export-batch/:batch_id`

**Formatos de exportación**:
- **CSV**: Lista de tokens y URLs para impresión masiva
- **PDF**: Documento con etiquetas imprimibles (N etiquetas por página)

**Respuesta CSV**:
```csv
id,token,url,created_at
1,qr_f4e8a9b2c1d3...,https://app.dominio.cl/qr/qr_f4e8a9b2c1d3...,2026-02-15T10:00:00Z
2,qr_a1b2c3d4e5...,https://app.dominio.cl/qr/qr_a1b2c3d4e5...,2026-02-15T10:00:01Z
```

#### 1.5 Revocar QR no utilizados
**Endpoint**: `POST /qr/:id/revoke`

**Uso**: Desactivar QR que no serán utilizados (pérdida, daño, etc.)

**Proceso**:
- Verificar que el QR no está asignado a un equipo
- Marcar `revoked_at = NOW()` y `enabled = 0`

---

### 2. Modificaciones al servicio QR (`qr.service.ts`)

#### 2.1 Método: `generateBatch(quantity: number, prefix?: string)`
```typescript
async generateBatch(quantity: number, prefix?: string): Promise<EquipmentQrCode[]> {
  const qrCodes: EquipmentQrCode[] = [];
  
  for (let i = 0; i < quantity; i++) {
    const token = this.generateUniqueToken(prefix);
    const qrCode = this.qrRepository.create({
      token,
      equipmentId: null,
      enabled: 1,
      assignedAt: null,
    });
    qrCodes.push(qrCode);
  }
  
  return await this.qrRepository.save(qrCodes);
}

private generateUniqueToken(prefix?: string): string {
  const uuid = crypto.randomUUID().replace(/-/g, '');
  return prefix ? `${prefix}_${uuid}` : `qr_${uuid}`;
}
```

#### 2.2 Método: `getAvailable(page: number, limit: number)`
```typescript
async getAvailable(page: number = 1, limit: number = 50) {
  const [data, total] = await this.qrRepository.findAndCount({
    where: {
      equipmentId: IsNull(),
      enabled: 1,
      revokedAt: IsNull(),
    },
    order: { createdAt: 'DESC' },
    skip: (page - 1) * limit,
    take: limit,
  });
  
  return {
    data,
    total,
    page,
    totalPages: Math.ceil(total / limit),
  };
}
```

#### 2.3 Método: `assignToEquipment(token: string, equipmentId: number)`
```typescript
async assignToEquipment(token: string, equipmentId: number): Promise<EquipmentQrCode> {
  const qrCode = await this.qrRepository.findOne({
    where: { token },
  });
  
  if (!qrCode) {
    throw new NotFoundException('Código QR no encontrado');
  }
  
  if (qrCode.equipmentId) {
    throw new BadRequestException('Este código QR ya está asignado a un equipo');
  }
  
  if (!qrCode.enabled || qrCode.revokedAt) {
    throw new BadRequestException('Este código QR no está disponible');
  }
  
  qrCode.equipmentId = equipmentId;
  qrCode.assignedAt = new Date();
  
  return await this.qrRepository.save(qrCode);
}
```

---

### 3. Modificaciones al servicio de Equipos (`equipment.service.ts`)

#### 3.1 Nuevo método: `enrollWithQR(qrToken: string, equipmentData: CreateEquipmentDto)`

```typescript
async enrollWithQR(qrToken: string, equipmentData: CreateEquipmentDto) {
  // Validar QR disponible
  const qrCode = await this.qrService.validateAvailableToken(qrToken);
  
  // Crear equipo
  const equipment = await this.create(equipmentData);
  
  // Asociar QR al equipo
  await this.qrService.assignToEquipment(qrToken, equipment.id);
  
  // Retornar equipo con QR
  return await this.findOne(equipment.id, { relations: ['qrCode'] });
}
```

#### 3.2 Modificar método `create()` para soportar QR opcional
- Si se recibe un `qr_token`, usar el QR pre-generado
- Si no, generar uno nuevo (comportamiento actual)

---

### 4. Frontend: Interfaces de usuario

#### 4.1 Página: Generar códigos QR en lote
**Ruta**: `/admin/qr/generate`

**Componentes**:
- Formulario para especificar cantidad de QR a generar
- Campo opcional para prefijo/identificador de lote
- Botón "Generar lote"
- Tabla con QR generados
- Botones de acción:
  - Descargar lista (CSV)
  - Descargar etiquetas para impresión (PDF)
  - Ver detalles del lote

**Wireframe**:
```
┌─────────────────────────────────────────────┐
│ Generar códigos QR en lote                  │
├─────────────────────────────────────────────┤
│ Cantidad: [____100____]                     │
│ Prefijo (opcional): [__FAB-2026__]          │
│ [Generar lote]                              │
├─────────────────────────────────────────────┤
│ Lotes generados:                            │
│ ┌───────────────────────────────────────┐   │
│ │ ID   | Fecha      | Cant. | Acciones │   │
│ │ #001 | 15/02/2026 | 100   | [CSV][PDF]│   │
│ │ #002 | 20/02/2026 | 50    | [CSV][PDF]│   │
│ └───────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

#### 4.2 Página: Enrolar equipo
**Ruta**: `/admin/equipos/enroll`

**Flujos de entrada**:
1. **Escanear QR**: Usar cámara o lector para capturar token
2. **Ingresar token manualmente**: Campo de texto

**Proceso**:
1. Escanear/ingresar token del QR
2. Sistema valida que el QR existe y está disponible
3. Mostrar formulario de creación de equipo
4. Completar datos del equipo
5. Guardar y asociar QR

**Wireframe**:
```
┌─────────────────────────────────────────────┐
│ Enrolar nuevo equipo                        │
├─────────────────────────────────────────────┤
│ Paso 1: Capturar código QR                  │
│ ┌─────────────────────────────────────┐     │
│ │ [📷 Escanear QR]  [✍️ Ingresar token]│     │
│ └─────────────────────────────────────┘     │
│                                             │
│ Token: qr_f4e8a9b2c1d3...  ✓ Disponible    │
├─────────────────────────────────────────────┤
│ Paso 2: Datos del equipo                    │
│ Nombre: [____________________________]      │
│ N° Serie: [____________________________]    │
│ Modelo: [____________________________]      │
│ Marca: [____________________________]       │
│ Ubicación: [____________________________]   │
│ Descripción:                                │
│ [________________________________]          │
│ [________________________________]          │
│                                             │
│ [Cancelar]  [Enrolar equipo]               │
└─────────────────────────────────────────────┘
```

#### 4.3 Componente: Escáner QR
**Librería sugerida**: `react-qr-scanner` o `html5-qrcode`

**Funcionalidad**:
- Acceder a la cámara del dispositivo
- Escanear código QR
- Extraer token automáticamente
- Validar en el backend

#### 4.4 Modificar página de equipos
**Agregar nueva opción**: "Enrolar con QR pre-generado"

Junto al botón "Crear nuevo equipo", agregar:
```
[+ Crear equipo]  [🏷️ Enrolar con QR]
```

---

### 5. Base de datos: Consideraciones adicionales

#### 5.1 Tabla de lotes (opcional)
Para mejor trazabilidad, se puede crear una tabla para registrar lotes:

```sql
CREATE TABLE qr_batches (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  batch_code VARCHAR(50) UNIQUE NOT NULL,
  prefix VARCHAR(50),
  quantity INT NOT NULL,
  created_by BIGINT UNSIGNED,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  notes TEXT,
  FOREIGN KEY (created_by) REFERENCES users(id)
);

ALTER TABLE equipment_qr_codes 
ADD COLUMN batch_id BIGINT UNSIGNED NULL,
ADD FOREIGN KEY (batch_id) REFERENCES qr_batches(id);

-- Nota: batch_id es nullable porque:
-- 1. Códigos QR existentes no pertenecen a lotes
-- 2. Se pueden generar códigos QR individuales sin lote
-- 3. Mantiene compatibilidad hacia atrás
```

#### 5.2 Índices recomendados
```sql
CREATE INDEX idx_equipment_id ON equipment_qr_codes(equipment_id);
CREATE INDEX idx_enabled ON equipment_qr_codes(enabled);
CREATE INDEX idx_assigned_at ON equipment_qr_codes(assigned_at);
CREATE INDEX idx_token ON equipment_qr_codes(token);
```

---

### 6. Validaciones y reglas de negocio

#### 6.1 Validaciones en generación de lote
- Cantidad mínima: 1
- Cantidad máxima: 1000 (por lote)
- Tokens únicos garantizados
- Prefijo máximo: 50 caracteres

#### 6.2 Validaciones en enrolamiento
- QR debe existir
- QR no debe estar asignado
- QR debe estar habilitado (`enabled = 1`)
- QR no debe estar revocado (`revoked_at IS NULL`)
- Serial number del equipo debe ser único (si aplica)

#### 6.3 Estados de un código QR
1. **Disponible**: `equipment_id IS NULL AND enabled = 1 AND revoked_at IS NULL`
2. **Asignado**: `equipment_id IS NOT NULL`
3. **Revocado**: `revoked_at IS NOT NULL OR enabled = 0`

---

### 7. Seguridad y permisos

#### 7.1 Roles y permisos
- **Generar lotes**: Solo usuarios admin o con rol "gestor de inventario"
- **Enrolar equipos**: Usuarios autorizados con permiso de creación de equipos
- **Revocar QR**: Solo administradores
- **Ver códigos disponibles**: Usuarios con permisos de equipos

#### 7.2 Auditoría
Registrar en logs:
- Quién generó cada lote
- Quién enroló cada equipo
- Quién revocó QR
- Intentos fallidos de enrolamiento

---

### 8. Flujo de usuario completo

#### Fase 1: Generación (Fábrica/Admin)
```
1. Admin accede a "Generar códigos QR"
2. Ingresa cantidad (ej: 100)
3. Opcionalmente agrega prefijo (ej: "FAB-2026")
4. Sistema genera 100 tokens únicos
5. Admin descarga PDF con etiquetas
6. Se imprimen y pegan en equipos
```

#### Fase 2: Enrolamiento (Bodega/Inventario)
```
1. Equipo llega a bodega con etiqueta QR
2. Usuario accede a "Enrolar equipo"
3. Escanea el código QR con la cámara
4. Sistema valida el token
5. Usuario completa formulario con datos del equipo
6. Sistema crea el equipo y lo asocia al QR
7. Ahora el equipo está disponible en el sistema con su QR
```

#### Fase 3: Uso normal
```
1. Cualquier persona escanea el QR del equipo
2. Accede a la ficha pública con toda su información
3. Puede ver documentos, mantenimientos, etc.
```

---

### 9. Roadmap de implementación

#### Sprint 1: Backend base (1 semana)
- [ ] Crear endpoint `POST /qr/generate-batch`
- [ ] Crear endpoint `GET /qr/available`
- [ ] Crear endpoint `POST /qr/:id/revoke`
- [ ] Implementar métodos en `qr.service.ts`
- [ ] Agregar validaciones

#### Sprint 2: Enrolamiento (1 semana)
- [ ] Crear endpoint `POST /equipment/enroll`
- [ ] Modificar `equipment.service.ts` para soportar enrolamiento
- [ ] Integrar servicio QR con servicio de equipos
- [ ] Pruebas de integración

#### Sprint 3: Frontend generación (1 semana)
- [ ] Crear página `/admin/qr/generate`
- [ ] Formulario de generación de lotes
- [ ] Vista de lotes generados
- [ ] Exportación a CSV

#### Sprint 4: Frontend enrolamiento (1 semana)
- [ ] Crear página `/admin/equipos/enroll`
- [ ] Implementar escáner QR con cámara
- [ ] Formulario de enrolamiento
- [ ] Validaciones en frontend

#### Sprint 5: Etiquetas e impresión (1 semana)
- [ ] Diseño de etiqueta QR imprimible
- [ ] Generación de PDF con etiquetas
- [ ] Endpoint de exportación de lote a PDF
- [ ] Optimizar layout para impresión

#### Sprint 6: Testing y refinamiento (1 semana)
- [ ] Pruebas end-to-end del flujo completo
- [ ] Auditoría de seguridad
- [ ] Optimización de rendimiento
- [ ] Documentación de usuario

---

### 10. Consideraciones técnicas

#### 10.1 Generación de tokens
- Usar `crypto.randomUUID()` para garantizar unicidad
- Formato: `qr_[uuid]` o `[prefix]_[uuid]`
- Longitud mínima: 32 caracteres

#### 10.2 Performance
- Generación de lotes grandes: usar transacciones en batch
- Índices en columnas de búsqueda frecuente
- Paginación en listados de QR

#### 10.3 Escalabilidad
- Si se generan millones de QR, considerar tabla de archivado para QR antiguos
- Implementar caché para tokens disponibles
- Considerar worker jobs para generación de lotes muy grandes

---

### 11. Pruebas a realizar

#### 11.1 Unitarias
- Generación de tokens únicos
- Validación de QR disponible
- Asignación de QR a equipo
- Revocación de QR

#### 11.2 Integración
- Flujo completo de generación → enrolamiento
- Validación de duplicados
- Manejo de errores

#### 11.3 E2E
- Usuario genera lote de 10 QR
- Usuario imprime etiquetas
- Usuario enrola 10 equipos usando los QR
- Verificar que todos los QR quedan asignados
- Intentar usar un QR ya asignado (debe fallar)

---

### 12. Métricas y monitoreo

#### 12.1 Métricas a rastrear
- Total de QR generados
- Total de QR disponibles
- Total de QR asignados
- Total de QR revocados
- Tiempo promedio entre generación y enrolamiento
- QR sin usar después de N días

#### 12.2 Dashboard admin
Crear vista con:
- Estadísticas de QR
- Últimos lotes generados
- QR pendientes de enrolamiento
- Gráficos de uso

---

### 13. Documentación pendiente

- [ ] Manual de usuario para generación de lotes
- [ ] Manual de usuario para enrolamiento
- [ ] Guía de troubleshooting
- [ ] API documentation (Swagger)

---

### 14. Posibles extensiones futuras

1. **Notificaciones**: Alertar cuando un lote de QR está a punto de agotarse
2. **Geolocalización**: Registrar dónde se enroló cada equipo
3. **App móvil**: Aplicación dedicada para enrolamiento en terreno
4. **NFC**: Soporte para etiquetas NFC además de QR
5. **Integración con ERP**: Sincronizar equipos con sistemas externos
6. **Historial de QR**: Registro completo del ciclo de vida de cada QR
7. **Lotes inteligentes**: Generar QR con patrones específicos por cliente/proyecto

---

## Resumen

Este plan permite implementar un sistema robusto de pre-generación de códigos QR que:

✅ Separa la generación de QR de la creación de equipos
✅ Permite generar etiquetas antes de tener los equipos en el sistema
✅ Facilita el enrolamiento rápido en bodega
✅ Mantiene trazabilidad completa del proceso
✅ Reutiliza la estructura de base de datos existente
✅ Se integra de forma natural con el flujo actual

**Tiempo estimado total**: 6-8 semanas
**Complejidad**: Media
**Impacto**: Alto (mejora significativa en el flujo de trabajo)
