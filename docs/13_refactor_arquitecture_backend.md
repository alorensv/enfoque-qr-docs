# Refactorización de Arquitectura Backend - Enfoque QR

**Fecha**: Marzo 2026  
**Objetivo**: Mejorar la escalabilidad y mantenibilidad del proyecto organizando el código según principios de Domain-Driven Design y separación de responsabilidades.

---

## 📊 Análisis de la Arquitectura Actual

### Estructura Actual

```
backend/src/
├── app.controller.ts
├── app.module.ts
├── app.service.ts
├── main.ts
├── auth/
│   ├── auth.controller.ts
│   ├── auth.module.ts
│   ├── auth.service.ts
│   ├── jwt-auth.guard.ts
│   └── jwt.strategy.ts
├── common/
│   ├── common.module.ts
│   ├── institutions.controller.ts    ⚠️ Lógica de dominio en common
│   ├── institutions.service.ts       ⚠️ Lógica de dominio en common
│   ├── logger.service.ts             ✓ Utilidad genérica
│   └── slug.service.ts               ✓ Utilidad genérica
├── equipment/
│   ├── dto/
│   ├── equipment.controller.ts
│   ├── equipment.module.ts          ⚠️ Usa forwardRef con QrModule
│   └── equipment.service.ts
├── maintenances/
│   ├── file-size.interceptor.ts
│   ├── maintenance-log.service.ts
│   ├── maintenance.storage.ts
│   ├── maintenances.controller.ts
│   ├── maintenances.module.ts
│   └── maintenances.service.ts
├── models/                          ❌ ANTI-PATRÓN: Entities centralizadas
│   ├── equipment.entity.ts
│   ├── equipment_document.entity.ts
│   ├── equipment_document_version.entity.ts
│   ├── equipment_maintenance.entity.ts
│   ├── equipment_maintenance_document.entity.ts
│   ├── equipment_maintenance_log.entity.ts
│   ├── equipment_maintenance_photo.entity.ts
│   ├── equipment_qr_code.entity.ts
│   ├── institution.entity.ts
│   ├── institution_settings.entity.ts
│   ├── qr_scan_log.entity.ts
│   ├── user.entity.ts
│   ├── user_institution.entity.ts
│   └── user_profile.entity.ts
├── qr/
│   ├── dto/
│   ├── qr-scan-log.service.ts
│   ├── qr.controller.ts
│   ├── qr.module.ts
│   └── qr.service.ts
└── users/
    ├── users.controller.ts
    ├── users.module.ts
    └── users.service.ts
```

---

## ⚠️ Problemas Identificados

### 1. **Carpeta `models/` Centralizada (Crítico)**

**Problema**: Todas las entidades están en una carpeta central, violando los principios de:
- Alta cohesión y bajo acoplamiento
- Domain-Driven Design
- Single Responsibility Principle
- Modularidad

**Impacto**:
- Difícil escalabilidad a microservicios
- Módulos no son autocontenidos
- Conflictos en Git más frecuentes
- Testing más complejo
- Imports cruzados confusos (`../../models/...`)

### 2. **Dependencias Circulares**

**Ubicación**: `equipment.module.ts`

```typescript
forwardRef(() => QrModule)
```

**Problema**: Indica un diseño acoplado. Equipment y QR tienen dependencias bidireccionales.

**Consecuencias**:
- Dificulta el testing unitario
- Problemas potenciales de inicialización
- Code smell de diseño incorrecto

### 3. **Common Module con Lógica de Dominio**

**Problema**: `InstitutionsService` y `InstitutionsController` están en `common/`, pero representan lógica de dominio, no utilidades genéricas.

**Qué debería estar en Common**:
- ✅ Utilidades (SlugService, LoggerService)
- ✅ Guards genéricos
- ✅ Interceptors compartidos
- ✅ Decorators
- ✅ DTOs base
- ✅ Interfaces comunes

