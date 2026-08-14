# 26 · Análisis de integridad, flujo de datos, multi-tenant y seguridad

> Estado del proyecto y base para priorizar el avance.
> Fecha de análisis: 2026-06-10 · Alcance: `backend/` (NestJS) + `front/` (Next.js).

---

## 1. Objetivo

Verificar que la plataforma garantice:

1. **Aislamiento multi-tenant**: cada institución ve y opera **solo** sus equipos, documentos y mantenciones.
2. **Integridad del flujo de datos**: institución → equipos → (documentos · mantenciones · QR), con `soft delete` y trazabilidad.
3. **Postura de seguridad**: RLS (a nivel app), CORS, security headers, rate limit, JWT httpOnly y no exposición de secretos.

---

## 2. Modelo de datos y flujo

```
Institution (tenant)
  ├─ InstitutionSettings (branding/config)
  ├─ Users  ──< UserInstitution (rol por institución)
  ├─ Clients
  └─ Equipment (institutionId)
        ├─ EquipmentQrCode  ──< QrScanLog
        ├─ EquipmentDocument ──< EquipmentDocumentVersion
        └─ EquipmentMaintenance ──< { Photo · Document · Log }
```

- **Tenant key**: `institutionId` viaja en el JWT (`{ sub, email, institutionId, role }`) y se emite en login a partir de `user_institution` activa — ver [auth.service.ts](../backend/src/auth/auth.service.ts).
- **Soft delete**: todas las entidades tienen `createdAt/updatedAt/deletedAt`; las queries filtran `deleted_at IS NULL`.
- **Almacenamiento de archivos**: dual local (`public/`) o S3 vía `S3Service`, con `getSignedUrl` para descargas.
- **Flujo QR**: se generan QR en lote (disponibles) → se **enrolan** a un equipo → escaneo público registra `QrScanLog` (con dedupe e IP).

---

## 3. Análisis multi-tenant (RLS a nivel aplicación)

> No hay RLS de base de datos (MySQL, `synchronize:false`); el aislamiento depende 100% de filtros `institutionId` en cada servicio/controlador. Esto exige disciplina total: **cualquier endpoint que olvide el filtro rompe el aislamiento.**

