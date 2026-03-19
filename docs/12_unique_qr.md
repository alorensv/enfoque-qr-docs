# QR Universal: Acceso por Número de Serie

---

## 📋 Resumen Ejecutivo

### Concepto
Implementar un **QR Universal por Institución** que permite buscar equipos por número de serie, complementando el sistema actual de QR específicos por equipo.

### Enfoque Recomendado
✅ **QR Universal con Segmentación por Institución**  
URL: `/qr/universal/{institution_slug}`

**Ejemplo**:
- Hospital Central: `/qr/universal/hospital-central`
- Clínica Los Andes: `/qr/universal/clinica-los-andes`

### Pasos de Implementación

#### **Paso 1: Actualizar Base de Datos** ⏱️ 1-2 horas
- [ok] Agregar campo `slug` a tabla `institutions`
- [ok] Agregar campos `search_type`, `search_query`, `institution_id` a `qr_scan_logs`
- [ok] Crear índices necesarios
- [ok] Migrar datos existentes (generar slugs para instituciones)

#### **Paso 2: Backend - Endpoint de Búsqueda** ⏱️ 3-4 horas
- [x] Crear endpoint `GET /equipment/search-by-serial/:institutionSlug/:serialNumber`
- [x] Implementar filtrado por institución
- [x] Agregar validación y sanitización de inputs
- [x] Implementar rate limiting (10 búsquedas/minuto)
- [x] Registrar logs de búsqueda con contexto de institución

#### **Paso 3: Backend - Gestión de Instituciones** ⏱️ 1-2 horas
- [x] Crear endpoint `GET /institutions/by-slug/:slug`
- [x] Actualizar entidad `Institution` con campo `slug`
- [x] Agregar validación de slug único

#### **Paso 4: Frontend - Página de Búsqueda** ⏱️ 4-6 horas
- [x] Crear página `/qr/universal/[institutionSlug].js`
- [x] Implementar formulario de búsqueda
- [x] Agregar validación de inputs
- [x] Implementar manejo de errores
- [x] Agregar feedback visual (loading, errores, éxito)

#### **Paso 5: Frontend - Admin** ⏱️ 3-4 horas
- [x] Crear página `/admin/qr-universal.js`
- [x] Mostrar QR universal de la institución
- [x] Implementar descarga de QR
- [x] Mostrar estadísticas de uso

#### **Paso 6: Testing** ⏱️ 3-4 horas
- [ ] Tests unitarios backend (búsqueda, validación, rate limiting)
- [ ] Tests de seguridad (aislamiento entre instituciones)
- [ ] Tests frontend (formulario, navegación, errores)
- [ ] Tests de integración end-to-end

#### **Paso 7: Documentación y Despliegue** ⏱️ 2-3 horas
- [ ] Documentar API endpoints
- [ ] Crear guía de usuario
- [ ] Preparar material de capacitación
- [ ] Desplegar en ambiente de staging
- [ ] Validación con usuarios piloto
- [ ] Despliegue a producción

### Tiempo Total Estimado
⏱️ **17-26 horas de desarrollo**

### Seguridad 🔒
- ✅ Aislamiento total entre instituciones
- ✅ Cada institución solo accede a sus equipos
- ✅ Rate limiting para prevenir abuso
- ✅ Logs detallados con trazabilidad
- ✅ Validación y sanitización de inputs

### Ventajas del Enfoque por Institución
1. **Seguridad**: Hospital A no puede buscar equipos de Hospital B
2. **Trazabilidad**: Métricas separadas por institución
3. **Escalabilidad**: Cada institución es independiente
4. **Simplicidad**: No requiere autenticación obligatoria

---

## Contexto del Requerimiento

El cliente consulta por la posibilidad de tener **un QR único/universal** que, en lugar de estar asociado a un equipo específico, permita:

1. Escanear el QR universal
2. Ingresar el número de serie del equipo manualmente
3. Acceder a la tarjeta completa del equipo (información, documentación, mantenciones)

### Diferencia con el sistema actual

**Sistema actual:**
- Cada equipo tiene su propio QR con token único
- Al escanear `/qr/{token}` se muestra directamente la información del equipo
- Requiere una etiqueta QR física por cada equipo

**Nuevo sistema propuesto:**
- Un solo QR universal accesible desde múltiples ubicaciones
- Al escanear `/qr/universal` se presenta un formulario de búsqueda
- El usuario ingresa el número de serie y accede a la misma tarjeta QR que el sistema actual

---

## Casos de Uso

### 1. **Consulta desde ubicaciones estratégicas**
   - Colocar un QR universal en la entrada de bodegas, talleres o áreas de trabajo
   - Personal puede escanear y buscar cualquier equipo por su número de serie
   - No requiere tener el equipo físico a la mano

### 2. **Equipos sin etiqueta QR**
   - Equipos antiguos que aún no tienen etiqueta QR física
   - Equipos en proceso de enrolamiento
   - Situaciones donde la etiqueta QR se ha dañado o perdido

### 3. **Personal técnico de campo**
   - Técnicos que necesitan consultar múltiples equipos
   - Un solo QR en su dispositivo o manual de trabajo
   - Reduce tiempo de búsqueda y necesidad de múltiples escaneos

### 4. **Verificación antes de asignación**
   - Validar que un equipo existe en el sistema antes de enrolar
   - Consultar información técnica sin tener acceso al QR específico
   - Auditorías y verificaciones de inventario

---

## Ventajas

✓ **Único punto de acceso**: Un solo QR físico puede dar acceso a todos los equipos del sistema  
✓ **Reducción de costos**: Menos impresión de etiquetas para consultas rápidas  
✓ **Flexibilidad**: Útil cuando el QR específico no está disponible  
✓ **Backup**: Método alternativo si el QR individual está dañado  
✓ **Escalabilidad**: Funciona independientemente de cuántos equipos haya  
✓ **Ubicuidad**: Se puede colocar en múltiples ubicaciones físicas  

---

## Estrategia de Coexistencia

### **Ambos sistemas funcionando en paralelo**

El diseño propuesto permite que **ambos sistemas coexistan sin conflicto**:

```
┌─────────────────────────────────────────────────────────┐
│                    Sistema EnfoqueQR                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────┐  ┌──────────────────────┐   │
│  │   QR ESPECÍFICO      │  │   QR UNIVERSAL       │   │
│  │   (Existente)        │  │   (Nuevo)            │   │
│  ├──────────────────────┤  ├──────────────────────┤   │
│  │ • 1 QR por equipo    │  │ • 1 QR para todos    │   │
│  │ • Acceso directo     │  │ • Requiere búsqueda  │   │
│  │ • En el equipo físico│  │ • En ubicaciones     │   │
│  │                      │  │   estratégicas       │   │
│  │ URL: /qr/{token}     │  │ URL: /qr/universal   │   │
│  └──────────────────────┘  └──────────────────────┘   │
│           │                          │                 │
│           └──────────┬───────────────┘                 │
│                      ▼                                 │
│         ┌────────────────────────┐                     │
│         │  Misma Tarjeta QR      │                     │
│         │  (Vista unificada)     │                     │
│         └────────────────────────┘                     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Punto clave**: Ambos métodos conducen a la **misma vista final** (la tarjeta del equipo), solo cambia el método de acceso.

---

### **Agrupación por Contexto de Uso**

#### **Grupo A: Trabajo en Terreno / Inspección Física**
- **Método recomendado**: QR Específico
- **Usuarios**: Técnicos, operadores, inspectores
- **Escenario**: Estar frente al equipo
- **Ventaja principal**: Velocidad (1 escaneo → información)

#### **Grupo B: Trabajo de Oficina / Planificación**
- **Método recomendado**: QR Universal
- **Usuarios**: Supervisores, personal administrativo, bodegueros
- **Escenario**: Consultar sin tener el equipo presente
- **Ventaja principal**: Flexibilidad (múltiples consultas desde un punto)

#### **Grupo C: Personal Móvil / Auditoría**
- **Método recomendado**: Ambos (según disponibilidad)
- **Usuarios**: Auditores, gerentes, personal de mantenimiento
- **Escenario**: Verificación de múltiples equipos en diferentes ubicaciones
- **Ventaja principal**: Tener opciones según la situación

---

### **Diferenciación en Base de Datos**

El sistema ya soporta la diferenciación a través del campo `search_type` en los logs:

```typescript
// Estructura de log unificada
interface QrScanLog {
  id: number;
  qr_code_id: number;        // ID del QR del equipo
  search_type: 'direct' | 'universal';  // ← Diferenciador clave
  search_query?: string;     // Solo para búsquedas universales
  ip: string;
  user_agent: string;
  scanned_at: Date;
}
```

**Ejemplos de logs**:

```typescript
// Log de QR específico
{
  qr_code_id: 123,
  search_type: 'direct',
  search_query: null,
  ip: '192.168.1.100',
  scanned_at: '2026-03-02T10:30:00Z'
}

