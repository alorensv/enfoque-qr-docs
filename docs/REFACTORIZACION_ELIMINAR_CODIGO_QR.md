# Refactorización: Eliminación de tabla codigo_qr

**Fecha**: 2026-02-23  
**Objetivo**: Simplificar la arquitectura consolidando todas las funcionalidades de códigos QR en una sola tabla

---

## Resumen de cambios

La tabla `codigo_qr` era una tabla legacy que duplicaba información con `equipment_qr_codes`. Se ha eliminado completamente y toda su funcionalidad se ha consolidado en `equipment_qr_codes`.

---

## Cambios en la base de datos

### Tabla `equipment_qr_codes` - Nuevas columnas:
```sql
ALTER TABLE `equipment_qr_codes`
ADD COLUMN `url_publica` VARCHAR(255) NULL DEFAULT NULL,
ADD COLUMN `imagen_path` VARCHAR(255) NULL DEFAULT NULL;
```

Ahora `equipment_qr_codes` contiene:
- `token` - Identificador único del QR
- `equipment_id` - FK al equipo (nullable para QRs pre-generados)
- `url_publica` - URL pública del QR (ej: https://app.dominio.cl/qr/token)
- `imagen_path` - Ruta de la imagen PNG del QR (ej: /equipos/123/qr/qr_token.png)
- `enabled` - Estado activo/inactivo
- `assigned_at` - Fecha de asignación a equipo
- `revoked_at` - Fecha de revocación

### Tabla eliminada:
- ❌ `codigo_qr` - **ELIMINADA** (funcionalidad consolidada en `equipment_qr_codes`)

---

## Cambios en el backend

### Archivos modificados:

#### 1. **equipment_qr_code.entity.ts**
- ✅ Agregadas propiedades `urlPublica` e `imagenPath`
- ✅ Entidad ahora es autosuficiente para manejar todo el ciclo de vida del QR

#### 2. **qr.service.ts**
- ❌ Eliminado `qrRepository` (Repository<CodigoQr>)
- ✅ Nuevo método `createWithImage()` - Crea QR completo con imagen (para creación directa de equipos)
- ✅ Actualizado `assignToEquipment()` - Ahora genera la URL y la imagen al asignar el QR
- ✅ Métodos `findAll()` y `findByToken()` ahora usan `equipmentQrCodeRepository`

#### 3. **equipment.service.ts**
- ❌ Eliminado import de `CodigoQr` y `CodigoQrEstado`
- ✅ Método `create()` ahora usa `createWithImage()` del QrService
- ✅ Método `enrollWithQR()` simplificado - ya no crea entrada en codigo_qr
- ✅ Método `findQrsByEquipmentId()` consulta directamente `equipment_qr_codes`

#### 4. **qr.module.ts**
- ❌ Eliminado `CodigoQr` del TypeOrmModule.forFeature

#### 5. **app.module.ts**
- ❌ Eliminado import y referencia a `CodigoQr`

#### 6. **codigo_qr.entity.ts**
- ❌ Archivo **ELIMINADO**

---

## Migración de datos

### Script de migración: `docs/migracion_eliminar_codigo_qr.sql`

**Pasos en orden:**
1. ✅ Agregar columnas a `equipment_qr_codes`
2. ✅ Migrar datos de `codigo_qr` a `equipment_qr_codes` (UPDATE con JOIN)
3. ⚠️ Verificar migración (SELECT para comparar datos)
4. ⚠️ Eliminar tabla `codigo_qr` (DROP TABLE - **¡DESPUÉS DE VERIFICAR!**)

**Comando de verificación:**
```sql
SELECT 
    eqc.id,
    eqc.token,
    eqc.url_publica,
    eqc.imagen_path,
    eqc.equipment_id,
    cqr.url_publica as old_url,
    cqr.imagen_path as old_imagen
FROM equipment_qr_codes eqc
LEFT JOIN codigo_qr cqr ON eqc.token = cqr.token
ORDER BY eqc.id DESC
LIMIT 20;
```

---

## Flujo de trabajo actualizado

### Flujo 1: Crear equipo directamente (workflow original)
```
Usuario crea equipo
   ↓
EquipmentService.create()
   ↓
QrService.createWithImage()
   ↓
- Genera token único
- Crea URL pública
- Genera imagen PNG
- Guarda registro en equipment_qr_codes con equipmentId
```

### Flujo 2: Pre-generar QR y enrolar después (nuevo workflow)
```
FASE 1: Generación en fábrica
Usuario genera lote de 100 QRs
   ↓
QrService.generateBatch()
   ↓
- Genera 100 tokens únicos
- Guarda en equipment_qr_codes con equipmentId = NULL
- Sin URL ni imagen todavía

FASE 2: Enrolamiento en bodega
Usuario escanea QR y enrola equipo
   ↓
EquipmentService.enrollWithQR()
   ↓
QrService.assignToEquipment()
   ↓
- Crea equipo
- Genera URL pública
- Genera imagen PNG
- Actualiza equipment_qr_codes con equipmentId, URL e imagen
```

---

## Beneficios de la refactorización

✅ **Simplicidad**: Una sola fuente de verdad para códigos QR  
✅ **Consistencia**: No hay duplicación de datos entre tablas  
✅ **Mantenibilidad**: Menos código, menos entidades, menos bugs  
✅ **Performance**: Una tabla menos para hacer JOINs  
✅ **Flexibilidad**: Soporte nativo para QRs pre-generados y asignados

---

## Verificación post-migración

### Checklist:
- [ ] Ejecutar migración SQL (pasos 1-2)
- [ ] Verificar datos migrados (paso 3)
- [ ] Probar creación de equipo nuevo (con QR automático)
- [ ] Probar generación de batch de QRs
- [ ] Probar enrolamiento con QR pre-generado
- [ ] Verificar que las imágenes QR se generan correctamente
- [ ] Eliminar tabla `codigo_qr` (paso 4) **¡SOLO DESPUÉS DE TODO OK!**

---

## Notas importantes

⚠️ **ANTES de eliminar la tabla `codigo_qr`:**
1. Hacer backup completo de la base de datos
2. Ejecutar query de verificación
3. Probar todos los flujos de QR
4. Tener plan de rollback preparado

⚠️ **El campo `estado` de codigo_qr no se migró** porque:
- `enabled = 1` equivale a "GENERADO" o "ENROLADO"
- `enabled = 0` + `revokedAt != NULL` equivale a "ANULADO"
- La lógica de estado se maneja ahora con `enabled`, `assignedAt` y `revokedAt`

---

## Próximos pasos sugeridos

1. Ejecutar script de migración en entorno de desarrollo
2. Validar todos los flujos de QR
3. Ejecutar en producción (con backup)
4. Monitorear logs durante 1 semana
5. Eliminar tabla `codigo_qr` después de período de estabilidad
