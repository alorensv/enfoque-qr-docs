---
description: Pipeline de paso a producción de Enfoque QR — commits, migración SQL, PRs, CI, deploy y verificación real
---

Llevá a producción todo lo que esté pendiente, en este orden. **No saltes
pasos ni los reordenes**: cada uno protege al siguiente. Seguí también
[[enfoqueqr-workflow]] y [[enfoqueqr-project-status]] si están en memoria —
tienen el runbook y los pendientes vivos del proyecto.

Contexto fijo del proyecto:

- **Meta-repo, 3 git independientes** (no submodules): esta raíz
  (`enfoque-qr-docs` → GitHub `alorensv/enfoque-qr-docs`, sin CI/deploy, solo
  documentación + `docs/sql/*_migration.sql`), `backend/` (→ GitHub
  `alorensv/enfoque-qr-back`) y `front/` (→ GitHub `alorensv/enfoque-qr-front`).
  `git status` en la raíz **no** refleja cambios de `backend/`/`front/`.
- **Backend en Cloud Run desde el 16-oct-2026** (ver
  `docs/31_backend_cloud_run.md`), **ya no en Vercel** — el proyecto Vercel
  `enfoque-qr-back` está pausado, se mantiene solo como rollback de
  emergencia. Sin dominio propio: el front le pega directo a la URL de
  Cloud Run (`enfoqueqr-api-891931110685.southamerica-east1.run.app`) —
  `api.enfoqueqr.cl` ya no existe como registro DNS, no lo busques. **No hay
  deploy automático**: después de mergear un PR del backend, correr
  `backend/scripts/deploy-cloud-run.sh` a mano (valida que estés en `main`
  limpio y al día antes de buildear, y termina con un smoke test real).
- **Front sigue en Vercel** (proyecto `enfoque-qr-front`, dominios
  `www.enfoqueqr.cl` y `www.equipos-lortech.cl`). Deploy por integración
  GitHub→Vercel: mergear a `main` dispara el build solo, sin workflow propio.
- **BD**: MariaDB en la VM GCP `enfoque-qr-db` (proyecto `produccion-ldc`,
  zona `southamerica-east1-c`, IP interna `10.158.0.2`, db `enfoqueqr`).
  **No es Cloud SQL** — se administra por SSH. El puerto 3306 está cerrado al
  público desde el 16-oct-2026 (antes abierto a `0.0.0.0/0`, atacado a
  diario) — solo accesible desde el rango interno de Cloud Run
  (`10.158.0.16/28`, regla `allow-mysql-serverless`) o por SSH a la VM.
  `synchronize` está en `false` (TypeORM): **ninguna migración corre sola**,
  se aplican a mano y en orden (`docs/sql/NN_*_migration.sql`).
- **MariaDB 10.11.19**, no "11.x" como decía antes esta sección — confirmado
  con `sudo mariadb --version` el 16-oct-2026. Para el ensayo del paso 4,
  usar la imagen Docker `mariadb:10.11`, no `mariadb:11`.
- **CI**: `audit.yml` (ambos repos, `pnpm audit --prod --audit-level=high` —
  acotado a dependencias de runtime desde el 16-oct-2026, antes bloqueaba
  por CVEs de devDependencies a veces sin parche publicado) y `e2e.yml`
  (solo backend, aislamiento multi-tenant + lo que se vaya sumando) — ambos
  disparan con `push`/`pull_request` a `main`. Empujar una rama sola no
  corre nada: hace falta abrir el PR.
- **El backend no tiene Preview con BD real** (Cloud Run no tiene un
  equivalente a los preview deploys de Vercel configurado todavía) — el
  gate pre-merge del backend es el **CI en verde**, no una URL de preview
  viva. El front sí tiene preview funcional en Vercel (no habla directo a
  la BD).
- **Gotcha de alias de Vercel (solo front)**: tras cualquier
  `vercel rollback`, el dominio custom (`www.enfoqueqr.cl`) queda *pinneado*
  a esa build. Un deploy posterior no mueve el alias solo — hay que correr
  `vercel alias set <deployment-url> <dominio>` y confirmarlo con
  `vercel inspect <dominio>` **y** un curl real. Ya pasó una vez en este
  proyecto; revisalo aunque no hayas hecho rollback vos. Ya no aplica al
  backend (sin dominio propio en Cloud Run).

---

## 1. Revisar qué se va

Corré `git status` y `git log --oneline origin/main..HEAD` en **los tres**
árboles (raíz, `backend/`, `front/`) — cada uno por separado, la raíz no ve a
los otros dos. Para cada uno: rama actual, qué hay sin commitear, qué commits
locales no están en `origin/main`, y si hay migraciones SQL nuevas en
`docs/sql/` sin aplicar en producción.

Si algún árbol está limpio y ya está al día con `main`, decilo y no lo toques.