// Log de QR universal
{
  qr_code_id: 123,
  search_type: 'universal',
  search_query: 'SN-2024-001',
  ip: '192.168.1.100',
  scanned_at: '2026-03-02T10:35:00Z'
}
```

Esto permite análisis separado sin duplicar estructura de datos.

---

### **Agrupación en Interface de Usuario**

**Propuesta de sección en Admin Dashboard**:

```jsx
// Componente React para admin
<QRManagementTabs>
  <Tab label="QR por Equipo" count={1234}>
    <EquipmentQRList 
      showGenerateButton={true}
      showPrintLabels={true}
      filterBy={['active', 'damaged', 'missing']}
    />
  </Tab>
  
  <Tab label="QR Universal" count={1}>
    <UniversalQRManager
      showStatistics={true}
      showDownloadButton={true}
      showUsageAnalytics={true}
    />
  </Tab>
  
  <Tab label="Comparativa" icon="📊">
    <QRUsageComparison
      period="last_30_days"
      metrics={['scans', 'unique_users', 'success_rate']}
    />
  </Tab>
</QRManagementTabs>
```

---

## Consideraciones de Seguridad

### Acceso público vs privado
- El QR universal debe tener las **mismas restricciones** que los QR individuales
- Documentos privados solo se muestran si el usuario está autenticado
- El número de serie es información "conocible" (está en la placa del equipo)

### Validación de entrada
- Sanitizar el input del número de serie
- Protección contra inyección SQL y XSS
- Rate limiting para prevenir ataques de fuerza bruta

### Trazabilidad
- Registrar búsquedas realizadas desde el QR universal
- Guardar IP, user-agent, timestamp y serial number buscado
- Diferenciar logs de QR específico vs QR universal

---

## Plan de Implementación

### **Fase 1: Backend**

#### 1.1 Actualizar tabla `institutions` con campo `slug`

**Objetivo**: Agregar identificador único amigable para URLs por institución.

**Script SQL**:
```sql
-- 1. Agregar campo slug
ALTER TABLE institutions 
ADD COLUMN slug VARCHAR(100) NULL AFTER name;

-- 2. Generar slugs para instituciones existentes (ejemplo de migración)
UPDATE institutions 
SET slug = LOWER(REPLACE(REPLACE(name, ' ', '-'), 'á', 'a'))
WHERE slug IS NULL;

-- Ejemplos de transformación:
-- 'Hospital Central' → 'hospital-central'
-- 'Clínica Los Andes' → 'clinica-los-andes'
-- 'Taller Industrial XYZ' → 'taller-industrial-xyz'

-- 3. Hacer el campo obligatorio y único
ALTER TABLE institutions 
MODIFY COLUMN slug VARCHAR(100) NOT NULL UNIQUE;

-- 4. Crear índice para búsquedas rápidas
CREATE INDEX idx_institutions_slug ON institutions(slug);
```

**Actualizar entidad NestJS**:
```typescript
// src/models/institution.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, OneToMany } from 'typeorm';

@Entity('institutions')
export class Institution {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ length: 255 })
  name: string;

  @Column({ length: 100, unique: true })
  slug: string;

  @Column({ type: 'text', nullable: true })
  address: string;

  @Column({ nullable: true })
  phone: string;

  @Column({ type: 'tinyint', default: 1 })
  status: number;

  @Column({ type: 'timestamp', nullable: true })
  deleted_at: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  created_at: Date;

  @Column({ 
    type: 'timestamp', 
    default: () => 'CURRENT_TIMESTAMP',
    onUpdate: 'CURRENT_TIMESTAMP'
  })
  updated_at: Date;

  // Relaciones
  @OneToMany(() => Equipment, equipment => equipment.institution)
  equipments: Equipment[];

  @OneToMany(() => User, user => user.institution)
  users: User[];
}
```

**Crear servicio para gestión de slugs**:
```typescript
// src/common/slug.service.ts
import { Injectable } from '@nestjs/common';

@Injectable()
export class SlugService {
  /**
   * Genera un slug amigable para URL a partir de un texto
   * @param text Texto a convertir en slug
   * @returns Slug generado
   */
  generateSlug(text: string): string {
    return text
      .toLowerCase()
      .normalize('NFD') // Descomponer caracteres con acentos
      .replace(/[\u0300-\u036f]/g, '') // Eliminar diacríticos
      .replace(/[^a-z0-9\s-]/g, '') // Eliminar caracteres especiales
      .trim()
      .replace(/\s+/g, '-') // Espacios a guiones
      .replace(/-+/g, '-'); // Múltiples guiones a uno solo
  }

  /**
   * Genera un slug único verificando existencia en BD
   * @param text Texto base
   * @param checkExists Función que verifica si el slug ya existe
   * @returns Slug único
   */
  async generateUniqueSlug(
    text: string,
    checkExists: (slug: string) => Promise<boolean>
  ): Promise<string> {
    let slug = this.generateSlug(text);
    let counter = 1;
    let finalSlug = slug;

    while (await checkExists(finalSlug)) {
      finalSlug = `${slug}-${counter}`;
      counter++;
    }

    return finalSlug;
  }
}
```

**Actualizar servicio de instituciones**:
```typescript
// src/institutions/institutions.service.ts (fragmento)
import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';
import { Institution } from '../models/institution.entity';
import { SlugService } from '../common/slug.service';

@Injectable()
export class InstitutionsService {
  constructor(
    @InjectRepository(Institution)
    private institutionRepository: Repository<Institution>,
    private slugService: SlugService
  ) {}

  /**
   * Buscar institución por slug
   */
  async findBySlug(slug: string): Promise<Institution> {
    const institution = await this.institutionRepository.findOne({
      where: { 
        slug,
        status: 1,
        deleted_at: IsNull()
      }
    });

    if (!institution) {
      throw new NotFoundException(`Institución con slug '${slug}' no encontrada`);
    }

    return institution;
  }

  /**
   * Crear institución con slug automático
   */
  async create(name: string, data: Partial<Institution>): Promise<Institution> {
    // Generar slug único
    const slug = await this.slugService.generateUniqueSlug(
      name,
      async (s) => {
        const existing = await this.institutionRepository.findOne({
          where: { slug: s }
        });
        return !!existing;
      }
    );

    const institution = this.institutionRepository.create({
      name,
      slug,
      ...data
    });

    return this.institutionRepository.save(institution);
  }

  /**
   * Actualizar institución (regenerar slug si cambia el nombre)
   */
  async update(id: number, data: Partial<Institution>): Promise<Institution> {
    const institution = await this.institutionRepository.findOne({
      where: { id }
    });

    if (!institution) {
      throw new NotFoundException('Institución no encontrada');
    }

    // Si cambia el nombre, regenerar slug
    if (data.name && data.name !== institution.name) {
      const newSlug = await this.slugService.generateUniqueSlug(
        data.name,
        async (s) => {
          const existing = await this.institutionRepository.findOne({
            where: { slug: s }
          });
          return existing && existing.id !== id;
        }
      );
      data.slug = newSlug;
    }

    await this.institutionRepository.update(id, data);
    return this.findOne(id);
  }
}
```

**Crear endpoint para buscar por slug**:
```typescript
// src/institutions/institutions.controller.ts (fragmento)
import { Controller, Get, Param } from '@nestjs/common';

@Controller('institutions')
export class InstitutionsController {
  constructor(private readonly institutionsService: InstitutionsService) {}

