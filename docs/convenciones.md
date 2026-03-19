
# Instrucciones
1. Responder siempre en español.

---

# Convenciones y Principios del Proyecto EnfoqueQR

> Guía de referencia para mantener consistencia al agregar nuevos módulos o "islas" al proyecto.

---

## 1. Arquitectura General

### 1.1 Arquitectura hexagonal (opcional, largo plazo)
- Separar domain, application, infrastructure
- Usar casos de uso en lugar de servicios gordos

### 1.2 CQRS (Command Query Responsibility Segregation)
- Para operaciones complejas
- Separar lecturas de escrituras

### 1.3 Event-driven architecture
- Eventos de dominio entre módulos
- Desacoplamiento total

### 1.4 Microservicios (largo plazo)
- Con esta estructura, cada módulo puede convertirse en microservicio
- Mínimo refactoring necesario

### 1.5 Principios SOLID
- **S**: Una clase, un propósito
- **O**: Abierto a extensión, cerrado a modificación
- **L**: Las subclases deben ser sustituibles por sus bases
- **I**: Interfaces pequeñas y especializadas
- **D**: Depender de abstracciones, no de implementaciones concretas

---

## 2. Convenciones Backend (NestJS)

### 2.1 Estructura de módulos
<!-- Cada feature vive en su propia carpeta con controller, service, module, dto/ y entities/ -->
```
src/
  [feature]/
    [feature].controller.ts    # Endpoints REST
    [feature].service.ts       # Lógica de negocio + acceso a datos
    [feature].module.ts        # Registro del módulo NestJS
    dto/
      create-[feature].dto.ts  # Validación de entrada (class-validator)
      update-[feature].dto.ts
    entities/
      [feature].entity.ts      # Entidad TypeORM
```

### 2.2 Naming conventions
| Elemento            | Convención           | Ejemplo                          |
|---------------------|----------------------|----------------------------------|
| Archivos            | kebab-case           | `equipment.controller.ts`        |
| Clases              | PascalCase           | `EquipmentController`            |
| Métodos/variables   | camelCase            | `findAllByInstitution()`         |
| Rutas REST          | plural lowercase     | `/equipments`, `/maintenances`   |
| Columnas BD         | snake_case           | `created_at`, `institution_id`   |
| Entidades TS        | camelCase (mapped)   | `createdAt` → `@Column({ name: 'created_at' })` |

### 2.3 Base de datos y entidades
<!-- TypeORM con MySQL. Soft-delete en todas las entidades via deletedAt -->
- ORM: **TypeORM** con repositorios inyectados via `TypeOrmModule.forFeature()`
- Toda entidad debe incluir: `id`, `createdAt`, `updatedAt`, `deletedAt` (nullable)
- Filtrar siempre por `deletedAt IS NULL` en consultas
- Índices en campos frecuentemente consultados: `@Index('idx_campo', ['campo'])`
- Relaciones: `@ManyToOne()`, `@OneToMany()`, `@JoinColumn()`

### 2.4 Autenticación y seguridad
<!-- JWT almacenado en cookie httpOnly, no en Authorization header -->
- JWT via **httpOnly cookie** (no Bearer header)
- Guard: `@UseGuards(JwtAuthGuard)` en rutas protegidas
- Payload JWT: `{ sub, email, institutionId, role }`
- Contraseñas: **bcryptjs**
- CORS configurado por dominio

### 2.5 Validación (DTOs)
<!-- Usar class-validator en cada DTO de entrada -->
- Decoradores: `@IsNotEmpty()`, `@IsString()`, `@IsNumber()`, `@IsOptional()`
- Anidar DTOs cuando sea necesario (ej: `EnrollEquipmentDto` contiene `CreateEquipmentDataDto`)

### 2.6 Archivos y storage
<!-- Soporte dual: local (public/) y AWS S3, controlado por variable de entorno -->
- Multer + `FileInterceptor` para subida de archivos
- Dual mode: local (`public/`) o AWS S3 (vía `S3Service`)
- Límite: 20MB (`FileSizeInterceptor`)

### 2.7 Logging
- `LoggerService` global (archivos `info.log`, `errors.log` + consola)

### 2.8 Documentación API
- Swagger en `/api-docs`
- Decoradores: `@ApiTags()`, `@ApiCookieAuth('token')`

---

## 3. Convenciones Frontend (Next.js — Pages Router)

### 3.1 Estructura de páginas
<!-- Pages Router (no App Router). Rutas dinámicas con [param] -->
```
pages/
  index.js                     # Landing / login
  admin/
    [recurso].js               # CRUD de cada recurso
  qr/
    [token].js                 # Vista pública del equipo
  api/
    proxy-endpoint.js          # (si aplica) proxy a backend
```

