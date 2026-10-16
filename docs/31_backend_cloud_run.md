# 31 · Backend en Cloud Run (migración 16-oct-2026)

## Por qué

MariaDB (VM `enfoque-qr-db`, GCP) tenía el puerto 3306 abierto a
`0.0.0.0/0` porque el backend corría en Vercel serverless, sin IPs de
salida fijas en el plan gratuito — no había forma de restringir el
firewall a "el backend" sin abrirlo a todo internet. Confirmado con
`fail2ban`: 49 bans por fuerza bruta en ~4 semanas, ataque activo y diario,
no un incidente aislado.

## Qué cambió

- **Backend**: Vercel serverless → **Cloud Run** (`enfoqueqr-api`,
  `southamerica-east1`, misma región que la BD).
- **Conexión a la BD**: por **IP interna** (`10.158.0.2`) vía Direct VPC
  Egress (`--network=default --subnet=default
  --vpc-egress=private-ranges-only`) — sin VPC Connector, sin costo fijo
  adicional. Mismo patrón que ya usan `accessport-api`/`miportal-api`/
  `clima-backend` en la misma cuenta GCP.
- **Firewall de MariaDB**: `allow-mysql` (`0.0.0.0/0:3306`) **borrada**.
  Regla nueva `allow-mysql-serverless`, acotada a `10.158.0.16/28` (el
  rango reservado por GCP para Direct VPC Egress).
- **Sin dominio propio**: `api.enfoqueqr.cl` **no existe más** como
  registro DNS. El front llama directo a la URL de Cloud Run
  (`NEXT_PUBLIC_API_URL`).
- **Cookie de sesión**: sacado el `domain: '.enfoqueqr.cl'` hardcodeado en
  `auth.controller.ts` → queda *host-only* (alcance más chico, más
  seguro). Es lo que permite servir desde la URL de Cloud Run sin romper
  el login — un host no puede setear `domain` para un dominio que no es
  él mismo ni un padre suyo, el navegador rechaza esa cookie en silencio.
- **Secretos**: Secret Manager, namespace `enfoqueqr-*`
  (`enfoqueqr-JWT_SECRET`, `enfoqueqr-DB_PASS`, `enfoqueqr-DB_CA_CERT`,
  `enfoqueqr-AWS_ACCESS_KEY_ID`, `enfoqueqr-AWS_SECRET_ACCESS_KEY`,
  `enfoqueqr-RESEND_API_KEY`), leídos por la service account
  `enfoqueqr-api@produccion-ldc.iam.gserviceaccount.com`
  (`roles/secretmanager.secretAccessor`, scopeado a esos secretos).
  `JWT_SECRET` y `DB_PASS` son valores **nuevos**, generados en la
  migración (no reusan los que tenía Vercel) — el resto de config plana
  (`DB_HOST`, `DB_PORT`, `CORS_ORIGINS`, etc.) va como env var normal, no
  como secreto.
- **Vercel** (`enfoque-qr-back`): proyecto **pausado**, no borrado — queda
  como rollback de emergencia. El front (`enfoque-qr-front`) sigue en
  Vercel sin cambios.

## Decisiones descartadas (y por qué)

- **Cloud Run Domain Mapping nativo**: no disponible en
  `southamerica-east1` (`Creating domain mappings is not allowed in
  southamerica-east1` — limitación de la plataforma, no de configuración).
- **Load Balancer HTTPS dedicado** (para tener `api.enfoqueqr.cl` propio):
  soportado, pero cuesta un piso fijo de ~US$18-20/mes (el forwarding
  rule global). Sin clientes recurrentes todavía, no se justifica — se
  puede reconsiderar más adelante.
- **CNAME directo a la URL de Cloud Run vía Cloudflare**: probado y
  **no funciona** — el edge de Cloud Run (GFE) enruta por Host/SNI y no
  reconoce un dominio custom sin Domain Mapping; da un 404 genérico de
  Google, no nuestra API.
- **Migrar también el front a GCP**: evaluado y descartado — el front no
  habla con la BD directo (solo HTTPS normal al backend), no es parte del
  problema de seguridad, y perdería el preview-deploy automático por PR
  que ya usa en Vercel.

## Deploy

No hay CI/CD automático para el backend todavía. Después de mergear a
`main`:

```bash
backend/scripts/deploy-cloud-run.sh
```

Valida que estés en `main` limpio y al día con `origin/main` antes de
buildear (evita construir una imagen desde una rama con código que nunca
llegó a `main` — pasó una vez en esta migración). Build con
`Dockerfile.prod` (multi-stage, sin pnpm ni devDependencies en la imagen
final, usuario no-root), push a Artifact Registry
(`southamerica-east1-docker.pkg.dev/produccion-ldc/apps/enfoqueqr-api`),
`gcloud run deploy`, y termina con un smoke test real (login con
credenciales falsas → debe dar 401/400, nunca 5xx).

## Nota sobre la URL del servicio

Cloud Run tiene **dos formatos de URL activos simultáneamente** para el
mismo servicio: la basada en el número de proyecto
(`enfoqueqr-api-891931110685.southamerica-east1.run.app`, la que usa hoy
`NEXT_PUBLIC_API_URL`) y una más corta basada en hash
(`enfoqueqr-api-<hash>-<region-code>.a.run.app`, la que devuelve por
defecto `gcloud run services describe ... status.url` desde esta
migración). Ambas resuelven al mismo servicio — no es necesario migrar de
una a la otra.

## Riesgo residual / pendiente

- Sin dominio propio para la API: aceptado (ver "decisiones descartadas").
  La URL ya era pública de todas formas (va en el JS del front); la
  protección real es `CORS_ORIGINS` + JWT + CSRF guard, no el nombre del
  host.
- `min-instances=0`: la primera request tras un período sin tráfico puede
  tener cold start. No evaluado el impacto real en UX todavía.
- Sin CI/CD automático: el deploy es manual (`deploy-cloud-run.sh`). Si
  se vuelve un problema de disciplina, considerar GitHub Actions con una
  service account dedicada (patrón ya usado por `accessport-api`/
  `miportal-api` en la misma cuenta).