**Qué NO debería estar**:
- ❌ Servicios de dominio (InstitutionsService)
- ❌ Controllers de entidades de negocio
- ❌ Entities específicas

### 4. **Falta de Convenciones de Nomenclatura**

- Mezcla de snake_case y camelCase en nombres de archivos
- `equipment_qr_code.entity.ts` vs `qr-scan-log.service.ts`

---

## 🎯 Estructura Propuesta

### Nueva Organización por Dominios

```
backend/src/
├── main.ts
├── app.module.ts
├── app.controller.ts
├── app.service.ts
│
├── core/                              # 🆕 Módulo Core (anteriormente common)
│   ├── core.module.ts
│   ├── services/
│   │   ├── logger.service.ts
│   │   └── slug.service.ts
│   ├── guards/
│   │   └── roles.guard.ts (si existe)
│   ├── interceptors/
│   │   └── logging.interceptor.ts (si existe)
│   ├── decorators/
│   │   └── current-user.decorator.ts (si existe)
│   └── interfaces/
│       └── base-response.interface.ts
│
├── auth/                              # Módulo Auth (sin cambios)
│   ├── auth.controller.ts
│   ├── auth.module.ts
│   ├── auth.service.ts
│   ├── jwt-auth.guard.ts
│   └── jwt.strategy.ts
│
├── institutions/                      # 🆕 Módulo Institutions (extraído de common)
│   ├── entities/
│   │   ├── institution.entity.ts
│   │   └── institution-settings.entity.ts
│   ├── dto/
│   │   ├── create-institution.dto.ts
│   │   └── update-institution.dto.ts
│   ├── institutions.controller.ts
│   ├── institutions.service.ts
│   └── institutions.module.ts
│
├── users/                             # Módulo Users (mejorado)
│   ├── entities/
│   │   ├── user.entity.ts
│   │   ├── user-profile.entity.ts
│   │   └── user-institution.entity.ts
│   ├── dto/
│   │   ├── create-user.dto.ts
│   │   └── update-user.dto.ts
│   ├── users.controller.ts
│   ├── users.service.ts
│   └── users.module.ts
│
├── equipment/                         # Módulo Equipment (mejorado)
│   ├── entities/
│   │   ├── equipment.entity.ts
│   │   ├── equipment-document.entity.ts
│   │   └── equipment-document-version.entity.ts
│   ├── dto/
│   │   ├── create-equipment.dto.ts
│   │   ├── update-equipment.dto.ts
│   │   └── add-document.dto.ts
│   ├── equipment.controller.ts
│   ├── equipment.service.ts
│   ├── equipment.module.ts
│   └── storage/
│       └── equipment.storage.ts
│
├── qr/                                # Módulo QR (mejorado)
│   ├── entities/
│   │   ├── equipment-qr-code.entity.ts
│   │   └── qr-scan-log.entity.ts
│   ├── dto/
│   │   ├── create-qr.dto.ts
│   │   └── scan-qr.dto.ts
│   ├── qr.controller.ts
│   ├── qr.service.ts
│   ├── qr-scan-log.service.ts
│   └── qr.module.ts
│
└── maintenances/                      # Módulo Maintenances (mejorado)
    ├── entities/
    │   ├── equipment-maintenance.entity.ts
    │   ├── equipment-maintenance-photo.entity.ts
    │   ├── equipment-maintenance-document.entity.ts
    │   └── equipment-maintenance-log.entity.ts
    ├── dto/
    │   ├── create-maintenance.dto.ts
    │   └── update-maintenance.dto.ts
    ├── interceptors/
    │   └── file-size.interceptor.ts
    ├── storage/
    │   └── maintenance.storage.ts
    ├── maintenances.controller.ts
    ├── maintenances.service.ts
    ├── maintenance-log.service.ts
    └── maintenances.module.ts
```

---

## 📋 Plan de Implementación

### Estrategia: Migración Incremental Sin Downtime