### 3.2 Naming conventions
| Elemento        | Convención       | Ejemplo              |
|-----------------|------------------|----------------------|
| Componentes     | PascalCase       | `AdminLayout.js`     |
| Páginas         | lowercase        | `equipos.js`         |
| Variables       | camelCase        | `isLoading`          |
| Servicios       | camelCase        | `api.js` → `equipmentApi` |

### 3.3 Estado y datos
<!-- Context API para auth, useState local para formularios. Sin Redux ni SWR -->
- Auth global: `AuthContext` + `useAuth()`
- Estado local: `useState` / `useEffect`
- Sin librería externa de estado

### 3.4 Comunicación con API
<!-- fetch nativo, sin axios. Credenciales include para cookies httpOnly -->
- `fetch()` nativo con `credentials: 'include'`
- Servicio centralizado en `services/api.js` (funciones por recurso)
- Subida de archivos: `FormData` multipart

### 3.5 Protección de rutas
<!-- HOC withAuth() verifica sesión y redirige si no autenticado -->
- `withAuth(Component)` — HOC que valida sesión
- Redirige a `/` si no autenticado

### 3.6 Estilos
- Principal: **Tailwind CSS** (clases utilitarias)
- Fuente: Urbanist (Google Fonts)
- Evitar inline styles en código nuevo; preferir Tailwind

