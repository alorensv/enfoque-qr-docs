# 17 — Seguridad: Rate Limiting Global Anti-Bot

## 1️⃣ OBJETIVO

Proteger **todos los endpoints públicos** (sin JWT) contra abuso automatizado (bots, scraping, fuerza bruta) mediante rate limiting por IP a nivel de aplicación.

---

## 2️⃣ ARQUITECTURA

### Componentes creados

| Archivo | Tipo | Descripción |
|---|---|---|
| `core/decorators/rate-limit.decorator.ts` | Decorator | `@RateLimit(max, windowMs)` — configura límites por endpoint |
| `core/guards/rate-limit.guard.ts` | Guard global | `RateLimitGuard` — intercepta toda petición y aplica límite si tiene decorator |
| `core/core.module.ts` | Módulo | Registra el guard globalmente vía `APP_GUARD` |

### Flujo de una petición

```
Request → RateLimitGuard
  ├─ ¿Tiene @RateLimit? NO → pasa libremente
  └─ ¿Tiene @RateLimit? SÍ
       ├─ Clave = "Controller:handler:IP"
       ├─ ¿Dentro de ventana y bajo límite? → pasa (count++)
       └─ ¿Excede límite? → HTTP 429 "Demasiadas solicitudes"
```

### Almacenamiento en memoria

- **Map** en el guard con clave `Controller:handler:IP`
- Cada entrada almacena `{ count, resetAt }`
- Limpieza automática de entradas expiradas cada 5 minutos
- Sin dependencias externas (no requiere Redis)

---

## 3️⃣ CONFIGURACIÓN DE LÍMITES POR ENDPOINT

### Auth (`/auth`)

| Método | Ruta | Límite | Razón |
|---|---|---|---|
| POST | `/auth/login` | **10 req/min** | Protección contra fuerza bruta |
| POST | `/auth/logout` | 20 req/min | Protección básica |

### QR (`/qr`)

| Método | Ruta | Límite | Razón |
|---|---|---|---|
| POST | `/qr/:token/scan` | **20 req/min** | Anti-bot escaneo + dedup en servicio |
| GET | `/qr/:token` | 60 req/min | Consulta pública |
| GET | `/qr/:token/image` | 30 req/min | Descarga de imagen |

### Equipos (`/equipments`)

| Método | Ruta | Límite | Razón |
|---|---|---|---|
| GET | `/equipments/:id` | 60 req/min | Consulta pública |
| GET | `/equipments/by-qr/:token` | 60 req/min | Consulta por QR |
| GET | `/equipments/:id/documents` | 60 req/min | Lista documentos |
| GET | `/equipments/documents/:docId/download` | 30 req/min | Descarga de archivo |
| GET | `/equipments/:id/photo` | 30 req/min | Descarga de foto |
| GET | `/equipments/search-by-serial/:slug/:serial` | **20 req/min** | Previene enumeración de seriales |

### Mantenciones (`/maintenances`)

| Método | Ruta | Límite | Razón |
|---|---|---|---|
| GET | `/maintenances/:id` | 60 req/min | Consulta pública |
| GET | `/maintenances/:id/logs` | 60 req/min | Logs de mantención |
| GET | `/maintenances/:id/photos` | 60 req/min | Lista fotos |
| GET | `/maintenances/:id/documents` | 60 req/min | Lista documentos |
| GET | `/maintenances/documents/:docId/download` | 30 req/min | Descarga archivo |
| GET | `/maintenances/photos/:photoId/file` | 30 req/min | Descarga foto |
| GET | `/maintenances/equipment/:equipmentId` | 60 req/min | Mantenciones por equipo |

### Instituciones (`/institutions`)

| Método | Ruta | Límite | Razón |
|---|---|---|---|
| GET | `/institutions/by-slug/:slug` | 60 req/min | Consulta pública |
| GET | `/institutions/:id` | 60 req/min | Consulta pública |

---

## 4️⃣ CRITERIOS DE LÍMITES

| Categoría | Límite | Aplicación |
|---|---|---|
| **Crítico** | 10 req/min | Login (fuerza bruta) |
| **Escritura pública** | 20 req/min | Scan QR, búsqueda serial |
| **Descarga de archivos** | 30 req/min | Fotos, documentos, imágenes QR |
| **Lectura general** | 60 req/min | Consultas de datos públicos |

---

## 5️⃣ USO DEL DECORATOR

```typescript
import { RateLimit } from '../core/decorators/rate-limit.decorator';

// Aplicar a un endpoint específico
@Get('endpoint')
@RateLimit(60, 60_000)  // 60 peticiones por minuto
async myHandler() { ... }

// Valores por defecto: @RateLimit() = 60 req/min
@Get('otro')
@RateLimit()
async otroHandler() { ... }
```

**Parámetros:**
- `max` (number): Máximo de peticiones permitidas en la ventana (default: 60)
- `windowMs` (number): Ventana de tiempo en milisegundos (default: 60_000)

---

## 6️⃣ RESPUESTA AL EXCEDER LÍMITE

```json
HTTP 429 Too Many Requests
{
  "statusCode": 429,
  "message": "Demasiadas solicitudes. Intente más tarde."
}
```

---

## 7️⃣ ENDPOINTS PROTEGIDOS POR JWT (SIN RATE LIMIT)

Los endpoints con `@UseGuards(JwtAuthGuard)` **no requieren** rate limit adicional porque:
- Requieren autenticación válida (cookie httpOnly JWT)
- El propio flujo de login ya está rate-limited
- El usuario autenticado queda identificado por su sesión

---

## 8️⃣ RESUMEN DE SEGURIDAD MULTICAPA

```
Capa 1: Rate Limit por IP → @RateLimit(max, windowMs)
Capa 2: Deduplicación IP+QR → QrScanLogService (ventana 10 min)
Capa 3: Autenticación JWT → @UseGuards(JwtAuthGuard)
Capa 4: httpOnly Cookies → Previene XSS de robo de token
Capa 5: Soft Delete → Los datos nunca se eliminan físicamente
```

---

## 9️⃣ CONSIDERACIONES DE ESCALADO

- **Instancia única**: El rate limiter en memoria funciona correctamente con una instancia de backend.
- **Múltiples instancias**: Si se escala a varios pods/contenedores, cada uno tendrá su propio Map. Para rate limiting distribuido, migrar a **Redis** con `@nestjs/throttler` o implementación custom.
- **Limpieza de memoria**: Las entradas expiradas se eliminan automáticamente cada 5 minutos.

---

## 🔟 ARCHIVOS MODIFICADOS

| Archivo | Cambio |
|---|---|
| `core/decorators/rate-limit.decorator.ts` | **NUEVO** — Decorator `@RateLimit` |
| `core/guards/rate-limit.guard.ts` | **NUEVO** — Guard global `RateLimitGuard` |
| `core/core.module.ts` | Registra `RateLimitGuard` como `APP_GUARD` |
| `auth/auth.controller.ts` | `@RateLimit` en login (10/min) y logout (20/min) |
| `qr/qr.controller.ts` | Removido rate limiter inline; `@RateLimit` en scan (20/min), token (60/min), image (30/min) |
| `equipment/equipment.controller.ts` | `@RateLimit` en 6 endpoints públicos |
| `maintenances/maintenances.controller.ts` | `@RateLimit` en 7 endpoints públicos |
| `institutions/institutions.controller.ts` | `@RateLimit` en 2 endpoints públicos |
| `common/institutions.controller.ts` | `@RateLimit` en 2 endpoints públicos |
