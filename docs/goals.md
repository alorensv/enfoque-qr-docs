# Objetivo del proyecto

> Documento que lee `/pm-dashboard` para estructurar el dashboard.
> Cuanto más claro el checklist y las fases, mejor sale el % de avance y el foco del sprint.

## Resumen en una línea

Plataforma **Enfoque QR**: monitoreo y trazabilidad de equipos (y temas en general)
mediante códigos QR, con documentación, mantenciones, fotos e historial de logs
consultables al escanear.

## Foco actual (sprint)

Cerrar las **brechas de seguridad multi-tenant** detectadas en
[26_claude_analisis.md](26_claude_analisis.md) (scope por `institutionId`, JWT,
CORS, headers) y dejar lista la base para el **dashboard por institución** que se
abre al escanear el QR.

## Visión del producto

El foco está en el **QR** y en la **facilidad de consultar información detallada**:

- Cada equipo/tema tiene un QR que, al escanearse, muestra su información,
  documentación y mantenciones.
- **Próxima mejora**: el escaneo abre una **card/dashboard por institución** con
  el listado de equipos, un **resumen por equipo** y acceso al **detalle**.
- Desde ese detalle se podrá **editar y mantener** cada equipo, documento,
  mantención, fotos e **historial de logs**.
- Todo bajo aislamiento estricto por institución (multi-tenant).

## Fases / hitos

- [x] **F0 — Setup**: meta-repo (backend NestJS + front Next.js + Docker), MySQL, Swagger
- [x] **F1 — Auth**: login JWT en cookie httpOnly, roles por institución (`user_institution`)
- [x] **F2 — Gestión de equipos**: alta/edición, foto, documentos, soft delete
- [x] **F3 — QR**: generación en lote, enrolado a equipo, vista pública por token, log de escaneos
- [x] **F4 — Mantenciones**: creación, fotos, documentos, logs y restauración
- [x] **F5 — Seguridad (hardening)**: brechas del doc 26 cerradas (8/8 · multi-tenant, JWT, CORS, headers, rate limit)
- [x] **F6 — QR + dashboard de cliente**: el cliente escanea y ve **solo sus equipos** con documentos públicos y mantenciones en `/qr/cliente/<token>` (token JWT firmado); + gestión ejecutiva de clientes (resumen + última actividad + edición + filtros) y última actividad/filtros en equipos
  - [ ] *(próximo)* Dashboard institución-wide: todos los equipos de la institución en una vista
- [x] **F7 — Edición desde el detalle**: edición de **mantenciones** y gestión de **fotos** (agregar/eliminar), **solo el creador o un admin**, con **historial de cambios** (quién + qué + cuándo)
  - [ ] *(próximo)* Edición de equipo y documentos desde el detalle
- [ ] **F8 — Mejoras de producto + robustez**: branding por institución, métricas/uso, exportes
  - [x] Resiliencia: keepAlive de MySQL, reintento de GET ante 5xx transitorios, `KvStore` con fallback en memoria
  - [x] **DB migrada a GCP** (VM e2-micro + MariaDB) desde BenzaHosting → login cold 115 s → 1.5 s; fix CORS por dominio de institución. Detalle en [27_db_gcp.md](27_db_gcp.md)
  - [ ] *(pendiente DB)* backups automáticos, SSL en 3306, decomisionar BenzaHosting, Redis (Upstash)

## F5 — Checklist de seguridad (desde doc 26)

- [x] **P0** Exigir `JWT_SECRET` (eliminar fallback `'supersecret'`)
- [x] **P0** Scope `institutionId` en mutaciones/listados de equipos y QR (T1–T4)
- [x] **P0** CORS con whitelist (quitar `origin:true` con `credentials:true`)
- [x] **P1** Agregar `helmet` / security headers
- [x] **P1** Cerrar lecturas privadas expuestas e IDOR por ID (T5–T8) — escrituras de mantenciones (editar/subir/eliminar/restaurar) y de documentos de equipo (T2) scopeadas por `institutionId`; lecturas de la vista QR quedan públicas por diseño
- [x] **P1** Unificar tokens QR a `crypto` (quitar `Math.random()`)
- [x] **P2** Rate limit con store compartido + `trust proxy` — `KvStoreService` con Redis opcional (`REDIS_URL`) y fallback en memoria
- [x] **P2** Refresh/revocación de JWT — access corto (30m) + refresh (7d) con rotación e interceptor de `fetch` en el front; revocación en logout por `jti`

## Definición de "hecho"

Una tarea está completa cuando el PR está mergeado a `main`, la app levanta
correctamente (backend + front vía Docker), el flujo afectado se valida
manualmente y, en cambios de seguridad, queda verificado el aislamiento
multi-tenant (un usuario no accede a recursos de otra institución).
