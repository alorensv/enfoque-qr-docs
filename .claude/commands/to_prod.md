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
- **Vercel**: proyecto `enfoque-qr-back` (API serverless, dominio
  `api.enfoqueqr.cl`) y proyecto `enfoque-qr-front` (dominios
  `www.enfoqueqr.cl` y `www.equipos-lortech.cl`). Deploy por integración
  GitHub→Vercel: mergear a `main` dispara el build solo, sin workflow propio.
- **BD**: MariaDB en la VM GCP `enfoque-qr-db` (proyecto `produccion-ldc`,
  zona `southamerica-east1-c`, IP pública `34.151.247.114:3306`, db
  `enfoqueqr`). **No es Cloud SQL** — se administra por SSH. `synchronize`
  está en `false` (TypeORM): **ninguna migración corre sola**, se aplican a
  mano y en orden (`docs/sql/NN_*_migration.sql`).
- **CI**: `audit.yml` (ambos repos, `pnpm audit --audit-level=high`) y
  `e2e.yml` (solo backend, aislamiento multi-tenant + lo que se vaya sumando)
  — ambos disparan con `push`/`pull_request` a `main`. Empujar una rama sola
  no corre nada: hace falta abrir el PR.
- **El backend no tiene Preview real**: las env vars de Preview en Vercel no
  traen `DB_HOST`/`DB_PASS` (solo Production), así que un preview del backend
  no conecta a BD. El gate pre-merge del backend es el **CI en verde**, no una
  URL de preview viva. El front sí tiene preview funcional (no habla directo a
  la BD).
- **Gotcha de alias de Vercel**: tras cualquier `vercel rollback`, el dominio
  custom (`api.enfoqueqr.cl`, `www.enfoqueqr.cl`) queda *pinneado* a esa
  build. Un deploy posterior no mueve el alias solo — hay que correr
  `vercel alias set <deployment-url> <dominio>` y confirmarlo con
  `vercel inspect <dominio>` **y** un curl real. Ya pasó una vez en este
  proyecto; revisalo aunque no hayas hecho rollback vos.

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

Levantá un MariaDB **de la misma versión que la VM** (`11.x` — confirmar con
`sudo mariadb --version` por SSH si hay dudas), restaurá el backup del paso 3
y aplicá ahí la migración nueva:

```bash
docker run -d --name mariadb-dryrun -e MARIADB_ROOT_PASSWORD=root \
  -e MARIADB_DATABASE=enfoqueqr -p 13399:3306 mariadb:11
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
ellos; la raíz cuando quieras). El merge a `main` dispara el deploy solo vía
la integración GitHub→Vercel — no hace falta `vercel --prod` salvo que hayas
cambiado env vars sin cambiar código (ahí sí hace falta un redeploy manual
para que las levante).

Después del deploy, **antes de dar por hecho que quedó bien**:

```bash
vercel ls --scope <tu-team> | head -5          # último deployment de cada proyecto
vercel inspect api.enfoqueqr.cl                # a qué deployment apunta el alias
vercel inspect www.enfoqueqr.cl
```

Si el alias no apunta al deployment recién construido (el gotcha del
contexto), `vercel alias set <deployment-url> <dominio>` y confirmá de nuevo.

## 9. Verificación contra producción real

No alcanza con que el PR esté verde ni con que Vercel diga "Ready". Con curl,
contra los dominios reales:

```bash
# La API responde y el schema nuevo está en uso (ejemplo: login + logout)
curl -si -X POST https://api.enfoqueqr.cl/auth/login \
  -H 'Content-Type: application/json' -H 'Origin: https://www.enfoqueqr.cl' \
  -d '{"email":"...","password":"..."}' | head -20

# Cabeceras de cookie sin cambios inesperados (Domain/Secure/SameSite/Max-Age)
curl -si -X POST https://api.enfoqueqr.cl/auth/logout \
  -H 'Origin: https://www.enfoqueqr.cl' | grep -i set-cookie

# CORS de la otra marca sigue vivo
curl -si -X POST https://api.enfoqueqr.cl/auth/logout \
  -H 'Origin: https://www.equipos-lortech.cl' | grep -i access-control-allow-origin

# Front sirve las páginas nuevas
curl -so /dev/null -w '%{http_code}\n' https://www.enfoqueqr.cl/
```

Si el cambio tocó la capa de datos, además: contá filas en la tabla afectada
en prod, y si aplica el patrón de A02, mirá `Ssl_accepts`/`Connections` en
MariaDB para confirmar que el tráfico real está pasando por donde se espera —
no te quedes con la palabra del deploy.

## 10. Cierre

Resumí: qué se commiteó en cada uno de los 3 repos, si hubo migración y con
qué resultado, los 2-3 PRs mergeados (con link), el estado del alias de
Vercel en ambos dominios, y las verificaciones de curl que corriste con su
resultado real (no "debería andar"). Mencioná explícitamente cualquier paso
que hayas salteado o que haya quedado a medias — en particular si el ensayo
del paso 4 no se pudo hacer contra la versión exacta de MariaDB de la VM.