### ✅ Bien aislados
| Recurso | Evidencia |
|---|---|
| Clientes | `findAllByInstitution`, `findOne(id, institutionId)`, `update/remove` reciben `institutionId` — [clients.service.ts](../backend/src/clients/clients.service.ts) |
| Usuarios | Todo se filtra por `ui.institutionId` — [users.service.ts](../backend/src/users/users.service.ts) |
| Listado de equipos | `GET /equipments` usa `req.user.institutionId` — [equipment.controller.ts:237](../backend/src/equipment/equipment.controller.ts#L237) |
| Listado de documentos | `GET /equipments/documents` filtra por `equipment.institutionId` — [equipment.controller.ts:56](../backend/src/equipment/equipment.controller.ts#L56) |

### ⚠️ Brechas de aislamiento (IDOR / cross-tenant)
| # | Endpoint | Problema | Sev. |
|---|---|---|---|
| T1 | `PUT /equipments/:id` y `DELETE /equipments/:id` | Guard de rol `admin/super`, pero `update`/`softDelete` **no verifican `institutionId`** → un admin puede editar/borrar equipos de **otra** institución por ID. [equipment.service.ts:165](../backend/src/equipment/equipment.service.ts#L165) | **Alta** |
| T2 | `DELETE /equipments/documents/:docId` | Solo `JwtAuthGuard`, sin chequeo de institución → borrado de documentos de otro tenant. [equipment.controller.ts:128](../backend/src/equipment/equipment.controller.ts#L128) | **Alta** |
| T3 | `POST /equipments` (`create`) | `institutionId` se toma del **body**, no del JWT → se puede crear equipo en otra institución. [equipment.controller.ts:281](../backend/src/equipment/equipment.controller.ts#L281) | **Alta** |
| T4 | `GET /qr` (`findAll`) | Devuelve **todos** los QR de **todas** las instituciones, sin filtro. [qr.controller.ts:27](../backend/src/qr/qr.controller.ts#L27) | **Alta** |
| T5 | `GET /equipments/:id` (público) | `findOne` no filtra por institución; expone datos de cualquier equipo por enumeración de ID. [equipment.controller.ts:242](../backend/src/equipment/equipment.controller.ts#L242) | Media |
| T6 | `POST /equipments/scan-counts` | `equipmentIds` del body no se validan contra la institución del usuario. [equipment.controller.ts:41](../backend/src/equipment/equipment.controller.ts#L41) | Media |
| T7 | Mantenciones públicas (`/:id/logs`, `/:id/photos`, `/:id/documents`, `/equipment/:id`, `/documents/:docId/download`) | Sin autenticación ni chequeo de tenant; cualquiera con un ID lee mantenciones/archivos. [maintenances.controller.ts](../backend/src/maintenances/maintenances.controller.ts) | Media |
| T8 | `POST /equipments/:id/documents` y `PUT /maintenances/:id` | No validan que el equipo/mantención pertenezca a la institución del usuario. | Media |

**Nota de diseño**: parte de los GET públicos son intencionales (vista QR pública). El riesgo está en (a) mutaciones sin scope (T1–T3) y (b) lecturas privadas expuestas sin auth (T7). Conviene separar explícitamente *endpoints públicos por token QR* de *endpoints administrativos por ID*.

---

## 4. Análisis de seguridad

### 4.1 RLS
- **Estado**: ❌ No existe RLS de BD. ⚠️ El "RLS a nivel app" es **parcial** (ver §3). 
- **Acción**: introducir un patrón único de scoping (helper/guard que inyecte `institutionId` y lo exija en cada query de servicio) para eliminar la dependencia de recordarlo endpoint por endpoint.

### 4.2 CORS
- **Estado**: ⚠️ Riesgoso. [main.ts:52](../backend/src/main.ts#L52) usa `origin: true` (refleja **cualquier** origen) **junto con** `credentials: true`. Esto permite que cualquier sitio haga peticiones autenticadas con la cookie.
- **Acción**: reemplazar `origin: true` por una whitelist (`https://enfoqueqr.cl`, subdominios y `localhost:3000` en dev).

### 4.3 Security headers
- **Estado**: ❌ No hay `helmet` ni headers de seguridad (sin `Content-Security-Policy`, `HSTS`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`).
- **Acción**: agregar `helmet()` en `bootstrap()` con CSP acorde a Swagger/CDN y assets propios.

### 4.4 Rate limit
- **Estado**: ⚠️ Funcional pero limitado. Guard global con `@RateLimit(max, windowMs)` por endpoint — [rate-limit.guard.ts](../backend/src/core/guards/rate-limit.guard.ts). Login `10/min`, escaneos `20/min`, descargas `30/min`.
- **Limitaciones**: store **en memoria** (`Map`) → no comparte estado entre instancias; en Vercel serverless **se reinicia en cada cold start**, lo que vuelve el límite poco fiable. Se aplica por IP, fácil de eludir tras proxies sin `trust proxy`.
- **Acción**: para prod serverless, mover a store compartido (Redis/Upstash) o usar el rate limit del edge/gateway. Configurar `app.set('trust proxy', 1)` para obtener la IP real.

### 4.5 JWT httpOnly
- **Estado**: ✅ Correcto en lo esencial. Cookie `token` `httpOnly`, `secure` en prod, `sameSite:'none'` + `domain:'.enfoqueqr.cl'` en prod, `maxAge` 24h — [auth.controller.ts:10](../backend/src/auth/auth.controller.ts#L10). `ignoreExpiration:false`.
- **⚠️ Riesgo crítico**: fallback `secretOrKey: process.env.JWT_SECRET || 'supersecret'` — [jwt.strategy.ts:13](../backend/src/auth/jwt.strategy.ts#L13). Si `JWT_SECRET` no está seteado, se firman/validan tokens con un secreto público → cualquiera puede forjar JWTs. Debe **fallar el arranque** si falta el secreto, sin fallback.
- **Otros**: sin mecanismo de refresh/rotación ni revocación; logout solo limpia cookie del cliente.

### 4.6 Exposición de secretos
- **Estado**: ✅ Sin `.env` versionados (solo `.env.example`); `.gitignore` cubre `.env*`.
- **⚠️ Revisar**: generación de token QR **inconsistente** — el batch usa `crypto.randomUUID()` ([qr.service.ts:76](../backend/src/qr/qr.service.ts#L76)) pero el alta directa de equipo usa `Math.random()` ([equipment.service.ts:114](../backend/src/equipment/equipment.service.ts#L114)), que **no es criptográficamente seguro** y es predecible/colisionable. Unificar a `crypto`.
- **Acción adicional**: confirmar que ninguna `NEXT_PUBLIC_*` del front contenga llaves sensibles (las `NEXT_PUBLIC_` se exponen al cliente por diseño).

---

## 5. Hallazgos priorizados

| Prioridad | ID | Hallazgo | Esfuerzo |
|---|---|---|---|
| 🔴 P0 | S-JWT | Fallback `'supersecret'` en JWT → forja de tokens | Bajo |
| 🔴 P0 | T1–T4 | Mutaciones/listados sin scope de `institutionId` (cross-tenant) | Medio |
| 🔴 P0 | S-CORS | `origin:true` + `credentials:true` | Bajo |
| 🟠 P1 | S-HDR | Falta `helmet`/security headers | Bajo |
| 🟠 P1 | T5–T8 | Lecturas privadas expuestas sin auth / IDOR por ID | Medio |
| 🟠 P1 | S-QR | `Math.random()` para tokens QR | Bajo |
| 🟡 P2 | S-RL | Rate limit en memoria no fiable en serverless | Medio |
| 🟡 P2 | S-REF | Sin refresh/revocación de JWT | Medio |

---

## 6. Próximos pasos sugeridos

1. **Quick wins de seguridad (P0/P1, bajo esfuerzo)**: exigir `JWT_SECRET`, whitelist CORS, `helmet`, unificar tokens QR a `crypto`.
2. **Hardening multi-tenant (P0, medio)**: crear un patrón único de scoping por `institutionId` y aplicarlo a equipos, QR y mantenciones (mutaciones primero).
3. **Separar superficie pública vs. privada**: endpoints públicos solo por **token QR**; todo lo administrativo bajo `JwtAuthGuard` + scope de institución.
4. **Rate limit production-ready**: store compartido + `trust proxy`.
5. **Trazabilidad/refresh JWT**: evaluar refresh token y revocación.

---

## 7. Estado de implementación (2026-06-11)

| ID | Hallazgo | Estado |
|---|---|---|
| S-JWT | Fallback `'supersecret'` eliminado; arranque falla sin `JWT_SECRET` | ✅ Resuelto |
| S-CORS | Whitelist + subdominios `*.enfoqueqr.cl` (sin `origin:true`) | ✅ Resuelto |
| S-HDR | `helmet` con CSP compatible con Swagger | ✅ Resuelto |
| S-QR | Token de QR con `crypto.randomUUID()` | ✅ Resuelto |
| T1, T3, T5 | Equipos: create/update/delete/get scopeados por `institutionId` (institución desde el JWT) | ✅ Resuelto |
| T2 | Documentos de equipo: add/delete scopeados por institución | ✅ Resuelto |
| T4 | Listado de QR scopeado (asignados de la institución + pool) | ✅ Resuelto |
| T6 | `scan-counts` filtra IDs a la institución | ✅ Resuelto |
| T7 | Lecturas de mantenciones: **públicas por diseño** (vista QR) | ⚪ Por diseño |
| T8 | Escrituras de mantenciones (update/upload/delete/restore) scopeadas | ✅ Resuelto |
| S-RL | Rate limit con store compartido (Redis opcional vía `REDIS_URL`) + `trust proxy` | ✅ Resuelto |
| S-REF | Access corto + refresh token con rotación (back) e interceptor de `fetch` (front) + revocación por `jti` | ✅ Resuelto |
| T7-priv | Documentos de equipo `isPrivate`: descarga y listado público ocultan privados a quien no es de la institución | ✅ Resuelto |

**Notas / deuda residual:**
- T7: las lecturas públicas siguen siendo enumerables por ID secuencial. Como la vista del QR ya es pública, el riesgo marginal es bajo; si se requiere endurecer, exponer estas lecturas **solo vía token QR** en lugar de por ID.
- ~~Descarga de documentos de equipo privados por enumeración de `docId`.~~ ✅ Resuelto: tanto la descarga como el listado público validan la institución vía cookie y ocultan los `isPrivate` a quien no corresponde.

---

### Apéndice · Convenciones verificadas
- Multi-tenant por `institutionId` en JWT ✅ · Soft delete global ✅ · Cookie httpOnly ✅
- Pendiente formalizar checklist de seguridad en `docs/convenciones.md` (scope obligatorio + guards por endpoint).