### 3.7 Layout admin
<!-- AdminLayout envuelve todas las páginas /admin/* -->
- `AdminLayout` → Header fijo + Sidebar (220px) + contenido principal
- `ProfileMenu` en header para acciones de usuario

---

## 4. Principios Generales

1. **DRY** — No repetir lógica; extraer a servicios compartidos (`core/`)
2. **KISS** — Soluciones simples; evitar abstracciones innecesarias
3. **Fail fast** — Validar entradas lo antes posible (DTOs, guards)
4. **Soft delete** — Nunca borrar registros físicamente
5. **Modularidad** — Cada feature es independiente y autocontenida
6. **Español en UI** — Todo el texto visible al usuario en español
7. **Sin dependencias innecesarias** — Evaluar antes de agregar un paquete nuevo

---

## 5. Boilerplate: Nueva "Isla" (Feature Module)

> Plantilla de referencia para crear un nuevo módulo. Reemplazar `[feature]` por el nombre del recurso (ej: `tickets`, `inspections`, `alerts`).

### 5.1 Backend — NestJS

**Entidad** — `src/[feature]/entities/[feature].entity.ts`
```typescript
// Entidad TypeORM con soft-delete y relación a institución
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, Index } from 'typeorm';
import { Institution } from '../../institutions/entities/institution.entity';

@Entity('[feature]')
export class Feature {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'nombre' })
  nombre: string;

  @Column({ name: 'institution_id' })
  @Index('idx_[feature]_institution')
  institutionId: number;

  @ManyToOne(() => Institution)
  @JoinColumn({ name: 'institution_id' })
  institution: Institution;

  @Column({ name: 'created_at', type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  updatedAt: Date;

  @Column({ name: 'deleted_at', type: 'timestamp', nullable: true })
  deletedAt: Date;
}
```

**DTO** — `src/[feature]/dto/create-[feature].dto.ts`
```typescript
// Validación de datos de entrada con class-validator
import { IsNotEmpty, IsString, IsNumber } from 'class-validator';

export class CreateFeatureDto {
  @IsNotEmpty()
  @IsString()
  nombre: string;

  @IsNotEmpty()
  @IsNumber()
  institutionId: number;
}
```

**Servicio** — `src/[feature]/[feature].service.ts`
```typescript
// Lógica de negocio. Consultas filtran siempre por deletedAt IS NULL
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Feature } from './entities/[feature].entity';
import { CreateFeatureDto } from './dto/create-[feature].dto';

@Injectable()
export class FeatureService {
  constructor(
    @InjectRepository(Feature)
    private readonly featureRepository: Repository<Feature>,
  ) {}

  async findAllByInstitution(institutionId: number): Promise<Feature[]> {
    return this.featureRepository
      .createQueryBuilder('[feature]')
      .where('[feature].institution_id = :institutionId', { institutionId })
      .andWhere('[feature].deleted_at IS NULL')
      .orderBy('[feature].created_at', 'DESC')
      .getMany();
  }

  async findOne(id: number): Promise<Feature> {
    const item = await this.featureRepository
      .createQueryBuilder('[feature]')
      .where('[feature].id = :id', { id })
      .andWhere('[feature].deleted_at IS NULL')
      .getOne();

    if (!item) throw new NotFoundException('Recurso no encontrado');
    return item;
  }

  async create(dto: CreateFeatureDto): Promise<Feature> {
    const entity = this.featureRepository.create(dto);
    return this.featureRepository.save(entity);
  }

  async softDelete(id: number): Promise<void> {
    await this.featureRepository.update(id, { deletedAt: new Date() });
  }
}
```

**Controller** — `src/[feature]/[feature].controller.ts`
```typescript
// Endpoints REST protegidos con JWT. Documentados con Swagger
import { Controller, Get, Post, Delete, Param, Body, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiCookieAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { FeatureService } from './[feature].service';
import { CreateFeatureDto } from './dto/create-[feature].dto';

@ApiTags('[feature]')
@Controller('[feature]')
export class FeatureController {
  constructor(private readonly featureService: FeatureService) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiCookieAuth('token')
  findAll(@Req() req) {
    return this.featureService.findAllByInstitution(req.user.institutionId);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiCookieAuth('token')
  findOne(@Param('id') id: number) {
    return this.featureService.findOne(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiCookieAuth('token')
  create(@Body() dto: CreateFeatureDto) {
    return this.featureService.create(dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiCookieAuth('token')
  remove(@Param('id') id: number) {
    return this.featureService.softDelete(id);
  }
}
```

**Módulo** — `src/[feature]/[feature].module.ts`
```typescript
// Registrar entidad, servicio y controller. Importar en AppModule
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Feature } from './entities/[feature].entity';
import { FeatureService } from './[feature].service';
import { FeatureController } from './[feature].controller';

@Module({
  imports: [TypeOrmModule.forFeature([Feature])],
  controllers: [FeatureController],
  providers: [FeatureService],
  exports: [FeatureService],
})
export class FeatureModule {}
```

### 5.2 Frontend — Next.js

**Servicio API** — Agregar en `services/api.js`
```javascript
// Funciones de comunicación con el backend para el nuevo recurso
export const featureApi = {
  getAll: async () => {
    const res = await fetch(`${API_URL}/[feature]`, getAuthHeaders());
    if (!res.ok) throw new Error('Error al obtener datos');
    return res.json();
  },

  getById: async (id) => {
    const res = await fetch(`${API_URL}/[feature]/${id}`, getAuthHeaders());
    if (!res.ok) throw new Error('Recurso no encontrado');
    return res.json();
  },

  create: async (data) => {
    const res = await fetch(`${API_URL}/[feature]`, {
      method: 'POST',
      ...getAuthHeaders(),
      headers: { ...getAuthHeaders().headers, 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error('Error al crear');
    return res.json();
  },

  remove: async (id) => {
    const res = await fetch(`${API_URL}/[feature]/${id}`, {
      method: 'DELETE',
      ...getAuthHeaders(),
    });
    if (!res.ok) throw new Error('Error al eliminar');
    return res.json();
  },
};
```

**Página admin** — `pages/admin/[feature].js`
```jsx
// Página CRUD protegida con withAuth. Usa AdminLayout como wrapper
import { useState, useEffect } from 'react';
import AdminLayout from '../../components/AdminLayout';
import withAuth from '../../contexts/withAuth';
import { featureApi } from '../../services/api';

function FeaturePage() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    featureApi.getAll()
      .then(setItems)
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <AdminLayout><p className="text-center py-8">Cargando...</p></AdminLayout>;

  return (
    <AdminLayout>
      <div className="p-6">
        <h1 className="text-2xl font-bold mb-4">[Feature]</h1>
        <table className="w-full bg-white rounded shadow">
          <thead>
            <tr className="bg-gray-50 text-left text-sm text-gray-600">
              <th className="px-4 py-2">Nombre</th>
              <th className="px-4 py-2">Fecha</th>
              <th className="px-4 py-2">Acciones</th>
            </tr>
          </thead>
          <tbody>
            {items.map((item) => (
              <tr key={item.id} className="border-t hover:bg-gray-50">
                <td className="px-4 py-2">{item.nombre}</td>
                <td className="px-4 py-2">{new Date(item.createdAt).toLocaleDateString()}</td>
                <td className="px-4 py-2">
                  <button
                    onClick={() => handleDelete(item.id)}
                    className="text-red-600 hover:underline text-sm"
                  >
                    Eliminar
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </AdminLayout>
  );

  async function handleDelete(id) {
    if (!confirm('¿Eliminar este registro?')) return;
    await featureApi.remove(id);
    setItems((prev) => prev.filter((i) => i.id !== id));
  }
}

export default withAuth(FeaturePage);
```

---

## 6. Checklist para Nueva Feature

- [ ] Crear entidad con `createdAt`, `updatedAt`, `deletedAt`
- [ ] Crear DTO con validaciones `class-validator`
- [ ] Crear servicio con consultas filtradas por `deletedAt IS NULL`
- [ ] Crear controller con `@UseGuards(JwtAuthGuard)` y `@ApiTags`
- [ ] Crear módulo e importar en `AppModule`
- [ ] Agregar funciones en `services/api.js` del front
- [ ] Crear página en `pages/admin/` envuelta con `withAuth()`
- [ ] Usar `AdminLayout` como wrapper
- [ ] Estilar con Tailwind CSS
- [ ] Documentar endpoint en Swagger