**Principio**: Duplicar → Migrar → Validar → Eliminar

### Fase 1: Preparación (Sin impacto en producción)

#### 1.1 Crear nuevas convenciones
- [ ] Documentar estándar de nomenclatura (kebab-case)
- [ ] Preparar scripts de testing
- [ ] Backup de la base de datos (si aplica)

#### 1.2 Renombrar `common/` a `core/`
```bash
# Crear módulo core
mkdir src/core
mkdir src/core/services
mkdir src/core/guards
mkdir src/core/interceptors
mkdir src/core/decorators
mkdir src/core/interfaces
```

**Archivos a mover**:
- `common/logger.service.ts` → `core/services/logger.service.ts`
- `common/slug.service.ts` → `core/services/slug.service.ts`
- `common/common.module.ts` → `core/core.module.ts` (renombrar clase)

**Cambios en `core.module.ts`**:
```typescript
import { Module, Global } from '@nestjs/common';
import { LoggerService } from './services/logger.service';
import { SlugService } from './services/slug.service';

@Global()
@Module({
  providers: [LoggerService, SlugService],
  exports: [LoggerService, SlugService],
})
export class CoreModule {}
```

**⚠️ NO mover todavía**:
- `institutions.controller.ts`
- `institutions.service.ts`

---

### Fase 2: Extraer Institutions de Core

#### 2.1 Crear módulo Institutions
```bash
mkdir src/institutions
mkdir src/institutions/entities
mkdir src/institutions/dto
```

#### 2.2 Mover entities
```bash
# Mover entities (mantener copia temporal)
cp src/models/institution.entity.ts src/institutions/entities/
cp src/models/institution_settings.entity.ts src/institutions/entities/institution-settings.entity.ts
```

#### 2.3 Actualizar imports en entities
```typescript
// institutions/entities/institution.entity.ts
// Cambiar imports relativos
import { InstitutionSettings } from './institution-settings.entity';
```

#### 2.4 Mover servicios y controllers
```bash
mv src/common/institutions.controller.ts src/institutions/
mv src/common/institutions.service.ts src/institutions/
```

#### 2.5 Crear institutions.module.ts
```typescript
import { Module, Global } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { InstitutionsController } from './institutions.controller';
import { InstitutionsService } from './institutions.service';
import { Institution } from './entities/institution.entity';
import { InstitutionSettings } from './entities/institution-settings.entity';

@Global() // Mantener como global si otros módulos lo necesitan
@Module({
  imports: [TypeOrmModule.forFeature([Institution, InstitutionSettings])],
  controllers: [InstitutionsController],
  providers: [InstitutionsService],
  exports: [InstitutionsService],
})
export class InstitutionsModule {}
```

#### 2.6 Actualizar app.module.ts
```typescript
// Agregar InstitutionsModule
import { InstitutionsModule } from './institutions/institutions.module';

@Module({
  imports: [
    CoreModule, // Renombrado de CommonModule
    InstitutionsModule, // Nuevo
    // ... resto de módulos
  ],
})
```

#### 2.7 Actualizar imports en archivos que usan Institution
```bash
# Buscar todos los archivos que importan desde models/institution
grep -r "from '../models/institution" src/
grep -r "from '../../models/institution" src/
```

**Actualizar a**:
```typescript
// Antes
import { Institution } from '../models/institution.entity';

// Después
import { Institution } from '../institutions/entities/institution.entity';
```

#### 2.8 Testing
- [ ] Ejecutar tests unitarios
- [ ] Verificar arranque de la aplicación
- [ ] Probar endpoints de institutions
- [ ] Revisar logs por errores

---

### Fase 3: Migrar User Module

#### 3.1 Crear estructura de entities
```bash
mkdir src/users/entities
mkdir src/users/dto
```