**Verificá que no se cuele nada que no deba versionarse**: `.env`,
`DB_CA_CERT`/certificados, dumps (`docs/dump_*.sql`, `docs/bd*.sql` son
snapshots de referencia ya trackeados — no confundir con un dump nuevo hecho
sin querer), `docs/vistas/` si trae capturas con datos reales.

## 2. Commits

Agrupá por tema y por repo — un commit no cruza `backend/`↔`front/`↔raíz. Si
el cambio toca schema, **la migración SQL tiene que ir commiteada en la raíz**
(`docs/sql/NN_descripcion_migration.sql`) en el mismo lote lógico que el
código del backend que la necesita, aunque sean repos distintos: si el código
llega a prod antes que la migración se aplique, revienta contra columnas o
tablas que no existen.

## 3. Backup de la BD de producción

Ya existe un cron diario de `mysqldump` → `gs://enfoqueqr-db-backups-…`
(bucket real, resolver el sufijo con `gcloud storage buckets list
--project=produccion-ldc`) con lifecycle de 30 días. **No asumas que está al
día** si vas a correr DDL: confirmá la fecha del último backup antes de
seguir.

```bash
gcloud storage ls gs://enfoqueqr-db-backups-*/ --project=produccion-ldc | tail -5
```

Si el más reciente es de hace más de un día, o si el cambio es sensible,
generá uno al toque por SSH antes de tocar el schema:

```bash
gcloud compute ssh enfoque-qr-db --zone=southamerica-east1-c --project=produccion-ldc \
  --command="sudo mysqldump -u root --single-transaction --routines --triggers enfoqueqr | gzip > /tmp/enfoqueqr-pre-migracion-\$(date +%Y%m%d-%H%M%S).sql.gz"
```

Traelo a local antes de seguir (lo necesitás para el ensayo del paso 4):

```bash
gcloud compute scp enfoque-qr-db:/tmp/enfoqueqr-pre-migracion-*.sql.gz . \
  --zone=southamerica-east1-c --project=produccion-ldc
```

## 4. Ensayo de la migración sobre una copia real de producción

**No lo saltees aunque el SQL "se vea simple".** Esta sesión ya encontró dos
diferencias reales entre motores al hacer justo esto: `ON DUPLICATE KEY
UPDATE` con `VALUES()` está deprecado en MySQL 8 (lo que corre en dev/CI) y el
alias `AS new` directamente **no existe** en MariaDB (lo que corre en prod) —
y la colación `utf8mb4_0900_ai_ci` de MySQL 8 tampoco existe en MariaDB. Un
ensayo contra el MySQL 8 de `docker/docker-compose.yml` no habría detectado
ninguna de las dos.

Levantá un MariaDB **de la misma versión que la VM** (`10.11.x` — confirmar
con `sudo mariadb --version` por SSH si hay dudas), restaurá el backup del
paso 3 y aplicá ahí la migración nueva:

```bash
docker run -d --name mariadb-dryrun -e MARIADB_ROOT_PASSWORD=root \
  -e MARIADB_DATABASE=enfoqueqr -p 13399:3306 mariadb:10.11
# esperar a que levante (mariadb -uroot -proot -e "SELECT 1")
gunzip -c enfoqueqr-pre-migracion-*.sql.gz | \
  docker exec -i mariadb-dryrun mariadb -uroot -proot enfoqueqr
docker exec -i mariadb-dryrun mariadb -uroot -proot enfoqueqr < docs/sql/NN_descripcion_migration.sql
```

Confirmá con `DESCRIBE`/`SHOW CREATE TABLE` que el schema quedó como se
espera, no solo que el comando "no tiró error". Si la migración escribe datos
(backfill), revisá filas afectadas.

Si falla, arreglá el SQL y **repetí el ensayo desde el backup limpio** (no
sobre la copia ya mutada). Al terminar, `docker rm -f mariadb-dryrun`.

## 5. Push a las ramas + Pull Requests

Por cada repo con cambios (`backend/`, `front/`, y la raíz si corresponde):

```bash
git push -u origin <rama>
gh pr create --repo alorensv/enfoque-qr-back  --base main --head <rama> --title "..." --body "..."
gh pr create --repo alorensv/enfoque-qr-front --base main --head <rama> --title "..." --body "..."
gh pr create --repo alorensv/enfoque-qr-docs  --base main --head <rama> --title "..." --body "..."
```

La raíz (docs) no tiene CI ni gate — el PR ahí es solo trazabilidad, se puede
mergear apenas esté creado. Backend y front sí necesitan lo que sigue.

## 6. Esperar CI en verde — es el gate real, no un preview

```bash
gh pr checks --repo alorensv/enfoque-qr-back  <pr-number> --watch
gh pr checks --repo alorensv/enfoque-qr-front <pr-number> --watch
```

Como el backend no tiene preview con BD real, **el CI (`audit.yml` +
`e2e.yml`) es la única verificación automática pre-merge que existe** —
tratalo como si fuera el ensayo en preview que no se puede hacer. Si algo
falla, leé el log antes de asumir que es infra del runner.

