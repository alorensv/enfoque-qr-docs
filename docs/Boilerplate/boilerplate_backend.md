# NestJS Boilerplate 2026: Arquitectura Hexagonal y Alto Rendimiento

Este boilerplate define el estándar de oro para el backend de **Enfoque QR** en 2026. Se basa en los principios de **Arquitectura Hexagonal (Ports & Adapters)**, **Domain-Driven Design (DDD)** y un enfoque extremo en **Observabilidad** y **Seguridad**.

---

## 🚀 Stack Tecnológico (Estándar 2026)

*   **Core**: NestJS 11+ (Motor **Fastify** para +20% performance).
*   **Lenguaje**: TypeScript 5.8+ (Strict Mode, ESM por defecto).
*   **ORM**: **Drizzle ORM** (Recomendado para nuevas islas) o **TypeORM + Data Mapper**.
*   **Validación**: **Valibot** (Zero-bundle size) o **Zod**.
*   **Testing**: **Vitest** (Velocidad instantánea) + **TestContainers**.
*   **Observabilidad**: **OpenTelemetry** + **Pino** (Structured Logging).
*   **Documentación**: **Scalar** (Sustituto moderno de Swagger UI).

---

## 🏗️ Estructura de Directorios (Hexagonal)

Cada módulo (Dominio) debe seguir esta estructura para garantizar el desacoplamiento total:

```text
src/[feature]/
├── domain/                      # 🧠 CAPA DE DOMINIO (Reglas de Negocio)
│   ├── entities/                # Objetos de dominio puros (sin decoradores de DB)
│   ├── repositories/            # Interfaces de repositorios (Ports)
│   ├── services/                # Lógica de negocio pura
│   └── exceptions/              # Excepciones personalizadas del dominio
├── application/                 # ⚙️ CAPA DE APLICACIÓN (Orquestación)
│   ├── use-cases/               # Casos de uso (una clase por acción)
│   ├── dto/                     # Schemas de validación (Valibot/Zod)
│   └── mappers/                 # Conversión entre Domain <-> DTO
└── infrastructure/              # 🔌 CAPA DE INFRAESTRUCTURA (Detalles Técnicos)
    ├── controllers/             # Endpoints REST / Fastify
    ├── persistence/             # Implementación de Repositorios (Adapters)
    │   ├── entities/            # Schemas de TypeORM/Drizzle (Mapeo físico)
    │   └── repositories/        # Implementaciones concretas
    └── services/                # Adaptadores de terceros (AWS S3, Mailer, etc.)
```

---

## 🛠️ Ejemplo Práctico: Módulo `Equipment`

### 1. Dominio: Entidad Pura (`domain/entities/equipment.entity.ts`)
```typescript
export class Equipment {
  constructor(
    public readonly id: string,
    public name: string,
    public institutionId: number,
    public status: 'active' | 'maintenance' | 'retired',
    public createdAt: Date
  ) {}

  public markAsInMaintenance() {
    this.status = 'maintenance';
  }
}
```

### 2. Aplicación: Caso de Uso (`application/use-cases/create-equipment.use-case.ts`)
```typescript
import { Injectable, Inject } from '@nestjs/common';
import { Equipment } from '../../domain/entities/equipment.entity';
import { IEquipmentRepository } from '../../domain/repositories/equipment.repository.interface';

@Injectable()
export class CreateEquipmentUseCase {
  constructor(
    @Inject('IEquipmentRepository')
    private readonly repository: IEquipmentRepository,
  ) {}

  async execute(data: CreateEquipmentDto): Promise<Equipment> {
    const equipment = new Equipment(
      crypto.randomUUID(),
      data.name,
      data.institutionId,
      'active',
      new Date()
    );
    
    return this.repository.save(equipment);
  }
}
```

### 3. Infraestructura: Controlador (`infrastructure/controllers/equipment.controller.ts`)
```typescript
import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { CreateEquipmentUseCase } from '../../application/use-cases/create-equipment.use-case';
import { ValibotGuard } from '@core/guards/valibot.guard';

@ApiTags('Equipments')
@Controller('equipments')
export class EquipmentController {
  constructor(private readonly createEquipment: CreateEquipmentUseCase) {}

  @Post()
  @ApiOperation({ summary: 'Crea un nuevo equipo con validación 2026' })
  async create(@Body() dto: CreateEquipmentDto) {
    return this.createEquipment.execute(dto);
  }
}
```

---

## 🔒 Seguridad & Hardening

1.  **JWT HttpOnly + Refresh Tokens**: Nunca almacenar tokens en `localStorage`.
2.  **Strict CSP & Helmet**: Configuración agresiva de cabeceras de seguridad.
3.  **Rate Limiting**: Aplicado por IP e InstitutionID para evitar fuerza bruta en QRs.
4.  **Zonificación de Red**: El backend solo acepta peticiones desde el API Gateway/Cloudflare.

---

## 📊 Observabilidad (Pino + OpenTelemetry)

Los logs deben ser estructurados (JSON) para su fácil ingesta en Datadog/ELK:

```typescript
// logger.service.ts
this.logger.info({
  event: 'equipment_created',
  equipmentId: '...',
  institutionId: '...',
  latency: 45, // ms
});
```

---

## 🐳 Dockerfile 2026 (Multi-stage & Distroless)

Uso de imágenes minimalistas para reducir superficie de ataque.

```dockerfile
# Stage 1: Build
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

# Stage 2: Runtime
FROM gcr.io/distroless/nodejs22-debian12
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["dist/main.js"]
```

---

## ✅ Checklist de "Pase a Producción"

- [ ] ¿El dominio es independiente de TypeORM/Drizzle?
- [ ] ¿Todos los flujos tienen un Caso de Uso definido?
- [ ] ¿Se usa `Valibot`/`Zod` en lugar de `class-validator`?
- [ ] ¿Vitest alcanza el 80% de coverage en la capa de Domain?
- [ ] ¿El endpoint está documentado en Scalar (`/docs`)?