#### 3.2 Mover entities
```bash
cp src/models/user.entity.ts src/users/entities/
cp src/models/user_profile.entity.ts src/users/entities/user-profile.entity.ts
cp src/models/user_institution.entity.ts src/users/entities/user-institution.entity.ts
```

#### 3.3 Actualizar imports en entities
```typescript
// users/entities/user.entity.ts
import { UserProfile } from './user-profile.entity';
import { UserInstitution } from './user-institution.entity';
import { Institution } from '../../institutions/entities/institution.entity';
```

#### 3.4 Actualizar users.module.ts
```typescript
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './entities/user.entity';
import { UserProfile } from './entities/user-profile.entity';
import { UserInstitution } from './entities/user-institution.entity';

@Module({
  imports: [TypeOrmModule.forFeature([User, UserProfile, UserInstitution])],
  // ...
})
```

#### 3.5 Actualizar users.service.ts
```typescript
// Cambiar imports
import { User } from './entities/user.entity';
import { UserProfile } from './entities/user-profile.entity';
import { UserInstitution } from './entities/user-institution.entity';
```

#### 3.6 Buscar y actualizar imports externos
```bash
# Encontrar referencias externas
grep -r "from '../models/user" src/ --exclude-dir=users
grep -r "from '../../models/user" src/ --exclude-dir=users
```

#### 3.7 Testing
- [ ] Tests de users module
- [ ] Verificar autenticación
- [ ] Probar endpoints de usuarios

---

### Fase 4: Migrar Equipment Module

#### 4.1 Crear estructura
```bash
mkdir src/equipment/entities
mkdir src/equipment/storage
```

#### 4.2 Mover entities
```bash
cp src/models/equipment.entity.ts src/equipment/entities/
cp src/models/equipment_document.entity.ts src/equipment/entities/equipment-document.entity.ts
cp src/models/equipment_document_version.entity.ts src/equipment/entities/equipment-document-version.entity.ts
```

#### 4.3 Actualizar imports en entities
```typescript
// equipment/entities/equipment.entity.ts
import { Institution } from '../../institutions/entities/institution.entity';
import { EquipmentDocument } from './equipment-document.entity';
import { EquipmentQrCode } from '../../qr/entities/equipment-qr-code.entity'; // Temporal
```

#### 4.4 Actualizar equipment.module.ts
```typescript
import { Equipment } from './entities/equipment.entity';
import { EquipmentDocument } from './entities/equipment-document.entity';
import { EquipmentQrCode } from '../qr/entities/equipment-qr-code.entity'; // Temporal
```

#### 4.5 Actualizar equipment.service.ts
- Actualizar todos los imports a rutas relativas

#### 4.6 Testing
- [ ] Tests de equipment module
- [ ] Probar creación de equipos
- [ ] Verificar subida de documentos
- [ ] Confirmar generación de QR (dependencia temporal)

---

### Fase 5: Migrar QR Module

#### 5.1 Crear estructura
```bash
mkdir src/qr/entities
```

#### 5.2 Mover entities
```bash
cp src/models/equipment_qr_code.entity.ts src/qr/entities/equipment-qr-code.entity.ts
cp src/models/qr_scan_log.entity.ts src/qr/entities/qr-scan-log.entity.ts
```

#### 5.3 Actualizar imports en entities
```typescript
// qr/entities/equipment-qr-code.entity.ts
import { Equipment } from '../../equipment/entities/equipment.entity';
```

#### 5.4 Resolver dependencia circular Equipment ↔ QR

**Opción A: QR como parte de Equipment** (Recomendado si QR no se usa fuera de equipment)
```typescript
// Mover qr/ dentro de equipment/
equipment/
  ├── entities/
  ├── qr/
  │   ├── entities/
  │   ├── qr.service.ts
  │   └── qr-scan-log.service.ts
  └── ...
```