  @Get('by-slug/:slug')
  async findBySlug(@Param('slug') slug: string) {
    return this.institutionsService.findBySlug(slug);
  }
}
```

---

#### 1.2 Crear endpoint de búsqueda por serial number con filtrado por institución

#### 1.2 Crear endpoint de búsqueda por serial number con filtrado por institución

**Endpoint**: `GET /equipment/search-by-serial/:institutionSlug/:serialNumber`

**Parámetros**:
- `institutionSlug`: Identificador único de la institución (en la URL)
- `serialNumber`: Número de serie del equipo (en la URL)

**Respuesta exitosa** (200):
```json
{
  "success": true,
  "equipment": {
    "id": 123,
    "name": "Compresor ABC-500",
    "serial_number": "SN-2024-001",
    "description": "Compresor de aire industrial",
    "status": "activo",
    "equipment_photo": "/equipos/123/photo.jpg",
    "institution": {
      "id": 1,
      "name": "Hospital Central",
      "slug": "hospital-central"
    },
    "qr_code": {
      "token": "qr_abc123...",
      "url_publica": "https://app.dominio.cl/qr/qr_abc123..."
    },
    "last_maintenance": {
      "id": 45,
      "performed_at": "2026-02-28",
      "status": "completado",
      "technician": "Juan Pérez"
    }
  }
}
```

**Respuesta no encontrado** (404):
```json
{
  "success": false,
  "message": "Equipo con número de serie SN-2024-001 no encontrado en Hospital Central"
}
```

**Respuesta institución no encontrada** (404):
```json
{
  "success": false,
  "message": "Institución no encontrada"
}
```

**Lógica del endpoint**:
```typescript
// equipment.controller.ts
import { Controller, Get, Param, Req, UseGuards, BadRequestException } from '@nestjs/common';
import { ThrottlerGuard, Throttle } from '@nestjs/throttler';
import { Request } from 'express';

@Controller('equipment')
export class EquipmentController {
  constructor(private readonly equipmentService: EquipmentService) {}

  @Get('search-by-serial/:institutionSlug/:serialNumber')
  @UseGuards(ThrottlerGuard)
  @Throttle(10, 60) // 10 búsquedas por minuto
  async searchBySerialInInstitution(
    @Param('institutionSlug') institutionSlug: string,
    @Param('serialNumber') serialNumber: string,
    @Req() req: Request
  ) {
    // Sanitizar y validar input
    const cleanSerial = serialNumber.trim().toUpperCase();
    const cleanSlug = institutionSlug.trim().toLowerCase();
    
    if (!cleanSerial || cleanSerial.length < 3) {
      throw new BadRequestException('Número de serie inválido');
    }
    
    return this.equipmentService.searchBySerialInInstitution(
      cleanSlug,
      cleanSerial,
      req
    );
  }
}
```

```typescript
// equipment.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';
import { Equipment } from '../models/equipment.entity';
import { Institution } from '../models/institution.entity';
import { QrScanLogService } from '../qr/qr-scan-log.service';
import { Request } from 'express';

@Injectable()
export class EquipmentService {
  constructor(
    @InjectRepository(Equipment)
    private equipmentRepository: Repository<Equipment>,
    @InjectRepository(Institution)
    private institutionRepository: Repository<Institution>,
    private qrScanLogService: QrScanLogService
  ) {}

  async searchBySerialInInstitution(
    institutionSlug: string,
    serialNumber: string,
    req: Request
  ): Promise<Equipment> {
    // 1. Validar que la institución existe
    const institution = await this.institutionRepository.findOne({
      where: { 
        slug: institutionSlug,
        status: 1,
        deleted_at: IsNull()
      }
    });
    
    if (!institution) {
      throw new NotFoundException('Institución no encontrada');
    }
    
    // 2. Buscar equipo SOLO dentro de esa institución
    const equipment = await this.equipmentRepository.findOne({
      where: { 
        serial_number: serialNumber,
        institution_id: institution.id, // ← Filtro crítico de seguridad
        deleted_at: IsNull()
      },
      relations: [
        'qr_code',
        'maintenances',
        'documents',
        'institution'
      ]
    });
    
    if (!equipment) {
      throw new NotFoundException(
        `Equipo con número de serie ${serialNumber} no encontrado en ${institution.name}`
      );
    }
    
    // 3. Registrar log de búsqueda universal con contexto de institución
    if (equipment.qr_code) {
      await this.qrScanLogService.create({
        qr_code_id: equipment.qr_code.id,
        ip: req.ip,
        user_agent: req.headers['user-agent'],
        search_type: 'universal',
        search_query: serialNumber,
        institution_id: institution.id,
        scanned_at: new Date()
      });
    }
    
    return equipment;
  }
}
```

---

#### 1.3 Modificar el sistema de logs de escaneo

#### 1.3 Modificar el sistema de logs de escaneo

**Tabla**: `qr_scan_logs`

**Agregar campos**: `search_type`, `search_query`, `institution_id`

```sql
-- 1. Agregar campo search_type
ALTER TABLE qr_scan_logs 
ADD COLUMN search_type ENUM('direct', 'universal') DEFAULT 'direct' 
COMMENT 'Tipo de acceso: directo por QR específico o búsqueda universal';

-- 2. Agregar campo search_query
ALTER TABLE qr_scan_logs
ADD COLUMN search_query VARCHAR(255) DEFAULT NULL 
COMMENT 'Serial number buscado en caso de búsqueda universal';

-- 3. Agregar campo institution_id para contexto
ALTER TABLE qr_scan_logs
ADD COLUMN institution_id BIGINT UNSIGNED NULL 
COMMENT 'Institución desde la cual se realizó la búsqueda universal';

-- 4. Crear foreign key
ALTER TABLE qr_scan_logs
ADD CONSTRAINT fk_qr_scan_logs_institution
FOREIGN KEY (institution_id) REFERENCES institutions(id)
ON DELETE SET NULL;

-- 5. Crear índices para consultas de trazabilidad
CREATE INDEX idx_qr_scan_logs_search_type ON qr_scan_logs(search_type);
CREATE INDEX idx_qr_scan_logs_search_query ON qr_scan_logs(search_query);
CREATE INDEX idx_qr_scan_logs_institution ON qr_scan_logs(institution_id);
CREATE INDEX idx_qr_scan_logs_type_institution ON qr_scan_logs(search_type, institution_id);
```

**Actualizar entidad**:
```typescript
// qr_scan_log.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, JoinColumn } from 'typeorm';
import { QrCode } from './equipment_qr_code.entity';
import { Institution } from './institution.entity';

@Entity('qr_scan_logs')
export class QrScanLog {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  qr_code_id: number;

  @Column({
    type: 'enum',
    enum: ['direct', 'universal'],
    default: 'direct'
  })
  search_type: 'direct' | 'universal';

  @Column({ nullable: true })
  search_query: string;

  @Column({ nullable: true })
  institution_id: number;

  @Column({ length: 45 })
  ip: string;

  @Column({ type: 'text', nullable: true })
  user_agent: string;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  scanned_at: Date;

  // Relaciones
  @ManyToOne(() => QrCode)
  @JoinColumn({ name: 'qr_code_id' })
  qr_code: QrCode;

  @ManyToOne(() => Institution)
  @JoinColumn({ name: 'institution_id' })
  institution: Institution;
}
```

**Registrar log de búsqueda universal**:
```typescript
// qr-scan-log.service.ts
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { QrScanLog } from '../models/qr_scan_log.entity';

@Injectable()
export class QrScanLogService {
  constructor(
    @InjectRepository(QrScanLog)
    private qrScanLogRepository: Repository<QrScanLog>
  ) {}

  /**
   * Registrar log de escaneo o búsqueda
   */
  async create(data: {
    qr_code_id: number;
    ip: string;
    user_agent: string;
    search_type?: 'direct' | 'universal';
    search_query?: string;
    institution_id?: number;
    scanned_at?: Date;
  }): Promise<QrScanLog> {
    const log = this.qrScanLogRepository.create({
      ...data,
      search_type: data.search_type || 'direct',
      scanned_at: data.scanned_at || new Date()
    });

    return this.qrScanLogRepository.save(log);
  }