## 7. Aplicar la migración en producción

**Antes de mergear** el código del backend que la necesita — si el deploy
sale primero, las requests a las rutas nuevas van a fallar contra columnas
que todavía no existen.

```bash
gcloud compute ssh enfoque-qr-db --zone=southamerica-east1-c --project=produccion-ldc \
  --command="sudo mysql -u root enfoqueqr" < docs/sql/NN_descripcion_migration.sql
```

Confirmá en la BD real (no en el dry-run) que el schema cambió:

```bash
gcloud compute ssh enfoque-qr-db --zone=southamerica-east1-c --project=produccion-ldc \
  --command="sudo mysql -u root enfoqueqr -e 'DESCRIBE <tabla_nueva_o_modificada>;'"
```

## 8. Merge y deploy

Mergeá los PRs (backend y front primero si hay orden de dependencia entre
ellos; la raíz cuando quieras). **Los dos repos ya no se despliegan igual:**

- **Front**: el merge a `main` dispara el deploy solo vía la integración
  GitHub→Vercel — no hace falta `vercel --prod` salvo que hayas cambiado
  env vars sin cambiar código (ahí sí hace falta un redeploy manual para
  que las levante).
- **Backend**: **no hay deploy automático.** Después de mergear, parado en
  `backend/` sobre `main` ya actualizado (`git pull origin main`), correr:

  ```bash
  backend/scripts/deploy-cloud-run.sh
  ```

  El script valida que estés en `main` limpio y al día antes de buildear
  (evita repetir el incidente del 16-oct: una imagen se construyó desde una
  rama con código que nunca llegó a `main`), hace build + push a Artifact
  Registry + `gcloud run deploy`, y termina con un smoke test real (login
  con credenciales falsas, debe dar 401/400, nunca 5xx). Si el smoke test
  falla, el script corta solo y no da el deploy por bueno.

Después del deploy del **front**, confirmá el alias (gotcha de Vercel, ver
contexto arriba):

```bash
vercel ls --scope <tu-team> | head -5          # último deployment
vercel inspect www.enfoqueqr.cl                # a qué deployment apunta el alias
```

Si el alias no apunta al deployment recién construido, `vercel alias set
<deployment-url> <dominio>` y confirmá de nuevo. El backend no tiene este
problema — no hay dominio propio que pueda quedar pinneado.

## 9. Verificación contra producción real

No alcanza con que el PR esté verde, con que Vercel diga "Ready", o con el
smoke test del script de deploy (ese solo confirma que la API arrancó y
conecta a la BD — no reemplaza probar lo que de verdad cambió). Con curl,
contra lo real:

```bash
# URL real del servicio de Cloud Run — no asumas que es siempre la misma
API_URL=$(gcloud run services describe enfoqueqr-api --project=produccion-ldc \
  --region=southamerica-east1 --format='value(status.url)')

# La API responde y el schema nuevo está en uso (ejemplo: login + logout)
curl -si -X POST "$API_URL/auth/login" \
  -H 'Content-Type: application/json' -H 'Origin: https://www.enfoqueqr.cl' \
  -d '{"email":"...","password":"..."}' | head -20

# Cabeceras de cookie sin cambios inesperados (host-only desde el 16-oct —
# sin Domain explícito — Secure/SameSite/Max-Age sí deberían seguir igual)
curl -si -X POST "$API_URL/auth/logout" \
  -H 'Origin: https://www.enfoqueqr.cl' | grep -i set-cookie

# CORS de la otra marca sigue vivo
curl -si -X POST "$API_URL/auth/logout" \
  -H 'Origin: https://www.equipos-lortech.cl' | grep -i access-control-allow-origin

# Front sirve las páginas nuevas (y tiene embebida la URL de Cloud Run
# correcta — NEXT_PUBLIC_API_URL se hornea en build time, no en runtime)
curl -so /dev/null -w '%{http_code}\n' https://www.enfoqueqr.cl/
```

Si el cambio tocó la capa de datos, además: contá filas en la tabla afectada
en prod, y si aplica el patrón de A02, mirá `Ssl_accepts`/`Connections` en
MariaDB para confirmar que el tráfico real está pasando por donde se espera —
no te quedes con la palabra del deploy.

## 10. Cierre

Resumí: qué se commiteó en cada uno de los 3 repos, si hubo migración y con
qué resultado, los 2-3 PRs mergeados (con link), el estado del alias de
Vercel en `www.enfoqueqr.cl` (front) y la revisión activa en Cloud Run
(backend, `gcloud run services describe enfoqueqr-api ...
latestReadyRevisionName`), y las verificaciones de curl que corriste con su
resultado real (no "debería andar"). Mencioná explícitamente cualquier paso
que hayas salteado o que haya quedado a medias — en particular si el ensayo
del paso 4 no se pudo hacer contra la versión exacta de MariaDB de la VM.