**Opción B: Mantener separado con dependencia unidireccional**
```typescript
// qr.module.ts - NO importa EquipmentModule
// equipment.module.ts - importa QrModule
@Module({
  imports: [
    TypeOrmModule.forFeature([Equipment, EquipmentDocument]),
    QrModule, // Sin forwardRef
  ],
})
```

#### 5.5 Actualizar qr.module.ts
```typescript
import { EquipmentQrCode } from './entities/equipment-qr-code.entity';
import { QrScanLog } from './entities/qr-scan-log.entity';
```

#### 5.6 Testing
- [ ] Tests de QR module
- [ ] Escaneo de códigos QR
- [ ] Generación de códigos desde equipment

---

### Fase 6: Migrar Maintenances Module

#### 6.1 Crear estructura
```bash
mkdir src/maintenances/entities
mkdir src/maintenances/interceptors
mkdir src/maintenances/storage
```

#### 6.2 Mover entities
```bash
cp src/models/equipment_maintenance.entity.ts src/maintenances/entities/equipment-maintenance.entity.ts
cp src/models/equipment_maintenance_photo.entity.ts src/maintenances/entities/equipment-maintenance-photo.entity.ts
cp src/models/equipment_maintenance_document.entity.ts src/maintenances/entities/equipment-maintenance-document.entity.ts
cp src/models/equipment_maintenance_log.entity.ts src/maintenances/entities/equipment-maintenance-log.entity.ts
```

#### 6.3 Reorganizar archivos internos
```bash
mv src/maintenances/file-size.interceptor.ts src/maintenances/interceptors/
mv src/maintenances/maintenance.storage.ts src/maintenances/storage/
```

#### 6.4 Actualizar imports
```typescript
// maintenances/entities/equipment-maintenance.entity.ts
import { Equipment } from '../../equipment/entities/equipment.entity';
import { User } from '../../users/entities/user.entity';
```

#### 6.5 Actualizar maintenances.module.ts
```typescript
import { EquipmentMaintenance } from './entities/equipment-maintenance.entity';
import { EquipmentMaintenancePhoto } from './entities/equipment-maintenance-photo.entity';
import { EquipmentMaintenanceDocument } from './entities/equipment-maintenance-document.entity';
import { EquipmentMaintenanceLog } from './entities/equipment-maintenance-log.entity';
```

#### 6.6 Testing
- [ ] Tests de maintenances
- [ ] Crear mantenimiento
- [ ] Subir fotos y documentos
- [ ] Verificar logs

---

### Fase 7: Actualizar app.module.ts

#### 7.1 Actualizar imports de entities
```typescript
// app.module.ts
// Eliminar imports desde models/
// Importar desde cada módulo

import { User } from './users/entities/user.entity';
import { UserProfile } from './users/entities/user-profile.entity';
import { Equipment } from './equipment/entities/equipment.entity';
import { Institution } from './institutions/entities/institution.entity';
import { EquipmentQrCode } from './qr/entities/equipment-qr-code.entity';
// ... etc
```

#### 7.2 Verificar lista de entities en TypeORM
```typescript
TypeOrmModule.forRoot({
  // ...
  entities: [
    User,
    UserProfile,
    UserInstitution,
    Equipment,
    EquipmentDocument,
    EquipmentDocumentVersion,
    Institution,
    InstitutionSettings,
    EquipmentQrCode,
    QrScanLog,
    EquipmentMaintenance,
    EquipmentMaintenancePhoto,
    EquipmentMaintenanceDocument,
    EquipmentMaintenanceLog,
  ],
  // ...
})
```

---

### Fase 8: Limpieza Final

#### 8.1 Verificar que no queden imports a models/
```bash
# Debe devolver 0 resultados
grep -r "from '../models" src/
grep -r "from '../../models" src/
grep -r "from '../../../models" src/
```

#### 8.2 Eliminar carpeta models/
```bash
# Solo después de verificar que todo funciona
rm -rf src/models
```

#### 8.3 Actualizar .gitignore si es necesario