  /**
   * Obtener estadísticas de uso por institución
   */
  async getStatsByInstitution(institutionId: number, days: number = 30) {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    return this.qrScanLogRepository
      .createQueryBuilder('log')
      .select([
        'log.search_type',
        'COUNT(*) as total',
        'COUNT(DISTINCT log.qr_code_id) as unique_equipments',
        'COUNT(DISTINCT log.ip) as unique_ips'
      ])
      .where('log.institution_id = :institutionId', { institutionId })
      .andWhere('log.scanned_at >= :startDate', { startDate })
      .groupBy('log.search_type')
      .getRawMany();
  }
}
```

---

#### 1.4 Validación y seguridad

#### 1.4 Validación y seguridad

**Rate limiting ya implementado en el controller** (ver sección 1.2)

**Validaciones adicionales**:
```typescript
// equipment.service.ts (métodos adicionales de validación)

/**
 * Validar formato de número de serie (opcional, ajustar según formato institucional)
 */
private isValidSerialFormat(serial: string): boolean {
  // Ejemplo: SN-YYYY-NNN o similar
  const regex = /^[A-Z0-9]{2,}-[0-9]{4}-[0-9]{3,}$/;
  return regex.test(serial);
}

/**
 * Sanitizar entrada del usuario
 */
private sanitizeSerialNumber(serial: string): string {
  return serial
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9-]/g, ''); // Solo letras, números y guiones
}
```

**Tests de seguridad**:
```typescript
// equipment.service.spec.ts
describe('EquipmentService - Security Tests', () => {
  it('debe prevenir búsquedas entre instituciones', async () => {
    // Setup: Equipo pertenece a hospital-central
    const equipment = await createTestEquipment({
      serial_number: 'SN-2024-001',
      institution_slug: 'hospital-central'
    });

    // Intentar buscar desde otra institución
    await expect(
      service.searchBySerialInInstitution(
        'clinica-los-andes',
        'SN-2024-001',
        mockRequest
      )
    ).rejects.toThrow(NotFoundException);
  });

  it('debe sanitizar inputs maliciosos', async () => {
    const maliciousInput = "SN-2024-001'; DROP TABLE equipments; --";
    const sanitized = service['sanitizeSerialNumber'](maliciousInput);
    
    expect(sanitized).toBe('SN-2024-001DROPTABLEEQUIPMENTS--');
    expect(sanitized).not.toContain("'");
    expect(sanitized).not.toContain(';');
  });

  it('debe registrar institución en logs de búsqueda', async () => {
    await service.searchBySerialInInstitution(
      'hospital-central',
      'SN-2024-001',
      mockRequest
    );

    const log = await qrScanLogRepository.findOne({
      where: { search_query: 'SN-2024-001' }
    });

    expect(log.search_type).toBe('universal');
    expect(log.institution_id).toBeDefined();
  });
});
```

---

### **Fase 2: Frontend**

#### 2.1 Crear página de búsqueda universal por institución

**Archivo**: `front/pages/qr/universal/[institutionSlug].js`

#### 2.1 Crear página de búsqueda universal por institución

**Archivo**: `front/pages/qr/universal/[institutionSlug].js`

```jsx
import { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import api from '../../../services/api';

export default function UniversalQRSearchByInstitution() {
  const router = useRouter();
  const { institutionSlug } = router.query;
  const [institutionName, setInstitutionName] = useState('');
  const [serialNumber, setSerialNumber] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  // Cargar información de la institución
  useEffect(() => {
    if (!institutionSlug) return;
    
    const fetchInstitution = async () => {
      try {
        const response = await api.get(`/institutions/by-slug/${institutionSlug}`);
        if (response.data && response.data.name) {
          setInstitutionName(response.data.name);
        }
      } catch (err) {
        setError('Institución no encontrada');
      }
    };

    fetchInstitution();
  }, [institutionSlug]);

  const handleSearch = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const response = await api.get(
        `/equipment/search-by-serial/${institutionSlug}/${serialNumber.trim()}`
      );
      
      if (response.data.success && response.data.equipment.qr_code) {
        // Redirigir a la tarjeta QR estándar del equipo
        const token = response.data.equipment.qr_code.token;
        router.push(`/qr/${token}`);
      } else {
        setError('Equipo encontrado pero no tiene código QR asignado');
      }
    } catch (err) {
      if (err.response?.status === 404) {
        setError(`No se encontró un equipo con ese número de serie en ${institutionName}`);
      } else if (err.response?.status === 429) {
        setError('Demasiadas búsquedas. Por favor, espera un momento.');
      } else {
        setError('Error al buscar el equipo. Intenta nuevamente.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <div className="max-w-md w-full bg-white rounded-lg shadow-lg p-8">
        
        {/* Logo e institución */}
        <div className="text-center mb-8">
          <h1 className="text-2xl font-bold text-gray-800 mb-2">
            Búsqueda de Equipos
          </h1>
          {institutionName && (
            <p className="text-blue-600 text-sm font-semibold mb-4">
              📍 {institutionName}
            </p>
          )}
          <p className="text-gray-600 text-sm">
            Ingresa el número de serie del equipo
          </p>
        </div>

        {/* Formulario */}
        <form onSubmit={handleSearch} className="space-y-4">
          <div>
            <label 
              htmlFor="serial" 
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              Número de Serie
            </label>
            <input
              id="serial"
              type="text"
              value={serialNumber}
              onChange={(e) => setSerialNumber(e.target.value)}
              placeholder="Ej: SN-2024-001"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              required
              disabled={loading}
              autoFocus
            />
          </div>

          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading || !serialNumber.trim()}
            className="w-full bg-blue-600 hover:bg-blue-700 text-white font-medium py-3 px-4 rounded-lg transition disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? 'Buscando...' : 'Buscar Equipo'}
          </button>
        </form>

        {/* Footer */}
        <div className="mt-6 pt-6 border-t border-gray-200">
          <p className="text-xs text-gray-500 text-center">
            🔍 Búsqueda limitada a equipos de {institutionName || 'esta institución'}
          </p>
          <p className="text-xs text-gray-400 text-center mt-2">
            El número de serie se encuentra en la placa del equipo
          </p>
        </div>
      </div>
    </div>
  );
}
```

#### 2.2 Generar QR universal por institución

**Cada institución tiene su propio QR universal** con URL única basada en el slug.

**Opción A: Generar QR offline**

```bash
# Para Hospital Central (slug: hospital-central)
qrencode -o qr-universal-hospital-central.png "https://app.dominio.cl/qr/universal/hospital-central"

# Para Clínica Los Andes (slug: clinica-los-andes)
qrencode -o qr-universal-clinica-los-andes.png "https://app.dominio.cl/qr/universal/clinica-los-andes"
```

**Opción B: Endpoint dinámico para generar imagen del QR**

```typescript
// qr.controller.ts
import { Controller, Get, Param, Res, NotFoundException } from '@nestjs/common';
import { Response } from 'express';
import * as QRCode from 'qrcode';

@Controller('qr')
export class QrController {
  constructor(
    private readonly institutionService: InstitutionService
  ) {}

  @Get('generate-universal/:institutionSlug')
  async generateUniversalQR(
    @Param('institutionSlug') institutionSlug: string,
    @Res() res: Response
  ) {
    // Verificar que la institución existe
    const institution = await this.institutionService.findBySlug(institutionSlug);
    
    if (!institution) {
      throw new NotFoundException('Institución no encontrada');
    }

    // Generar URL del QR universal para esta institución
    const url = `${process.env.APP_URL}/qr/universal/${institutionSlug}`;
    
    // Generar imagen QR
    const qrImage = await QRCode.toBuffer(url, {
      width: 500,
      margin: 2,
      errorCorrectionLevel: 'H',
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });
    
    res.setHeader('Content-Type', 'image/png');
    res.setHeader('Content-Disposition', `inline; filename="qr-universal-${institutionSlug}.png"`);
    res.send(qrImage);
  }
}
```

**Opción C: Generación dinámica en frontend**

```jsx
// Usando biblioteca qrcode.react
import QRCode from 'qrcode.react';

function UniversalQRDisplay({ institutionSlug }) {
  const universalUrl = `${window.location.origin}/qr/universal/${institutionSlug}`;
  
  return (
    <div className="qr-container">
      <QRCode
        value={universalUrl}
        size={300}
        level="H"
        includeMargin={true}
      />
      <p className="text-sm mt-2">{universalUrl}</p>
    </div>
  );
}
```

---

#### 2.3 Página de gestión de QR universal (Admin)

#### 2.3 Página de gestión de QR universal (Admin)

**Archivo**: `front/pages/admin/qr-universal.js`

```jsx
import { useState, useEffect } from 'react';
import AdminLayout from '../../components/AdminLayout';
import QRCode from 'qrcode.react';
import { useAuth } from '../../contexts/AuthContext';
import api from '../../services/api';

export default function QRUniversalManager() {
  const { user } = useAuth();
  const [institution, setInstitution] = useState(null);
  const [universalQRUrl, setUniversalQRUrl] = useState('');
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user?.institutionId) return;
    
    const fetchData = async () => {
      try {
        // Cargar datos de la institución
        const instResponse = await api.get(`/institutions/${user.institutionId}`, {
          withCredentials: true
        });
        
        setInstitution(instResponse.data);
        
        // Generar URL del QR universal
        const baseUrl = window.location.origin;
        setUniversalQRUrl(`${baseUrl}/qr/universal/${instResponse.data.slug}`);
        
        // Cargar estadísticas (opcional)
        const statsResponse = await api.get(
          `/analytics/qr-universal-stats/${instResponse.data.slug}`,
          { withCredentials: true }
        );
        setStats(statsResponse.data);
        
      } catch (error) {
        console.error('Error cargando datos:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [user]);

  const handleDownloadQR = () => {
    const canvas = document.getElementById('universal-qr-canvas');
    const pngUrl = canvas
      .toDataURL('image/png')
      .replace('image/png', 'image/octet-stream');
    
    const downloadLink = document.createElement('a');
    downloadLink.href = pngUrl;
    downloadLink.download = `qr-universal-${institution.slug}.png`;
    document.body.appendChild(downloadLink);
    downloadLink.click();
    document.body.removeChild(downloadLink);
  };

  const handlePrintQR = () => {
    window.print();
  };

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-gray-600">Cargando...</div>
        </div>
      </AdminLayout>
    );
  }

  return (
    <AdminLayout>
      <div className="container mx-auto px-4 py-8 max-w-4xl">
        <h1 className="text-3xl font-bold text-gray-900 mb-8">
          QR Universal de Búsqueda
        </h1>

        <div className="bg-white shadow-lg rounded-lg p-8">
          
          {/* Información de la institución */}
          <div className="mb-8">
            <h2 className="text-xl font-semibold text-gray-800 mb-4">
              {institution?.name}
            </h2>
            <p className="text-gray-600 text-sm mb-2">
              Este código QR permite buscar equipos de tu institución por número de serie.
              Los usuarios solo podrán acceder a equipos que pertenezcan a{' '}
              <span className="font-semibold">{institution?.name}</span>.
            </p>
            <div className="bg-blue-50 border-l-4 border-blue-500 p-4 mt-4">
              <p className="text-sm text-blue-800">
                <strong>🔒 Seguridad:</strong> Cada institución tiene su propio QR universal.
                Esto garantiza el aislamiento de datos entre instituciones.
              </p>
            </div>
          </div>

          {/* QR Code */}
          <div className="flex flex-col items-center mb-8 print-section">
            <div className="bg-white p-6 rounded-lg shadow-inner border-2 border-gray-200">
              <QRCode
                id="universal-qr-canvas"
                value={universalQRUrl}
                size={300}
                level="H"
                includeMargin={true}
              />
            </div>
            <p className="text-sm text-gray-500 mt-4 font-mono break-all text-center max-w-md">
              {universalQRUrl}
            </p>
          </div>

          {/* Estadísticas */}
          {stats && (
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
              <div className="bg-gray-50 p-4 rounded-lg">
                <p className="text-sm text-gray-600">Búsquedas hoy</p>
                <p className="text-2xl font-bold text-gray-800">{stats.today || 0}</p>
              </div>
              <div className="bg-gray-50 p-4 rounded-lg">
                <p className="text-sm text-gray-600">Este mes</p>
                <p className="text-2xl font-bold text-gray-800">{stats.thisMonth || 0}</p>
              </div>
              <div className="bg-gray-50 p-4 rounded-lg">
                <p className="text-sm text-gray-600">Tasa de éxito</p>
                <p className="text-2xl font-bold text-green-600">
                  {stats.successRate ? `${stats.successRate.toFixed(1)}%` : 'N/A'}
                </p>
              </div>
            </div>
          )}

          {/* Acciones */}
          <div className="flex flex-wrap gap-4 justify-center mb-8">
            <button
              onClick={handleDownloadQR}
              className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium shadow-md transition"
            >
              📥 Descargar QR
            </button>
            <button
              onClick={handlePrintQR}
              className="px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium shadow-md transition"
            >
              🖨️ Imprimir
            </button>
            <button
              onClick={() => window.open(universalQRUrl, '_blank')}
              className="px-6 py-3 bg-gray-600 text-white rounded-lg hover:bg-gray-700 font-medium shadow-md transition"
            >
              🔗 Probar Búsqueda
            </button>
          </div>

          {/* Instrucciones de uso */}
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-6">
            <h3 className="font-semibold text-blue-900 mb-3 text-lg">
              💡 ¿Dónde colocar este QR?
            </h3>
            <ul className="space-y-2 text-sm text-blue-800">
              <li className="flex items-start">
                <span className="mr-2">✓</span>
                <span>Entrada de bodega o taller</span>
              </li>
              <li className="flex items-start">
                <span className="mr-2">✓</span>
                <span>Área de recepción</span>
              </li>
              <li className="flex items-start">
                <span className="mr-2">✓</span>
                <span>Pizarra informativa</span>
              </li>
              <li className="flex items-start">
                <span className="mr-2">✓</span>
                <span>Manuales de trabajo impresos</span>
              </li>
              <li className="flex items-start">
                <span className="mr-2">✓</span>
                <span>Escritorio de supervisores</span>
              </li>
            </ul>
          </div>

          {/* Diferenciación con QR específico */}
          <div className="mt-6 bg-yellow-50 border border-yellow-200 rounded-lg p-6">
            <h3 className="font-semibold text-yellow-900 mb-3 text-lg">
              ⚡ QR Universal vs QR Específico
            </h3>
            <div className="grid md:grid-cols-2 gap-4 text-sm">
              <div>
                <p className="font-semibold text-yellow-900 mb-2">QR Específico:</p>
                <ul className="space-y-1 text-yellow-800">
                  <li>• Pegado en cada equipo</li>
                  <li>• Acceso directo e inmediato</li>
                  <li>• Ideal para inspecciones</li>
                </ul>
              </div>
              <div>
                <p className="font-semibold text-yellow-900 mb-2">QR Universal:</p>
                <ul className="space-y-1 text-yellow-800">
                  <li>• Un QR para todos los equipos</li>
                  <li>• Requiere ingresar N° de serie</li>
                  <li>• Ideal para consultas sin acceso físico</li>
                </ul>
              </div>
            </div>
          </div>
        </div>

        {/* Estilos de impresión */}
        <style jsx global>{`
          @media print {
            body * {
              visibility: hidden;
            }
            .print-section, .print-section * {
              visibility: visible;
            }
            .print-section {
              position: absolute;
              left: 50%;
              top: 50%;
              transform: translate(-50%, -50%);
            }
          }
        `}</style>
      </div>
    </AdminLayout>
  );
}
```

**Agregar enlace en menú de navegación**:
```jsx
// components/AdminSidebar.js
<nav className="mt-8">
  {/* ... otros enlaces ... */}
  
  <Link href="/admin/qr-universal">
    <a className="flex items-center px-4 py-3 text-gray-700 hover:bg-gray-100">
      <span className="mr-3">🔍</span>
      <span>QR Universal</span>
    </a>
  </Link>
</nav>
```

---

### **Fase 3: Mejoras y Optimizaciones**

#### 3.1 Caché de búsquedas frecuentes

```typescript
// equipment.service.ts
import { CACHE_MANAGER, Inject } from '@nestjs/common';
import { Cache } from 'cache-manager';

@Injectable()
export class EquipmentService {
  constructor(
    @Inject(CACHE_MANAGER) private cacheManager: Cache
  ) {}

  async findBySerialNumber(serialNumber: string): Promise<Equipment> {
    // Intentar obtener del caché
    const cacheKey = `equipment:serial:${serialNumber}`;
    const cached = await this.cacheManager.get<Equipment>(cacheKey);
    
    if (cached) {
      return cached;
    }
    
    // Si no está en caché, buscar en BD
    const equipment = await this.equipmentRepository.findOne({
      where: { serial_number: serialNumber, deleted_at: IsNull() },
      relations: ['qr_code', 'maintenances', 'documents', 'institution']
    });
    
    if (!equipment) {
      throw new NotFoundException('Equipo no encontrado');
    }
    
    // Guardar en caché por 5 minutos
    await this.cacheManager.set(cacheKey, equipment, 300);
    
    return equipment;
  }
}
```

#### 3.2 Búsqueda con autocompletado

Agregar un endpoint de autocompletado para mejorar UX:

```typescript
@Get('search-serial-autocomplete')
async autocompleteSerial(@Query('q') query: string) {
  if (!query || query.length < 2) {
    return { suggestions: [] };
  }
  
  const suggestions = await this.equipmentRepository
    .createQueryBuilder('eq')
    .select(['eq.serial_number', 'eq.name'])
    .where('eq.serial_number LIKE :query', { query: `${query}%` })
    .andWhere('eq.deleted_at IS NULL')
    .limit(5)
    .getMany();
    
  return { suggestions };
}
```

#### 3.3 Escáner de código de barras

Si los equipos tienen códigos de barras en sus números de serie:

```jsx
import { BrowserQRCodeReader } from '@zxing/library';

const ScannerButton = () => {
  const handleScan = async () => {
    const codeReader = new BrowserQRCodeReader();
    try {
      const result = await codeReader.decodeOnceFromVideoDevice();
      setSerialNumber(result.text);
    } catch (err) {
      console.error('Error al escanear:', err);
    }
  };
  
  return (
    <button onClick={handleScan} className="...">
      📷 Escanear código de barras
    </button>
  );
};
```

#### 3.4 Historial de búsquedas del usuario

Guardar en localStorage las últimas búsquedas para acceso rápido:

```jsx
const [recentSearches, setRecentSearches] = useState([]);

useEffect(() => {
  const stored = localStorage.getItem('recent_serial_searches');
  if (stored) {
    setRecentSearches(JSON.parse(stored));
  }
}, []);

const saveSearch = (serialNumber) => {
  const updated = [serialNumber, ...recentSearches.slice(0, 4)];
  setRecentSearches(updated);
  localStorage.setItem('recent_serial_searches', JSON.stringify(updated));
};
```

---

## Análisis de Impacto

### **Base de datos**
- ✓ No requiere cambios obligatorios en esquema existente
- ✓ Cambios opcionales: campos adicionales en `qr_scan_logs` para trazabilidad mejorada
- ✓ Índice existente en `serial_number` ya soporta búsquedas eficientes

### **Backend**
- ✓ Un nuevo endpoint: `GET /equipment/search-by-serial/:serialNumber`
- ✓ Modificación menor en servicio de logs para registrar tipo de búsqueda
- ✓ Rate limiting recomendado

### **Frontend**
- ✓ Una nueva página: `/qr/universal`
- ✓ Generación de un QR físico universal
- ✓ Opcional: página admin para gestionar QR universal

### **Infraestructura**
- ✓ No requiere cambios en infraestructura
- ✓ Opcional: CDN/caché para mejorar performance de búsquedas frecuentes

---

## Testing

### Tests backend

```typescript
describe('EquipmentController - Búsqueda por Serial', () => {
  it('debe encontrar equipo por número de serie', async () => {
    const response = await request(app.getHttpServer())
      .get('/equipment/search-by-serial/SN-2024-001')
      .expect(200);
    
    expect(response.body.success).toBe(true);
    expect(response.body.equipment.serial_number).toBe('SN-2024-001');
  });
  
  it('debe retornar 404 si no existe el serial', async () => {
    await request(app.getHttpServer())
      .get('/equipment/search-by-serial/NO-EXISTE')
      .expect(404);
  });
  
  it('debe aplicar rate limiting', async () => {
    // Hacer 11 requests rápidos
    for (let i = 0; i < 11; i++) {
      const res = await request(app.getHttpServer())
        .get('/equipment/search-by-serial/SN-2024-001');
      
      if (i < 10) {
        expect(res.status).toBe(200);
      } else {
        expect(res.status).toBe(429); // Too Many Requests
      }
    }
  });
});
```

### Tests frontend

```javascript
describe('UniversalQRSearch', () => {
  it('debe mostrar formulario de búsqueda', () => {
    render(<UniversalQRSearch />);
    expect(screen.getByLabelText(/número de serie/i)).toBeInTheDocument();
  });
  
  it('debe buscar y redirigir al encontrar equipo', async () => {
    const mockPush = jest.fn();
    useRouter.mockReturnValue({ push: mockPush });
    
    api.get.mockResolvedValue({
      data: {
        success: true,
        equipment: {
          qr_code: { token: 'abc123' }
        }
      }
    });
    
    render(<UniversalQRSearch />);
    
    const input = screen.getByLabelText(/número de serie/i);
    const button = screen.getByRole('button', { name: /buscar equipo/i });
    
    fireEvent.change(input, { target: { value: 'SN-2024-001' } });
    fireEvent.click(button);
    
    await waitFor(() => {
      expect(mockPush).toHaveBeenCalledWith('/qr/abc123');
    });
  });
  
  it('debe mostrar error si no encuentra equipo', async () => {
    api.get.mockRejectedValue({ response: { status: 404 } });
    
    render(<UniversalQRSearch />);
    
    const input = screen.getByLabelText(/número de serie/i);
    const button = screen.getByRole('button', { name: /buscar equipo/i });
    
    fireEvent.change(input, { target: { value: 'NO-EXISTE' } });
    fireEvent.click(button);
    
    await waitFor(() => {
      expect(screen.getByText(/no se encontró/i)).toBeInTheDocument();
    });
  });
});
```

---

## Roadmap de Implementación

### **Sprint 1** (Funcionalidad básica)
- [ ] Crear endpoint `GET /equipment/search-by-serial/:serialNumber`
- [ ] Agregar validación y sanitización de input
- [ ] Implementar rate limiting
- [ ] Crear página `/qr/universal` en frontend
- [ ] Generar QR universal físico para pruebas

### **Sprint 2** (Trazabilidad y seguridad)
- [ ] Modificar tabla `qr_scan_logs` (campos opcionales)
- [ ] Actualizar entidad y servicio de logs
- [ ] Registrar búsquedas universales en logs
- [ ] Agregar tests unitarios y de integración

### **Sprint 3** (Admin y optimizaciones)
- [ ] Crear página admin para gestionar QR universal
- [ ] Implementar caché de búsquedas frecuentes
- [ ] Agregar autocompletado de serial numbers
- [ ] Agregar historial de búsquedas locales

### **Sprint 4** (Mejoras UX)
- [ ] Implementar escáner de código de barras
- [ ] Agregar estadísticas de uso en admin
- [ ] Diseño responsive optimizado
- [ ] Documentación de usuario final

---

## Métricas de Éxito

- **Adopción**: % de búsquedas vía QR universal vs QR específico
- **Performance**: Tiempo de respuesta < 500ms para búsquedas
- **Precisión**: % de búsquedas exitosas (encontraron el equipo)
- **Disponibilidad**: Uptime del endpoint > 99.9%
- **Seguridad**: 0 incidentes de inyección SQL o XSS

---

## Preguntas Frecuentes (FAQ)

**Q: ¿El QR universal reemplaza los QR específicos de cada equipo?**  
A: No, es un método complementario. Los QR específicos siguen funcionando igual.

**Q: ¿Qué pasa si alguien no conoce el número de serie?**  
A: Debe usar el QR específico del equipo o buscar desde el panel de administración.

**Q: ¿Se puede desactivar el QR universal?**  
A: Sí, simplemente no distribuir el QR o implementar un flag de activación en configuración.

**Q: ¿Es seguro exponer la búsqueda por serial number públicamente?**  
A: Sí, el serial number ya es visible en la placa física del equipo. Los documentos privados siguen protegidos por autenticación.

**Q: ¿Cuántos QR universales físicos se pueden imprimir?**  
A: Los que se necesiten, todos apuntan a la misma URL (`/qr/universal`).

---

---

## Coexistencia de Ambos Sistemas

### Matriz de Uso: QR Específico vs QR Universal

| Aspecto | QR Específico | QR Universal |
|---------|---------------|--------------|
| **Ubicación física** | Pegado en el equipo | Entrada bodega, oficina, manuales |
| **Acceso** | Directo a ficha del equipo | Requiere ingresar serial number |
| **Uso principal** | Inspección del equipo físico | Consulta sin acceso al equipo |
| **Cantidad de escaneos** | Múltiples (cada inspección) | Variable (búsquedas puntuales) |
| **Usuario típico** | Técnico en terreno | Personal de bodega, supervisores |
| **Ventaja** | Rapidez (1 escaneo) | Flexibilidad (1 QR, N equipos) |
| **Requisito previo** | Equipo debe estar presente | Conocer serial number |

---

## Diferenciación Visual y de Diseño

### 1. **Etiquetas QR Específico (Equipo Individual)**

**Diseño de etiqueta**:
```
┌─────────────────────────────────┐
│  [Logo Institución]             │
│                                 │
│  ════════════════════           │
│  ║           ║                  │
│  ║  QR Code  ║  EQUIPO          │
│  ║           ║  Compresor XYZ   │
│  ║           ║                  │
│  ════════════════════           │
│                                 │
│  S/N: SN-2024-001               │
│  ID: #12345                     │
│                                 │
│  Escanear para ver ficha        │
└─────────────────────────────────┘
```

**Características**:
- ✓ Logo de la institución
- ✓ Nombre del equipo
- ✓ Número de serie destacado
- ✓ QR específico del equipo
- ✓ Texto: "Escanear para ver ficha"
- ✓ Tamaño: Etiqueta adhesiva estándar
- ✓ Color de fondo: Blanco o institucional

---

### 2. **Etiquetas QR Universal (Punto de Acceso)**

**Diseño de etiqueta**:
```
┌─────────────────────────────────┐
│                                 │
│   [Logo Institución]            │
│                                 │
│   ██████████████████            │
│   ██            ██              │
│   ██  QR Code   ██   BÚSQUEDA   │
│   ██            ██   UNIVERSAL  │
│   ██            ██   DE EQUIPOS │
│   ██████████████████            │
│                                 │
│   📱 Escanea este código        │
│   🔍 Ingresa el N° de serie     │
│   📋 Accede a la información    │
│                                 │
│   ¿No encuentras el QR?         │
│   ¡Usa este código!             │
│                                 │
└─────────────────────────────────┘
```

**Características**:
- ✓ Logo institucional más grande
- ✓ Título destacado: "BÚSQUEDA UNIVERSAL"
- ✓ Iconografía clara (📱🔍📋)
- ✓ Instrucciones paso a paso
- ✓ Mensaje de utilidad
- ✓ Tamaño: Cartel A4 o A5 (más grande)
- ✓ Color de fondo: Distintivo (azul claro, amarillo suave)
- ✓ Opcional: Código de barras adicional

---

### 3. **Diferenciación por Color**

**Código de colores sugerido**:

| Tipo QR | Color de Fondo | Color de Borde | Uso |
|---------|----------------|----------------|-----|
| **QR Específico** | Blanco | Negro/Gris | Etiqueta en equipo |
| **QR Universal** | Azul claro (#E3F2FD) | Azul (#2196F3) | Punto de acceso |
| **QR Admin** | Amarillo claro (#FFF9C4) | Amarillo (#FFC107) | Solo personal autorizado |

---

## Estrategia de Implementación y Ubicación

### **Ubicación de QR Específicos**

1. **Equipos grandes/fijos**:
   - Parte frontal visible
   - Protegido de factores ambientales
   - A altura de lectura cómoda (1.2m - 1.6m)

2. **Equipos portátiles**:
   - En carcasa principal
   - Múltiples ubicaciones si hay riesgo de desgaste
   - Considerar fundas protectoras

3. **Equipos críticos**:
   - Etiqueta principal + etiqueta de respaldo
   - En ubicación diferente dentro del mismo equipo

---

### **Ubicación de QR Universales**

1. **Puntos de entrada**:
   - ✓ Entrada de bodega principal
   - ✓ Recepción de taller
   - ✓ Área de carga/descarga
   - ✓ Sala de control

2. **Áreas de trabajo**:
   - ✓ Pizarra informativa del taller
   - ✓ Escritorio de supervisor
   - ✓ Panel de instrucciones

3. **Documentación**:
   - ✓ Manual de operaciones
   - ✓ Listado de equipos impreso
   - ✓ Tarjeta de identificación del personal

4. **Digital**:
   - ✓ Pantalla de bienvenida de la institución
   - ✓ Pantallas digitales informativas
   - ✓ Correos electrónicos de onboarding

---

## Flujos de Usuario Diferenciados

### **Flujo A: Usuario usa QR Específico** (Escenario ideal)

```
1. Usuario está frente al equipo físico
   ↓
2. Escanea QR pegado en el equipo
   ↓
3. Acceso DIRECTO a ficha del equipo
   ↓
4. Ve información, documentos, mantenciones
   ↓
5. [Opcional] Reporta mantención o incidencia
```

**Tiempo estimado**: 5-10 segundos  
**Fricción**: Mínima  
**Requisito**: Equipo presente y QR legible

---

### **Flujo B: Usuario usa QR Universal** (Escenario alternativo)

```
1. Usuario no tiene acceso al equipo físico
   ↓
2. Escanea QR Universal (en bodega/oficina)
   ↓
3. Ve formulario de búsqueda
   ↓
4. Ingresa número de serie (o escanea código de barras)
   ↓
5. Sistema busca y valida el equipo
   ↓
6. Redirige a ficha del equipo (igual que Flujo A)
   ↓
7. Ve información, documentos, mantenciones
```

**Tiempo estimado**: 20-30 segundos  
**Fricción**: Media (requiere input manual)  
**Requisito**: Conocer el serial number

---

### **Flujo C: Usuario tiene ambos disponibles**

```
Escenario: Técnico está en bodega, tiene el equipo presente

Opción 1 (Recomendada):
- Escanea QR específico del equipo → Acceso directo

Opción 2 (Si QR dañado):
- Escanea QR universal → Ingresa serial → Acceso
```

---

## Gestión Administrativa

### **Panel Admin: Vista Unificada**

**Propuesta de interfaz**: `admin/qr-management`

```jsx
┌────────────────────────────────────────────────┐
│  Gestión de Códigos QR                         │
├────────────────────────────────────────────────┤
│                                                │
│  [Tab: QR Específicos] [Tab: QR Universal]    │
│                                                │
│  ┌─────────────────────────────────────────┐  │
│  │ QR Específicos (1,234 activos)          │  │
│  ├─────────────────────────────────────────┤  │
│  │                                          │  │
│  │ Equipo         Serial       Estado  QR   │  │
│  │ Compresor XYZ  SN-2024-001  ● Activo    │  │
│  │ Generador ABC  SN-2024-002  ● Activo    │  │
│  │ Bomba 123      SN-2024-003  ⚪ Sin QR   │  │
│  │                                          │  │
│  │ [+ Generar QR para equipo sin asignar]  │  │
│  │ [📊 Ver estadísticas de uso]            │  │
│  └─────────────────────────────────────────┘  │
│                                                │
│  ┌─────────────────────────────────────────┐  │
│  │ QR Universal                             │  │
│  ├─────────────────────────────────────────┤  │
│  │                                          │  │
│  │ [QR Code Image]                          │  │
│  │                                          │  │
│  │ URL: app.dominio.cl/qr/universal        │  │
│  │                                          │  │
│  │ Búsquedas hoy: 45                        │  │
│  │ Búsquedas este mes: 1,234                │  │
│  │ Tasa de éxito: 94.2%                     │  │
│  │                                          │  │
│  │ [📥 Descargar para imprimir]            │  │
│  │ [📊 Ver estadísticas detalladas]        │  │
│  │ [⚙️ Configurar mensajes]                │  │
│  └─────────────────────────────────────────┘  │
│                                                │
└────────────────────────────────────────────────┘
```

---

### **Analytics y Métricas Diferenciadas**

**Dashboard de métricas**:

```sql
-- Consulta para comparar uso de ambos sistemas
SELECT 
  search_type,
  DATE(scanned_at) as fecha,
  COUNT(*) as total_escaneos,
  COUNT(DISTINCT qr_code_id) as equipos_unicos,
  COUNT(DISTINCT ip) as usuarios_unicos
FROM qr_scan_logs
WHERE scanned_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY search_type, DATE(scanned_at)
ORDER BY fecha DESC;
```

**Métricas recomendadas**:

| Métrica | QR Específico | QR Universal |
|---------|---------------|--------------|
| **Escaneos totales** | Total de escaneos directos | Total de búsquedas |
| **Equipos más consultados** | Top 10 por escaneos | Top 10 por búsquedas |
| **Horarios pico** | Distribución por hora | Distribución por hora |
| **Tasa de éxito** | N/A (siempre exitoso) | % búsquedas que encontraron equipo |
| **Tiempo promedio** | N/A | Tiempo desde búsqueda hasta acceso |
| **Errores comunes** | QR dañados | Serial incorrecto, equipo no existe |

---

## Reporte de Uso Comparativo

**Endpoint**: `GET /analytics/qr-usage-comparison`

**Respuesta**:
```json
{
  "period": "last_30_days",
  "specific_qr": {
    "total_scans": 15234,
    "unique_equipments": 856,
    "unique_users": 342,
    "avg_scans_per_equipment": 17.8,
    "most_scanned": [
      {
        "equipment_id": 123,
        "name": "Compresor ABC-500",
        "scans": 245
      }
    ]
  },
  "universal_qr": {
    "total_searches": 1842,
    "successful_searches": 1734,
    "success_rate": 94.2,
    "unique_equipments": 421,
    "unique_users": 89,
    "avg_search_time_seconds": 8.4,
    "common_errors": [
      {
        "error": "Serial no encontrado",
        "count": 78
      },
      {
        "error": "Formato inválido",
        "count": 30
      }
    ]
  },
  "comparison": {
    "total_accesses": 17076,
    "specific_qr_percentage": 89.2,
    "universal_qr_percentage": 10.8,
    "overlap_equipments": 156, // Equipos accedidos por ambos métodos
    "only_specific": 700,
    "only_universal": 265
  }
}
```

---

## Recomendaciones de Uso para Usuarios Finales

### **Guía de Selección de Método**

**Usa el QR Específico cuando**:
- ✓ Estás frente al equipo físico
- ✓ Necesitas acceso rápido (urgencia)
- ✓ Estás realizando inspección visual
- ✓ Vas a registrar una mantención
- ✓ El QR está en buenas condiciones

**Usa el QR Universal cuando**:
- ✓ El equipo no está accesible (en uso, lugar remoto)
- ✓ El QR específico está dañado o ilegible
- ✓ Necesitas consultar múltiples equipos
- ✓ Estás en oficina con listado de serial numbers
- ✓ Estás verificando información antes de ir al terreno

---

## Señalética y Comunicación

### **Cartel para área con QR Universal**

```
┌───────────────────────────────────────────────┐
│                                               │
│         🔍 PUNTO DE BÚSQUEDA DE EQUIPOS       │
│                                               │
│   ┌─────────────────┐                         │
│   │                 │  1. Escanea este QR    │
│   │   [QR GRANDE]   │  2. Ingresa N° de serie│
│   │                 │  3. Accede a la info   │
│   └─────────────────┘                         │
│                                               │
│   ╔════════════════════════════════════════╗  │
│   ║ ¿Cuándo usar este QR?                  ║  │
│   ╠════════════════════════════════════════╣  │
│   ║ • Cuando el equipo no está cerca       ║  │
│   ║ • Si la etiqueta del equipo está dañada║  │
│   ║ • Para consultar varios equipos        ║  │
│   ╚════════════════════════════════════════╝  │
│                                               │
│   💡 Tip: Si estás frente al equipo,         │
│      usa el QR pegado en él para acceso      │
│      más rápido.                             │
│                                               │
└───────────────────────────────────────────────┘
```

---

### **Etiqueta instructiva en equipo**

```
┌────────────────────────────┐
│  [QR Code del equipo]      │
│                            │
│  ACCESO RÁPIDO ⚡          │
│  Escanea para ver:         │
│  • Información técnica     │
│  • Documentos              │
│  • Historial mantención    │
│                            │
│  S/N: SN-2024-001          │
│                            │
│  ¿QR dañado?               │
│  Busca el QR Universal     │
│  en la entrada de bodega   │
└────────────────────────────┘
```

---

## Migración y Adopción Gradual

### **Fase de Convivencia**

**Mes 1-2: Introducción**
- Mantener solo QR específicos funcionando
- Desplegar QR universales en 2-3 ubicaciones piloto
- Capacitar a personal clave (supervisores, bodega)
- Monitorear uso y recoger feedback

**Mes 3-4: Expansión**
- Evaluar métricas de adopción
- Instalar QR universales en todas las ubicaciones estratégicas
- Crear material de capacitación (videos, guías)
- Comunicar beneficios a todo el personal

**Mes 5-6: Optimización**
- Analizar patrones de uso
- Identificar mejoras en UX
- Ajustar ubicación de QR universales según uso real
- Implementar mejoras (autocompletado, historial, etc.)

---

### **Plan de Capacitación**

**Contenido del taller** (30 minutos):

1. **Introducción** (5 min)
   - ¿Qué es un QR y cómo funciona?
   - Diferencia entre QR específico y universal

2. **Demostración práctica** (10 min)
   - Escanear QR específico en equipo real
   - Escanear QR universal y buscar por serial
   - Comparar tiempos y experiencia

3. **Casos de uso** (10 min)
   - Cuándo usar cada tipo
   - Qué hacer si el QR específico no funciona
   - Tips para búsquedas más rápidas

4. **Preguntas y práctica** (5 min)
   - Resolver dudas
   - Práctica guiada con equipos de la institución

---

## Troubleshooting y Soporte

### **Problemas Comunes y Soluciones**

| Problema | Sistema | Solución |
|----------|---------|----------|
| **QR específico no escanea** | QR Específico | 1. Limpiar cámara del teléfono<br>2. Mejorar iluminación<br>3. Usar QR universal como backup |
| **Serial number no encontrado** | QR Universal | 1. Verificar que esté bien escrito<br>2. Revisar en placa física del equipo<br>3. Consultar con supervisor |
| **Equipo sin QR asignado** | QR Específico | 1. Usar QR universal<br>2. Reportar a admin para generar QR<br>3. Buscar desde panel admin |
| **Rate limit alcanzado** | QR Universal | 1. Esperar 1 minuto<br>2. Si es urgente, contactar IT<br>3. Usar acceso desde panel admin |

---

### **Flujo de Escalamiento**

```
Usuario tiene problema
    ↓
Intenta solución alternativa (otro sistema QR)
    ↓
Si persiste → Consulta con supervisor
    ↓
Supervisor intenta desde panel admin
    ↓
Si persiste → Ticket a soporte IT
    ↓
IT verifica:
  - Estado del QR en base de datos
  - Logs de error
  - Integridad de datos del equipo
    ↓
Solución implementada + feedback a usuario
```

---

## Conclusión

El **QR Universal** es una funcionalidad complementaria que mejora significativamente la accesibilidad del sistema sin comprometer la seguridad ni requerir cambios arquitectónicos mayores. 

### **Coexistencia Efectiva**

La estrategia de mantener ambos sistemas permite:

- ✅ **QR Específico** como método principal (89-92% de uso esperado)
- ✅ **QR Universal** como método alternativo flexible (8-11% de uso esperado)
- ✅ Redundancia y resiliencia del sistema
- ✅ Adaptabilidad a diferentes escenarios de uso
- ✅ Mejor experiencia de usuario en situaciones no ideales

### **Diferenciación Clara**

- 🎨 **Visual**: Diseños, colores y tamaños diferentes
- 📍 **Ubicación**: Equipos vs puntos de acceso estratégicos
- 📊 **Analytics**: Métricas separadas para evaluar cada sistema
- 👥 **Usuarios**: Perfiles de uso diferenciados

### **Recomendación Final**

**Implementar en fases**, comenzando con la funcionalidad básica (Sprint 1) y evaluando la adopción antes de invertir en optimizaciones avanzadas.

**Inversión de desarrollo**: 
- Básico: 16-24 horas
- Completo (con diferenciación y analytics): 32-40 horas

**Valor agregado**: Alto, especialmente para instituciones con muchos equipos o personal técnico que necesita consultar información rápidamente sin acceso físico al equipo.