#### 8.4 Testing final completo
- [ ] Tests unitarios de todos los módulos
- [ ] Tests de integración
- [ ] Tests E2E (si existen)
- [ ] Pruebas manuales de flujos críticos:
  - [ ] Login
  - [ ] Crear equipo
  - [ ] Generar QR
  - [ ] Escanear QR
  - [ ] Crear mantenimiento
  - [ ] Subir documentos

---

## ✅ Checklist de Validación por Fase

### Para cada fase, verificar:

1. **Compilación**
   ```bash
   npm run build
   ```

2. **Tests**
   ```bash
   npm run test
   npm run test:e2e
   ```

3. **Inicio de aplicación**
   ```bash
   npm run start:dev
   ```

4. **Logs sin errores**
   - Revisar consola
   - Verificar logs de TypeORM
   - Confirmar que todas las entities se cargan

5. **Endpoints funcionales**
   - Probar con Postman/Insomnia
   - Verificar respuestas esperadas

---

## 🔄 Rollback Plan

### Si algo falla en una fase:

1. **Mantener ambas estructuras temporalmente**
   - Los archivos originales en `models/` se mantienen hasta validar
   - Solo se eliminan después de confirmar funcionamiento

2. **Git commits atómicos**
   ```bash
   git add src/institutions
   git commit -m "feat: create institutions module with entities"
   
   git add src/core
   git commit -m "refactor: rename common to core"
   ```

3. **Tags de versión**
   ```bash
   git tag v1.0.0-before-refactor
   git tag v1.1.0-institutions-migrated
   git tag v1.2.0-users-migrated
   # etc...
   ```

4. **Revertir si es necesario**
   ```bash
   git revert <commit-hash>
   # o
   git reset --hard <tag-name>
   ```

---

## 📊 Métricas de Éxito

### Indicadores de que la refactorización fue exitosa:

- ✅ Todos los tests pasan
- ✅ No hay imports desde `models/`
- ✅ No hay `forwardRef()` innecesarios
- ✅ Cada módulo es autocontenido
- ✅ Build sin warnings de TypeScript
- ✅ Tiempo de CI/CD sin incremento significativo
- ✅ Coverage de tests se mantiene o mejora

---

## 🎯 Beneficios Post-Refactorización

1. **Escalabilidad**
   - Fácil extraer módulos a microservicios
   - Cada dominio es independiente

2. **Mantenibilidad**
   - Código más organizado y predecible
   - Fácil onboarding de nuevos desarrolladores

3. **Testing**
   - Módulos se pueden testear aisladamente
   - Mocks más simples

4. **Desarrollo en equipo**
   - Menos conflictos en Git
   - Equipos pueden trabajar en dominios diferentes

5. **Performance**
   - Imports más eficientes
   - Lazy loading modular (si se implementa)

---

## 📚 Referencias

- [NestJS Best Practices](https://docs.nestjs.com/techniques/performance)
- [Domain-Driven Design](https://martinfowler.com/bliki/DomainDrivenDesign.html)
- [TypeORM Best Practices](https://orkhan.gitbook.io/typeorm/docs/active-record-data-mapper)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

---

## 📝 Notas Adicionales

### Consideraciones para el futuro:

1. **Implementar arquitectura hexagonal (opcional)**
   - Separar domain, application, infrastructure
   - Usar casos de uso en lugar de servicios gordos

2. **CQRS (Command Query Responsibility Segregation)**
   - Para operaciones complejas
   - Separar lecturas de escrituras

3. **Event-driven architecture**
   - Eventos de dominio entre módulos
   - Desacoplamiento total

4. **Microservicios (largo plazo)**
   - Con esta estructura, cada módulo puede convertirse en microservicio
   - Minimal refactoring needed

---

**Última actualización**: Marzo 2026  
**Estado**: Documentado - Pendiente implementación  
**Prioridad**: Alta  
**Estimación**: 2-3 semanas (implementación gradual)
