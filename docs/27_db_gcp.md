# 27 · Migración de la base de datos a GCP

> Migración de MySQL desde hosting compartido (BenzaHosting) a una VM propia en
> Google Cloud, para resolver la lentitud/intermitencia de producción.
> Fecha: 2026-06-19.

---

## 1. Problema

La plataforma en producción (front en Vercel, backend NestJS serverless en Vercel)
cargaba lento y a veces **no cargaba**. El login fallaba con "CORS error".

Diagnóstico real (no era CORS de fondo):

- El backend serverless conectaba a MySQL en **BenzaHosting** (`srv58.benzahosting.cl`).
- En **arranque en frío**, la primera conexión a esa DB **se colgaba ~115 s** →
  la función timeouteaba → Vercel devolvía **500 sin headers CORS** → el navegador
  lo mostraba como *"CORS error"* (síntoma, no causa).
- En caliente el login respondía en **0.8 s** (correcto). O sea: el cuello de
  botella era la **conexión a BenzaHosting** (hosting compartido: lento/inestable
  para conexiones remotas desde serverless, con IPs en lista blanca).

> Antes de migrar también se corrigió un bug de CORS: el callback lanzaba un
> `Error` ante orígenes no permitidos → 500 en el preflight. Ahora responde
> `callback(null, false)` (rechazo limpio). Los dominios de instituciones se
> autorizan con la env `CORS_ORIGINS` (ver §6). Ej.: `equipos-lortech.cl`.

---

## 2. Decisión

Mover la base de datos a infraestructura propia, **gastando el mínimo**:

- **GCP Compute Engine e2-micro** (free tier) con **MariaDB** autogestionada.
- Se descartó Cloud SQL (~US$10/mes) por costo; se descartó dejar BenzaHosting por
  fiabilidad.

**Costo real:** la VM e2-micro y el disco (30 GB estándar) son **free tier ($0)**,
pero GCP cobra la **IP pública IPv4** (~**US$3/mes**). Total ≈ **US$3/mes**.

---

## 3. Arquitectura resultante

```
Navegador (www.enfoqueqr.cl / www.equipos-lortech.cl)
   │  HTTPS
   ▼
Front Next.js  ─────────────►  Backend NestJS (Vercel serverless, api.enfoqueqr.cl)
 (Vercel)        fetch/cookie         │  TCP 3306 (público + auth)
                                      ▼
                          MariaDB 10.11 — GCP VM e2-micro
                          enfoque-qr-db · southamerica-east1 · 34.151.247.114
```

---

## 4. Recursos creados en GCP

| Recurso | Valor |
|---|---|
| Proyecto | `produccion-ldc` (display "Produccion") |
| Billing | vinculado a la cuenta de facturación existente |
| VM | `enfoque-qr-db` · `e2-micro` · zona `southamerica-east1-c` · Debian 12 |
| Disco | 30 GB `pd-standard` (free tier) |
| IP pública | `34.151.247.114` |
| Firewall | `allow-mysql` → `tcp:3306` desde `0.0.0.0/0`, target tag `mysql-server` |
| Motor DB | **MariaDB 10.11** (compatible MySQL, más liviano para 1 GB RAM) |
| Swap | 2 GB (`/swapfile`, en `/etc/fstab`) para evitar OOM |
| Tuning | `innodb_buffer_pool_size=128M`, `performance_schema=OFF`, `max_connections=60`, `bind-address=0.0.0.0` (en `/etc/mysql/mariadb.conf.d/99-enfoque.cnf`) |

### Datos de conexión
```
Host: 34.151.247.114   Puerto: 3306
DB:   enfoqueqr        Usuario: enfoque
Pass: (en Vercel env DB_PASS · NO se versiona en este repo)
```

---

## 5. Migración de datos

BenzaHosting bloquea por IP, así que el `mysqldump` remoto desde la VM falló
(`Can't connect ... (110)` timeout). Se resolvió con **export directo desde
phpMyAdmin** (`docs/dump_enfoque.sql`).

Ajuste de compatibilidad **MySQL 8 → MariaDB** antes de importar:

- La colación `utf8mb4_0900_ai_ci` (MySQL 8) **no existe en MariaDB** → se
  reemplazó por `utf8mb4_unicode_ci`.
- Se quitaron `CREATE DATABASE`/`USE lineasde_enfoqueqr` y cláusulas `DEFINER`
  para importar en la base `enfoqueqr`.

```bash
sed -E \
  -e 's/utf8mb4_0900_ai_ci/utf8mb4_unicode_ci/g' \
  -e 's/ DEFINER=`[^`]*`@`[^`]*`//g' \
  -e '/CREATE DATABASE.*lineasde_enfoqueqr/d' \
  -e '/^USE `lineasde_enfoqueqr`/d' \
  docs/dump_enfoque.sql > /tmp/dump_clean.sql
# scp a la VM e import:  sudo mysql -u root enfoqueqr < dump_clean.sql
```

**Resultado:** 16 tablas importadas (1 institución, 4 usuarios, 13 equipos, 6 clientes).

---

## 6. Cambios en Vercel (backend `enfoque-qr-back`)

Variables de **Production** actualizadas para apuntar a la VM:

```
DB_HOST = 34.151.247.114
DB_PORT = 3306
DB_USER = enfoque
DB_PASS = (secreto)
DB_NAME = enfoqueqr
CORS_ORIGINS = https://www.enfoqueqr.cl,https://www.equipos-lortech.cl  (dominios de instituciones)
```

Luego **redeploy a producción** (`vercel --prod`).

> Nota: Vercel **no usa** los `.env` del repo; las variables viven en el proyecto
> de Vercel. `.env.example` es solo documentación.

### Verificación
- `POST /auth/login` (cold) → **401 en 1.5 s** (antes 115 s) ✅
- CORS OK para `equipos-lortech.cl` y `enfoqueqr.cl` ✅

---

## 7. Operación (runbook)

```bash
# SSH a la VM
gcloud compute ssh enfoque-qr-db --zone=southamerica-east1-c --project=produccion-ldc

# Estado / reinicio de MariaDB
sudo systemctl status mariadb
sudo systemctl restart mariadb

# Consola SQL (en la VM, root por socket)
sudo mysql -u root enfoqueqr
```

---

## 8. Pendientes recomendados

- [ ] **Backups automáticos** (lo más importante): cron diario de `mysqldump`
      (a archivo local + idealmente a Google Cloud Storage con retención).
      La VM hoy **no tiene respaldo**.
- [ ] **Seguridad del puerto 3306**: hoy abierto a `0.0.0.0/0` con contraseña
      fuerte. Exigir **SSL/TLS** en las conexiones (o restringir por IP, difícil
      con Vercel serverless). Riesgo inmediato acotado por la contraseña robusta.
- [ ] **Decomisionar BenzaHosting**: mantener unos días como respaldo y, tras
      confirmar estabilidad en GCP, dar de baja.
- [ ] **Redis (Upstash) para serverless** (de [[26_claude_analisis]] §S-RL/S-REF):
      sin `REDIS_URL`, rate limit y revocación de JWT son por-instancia/efímeros.
- [ ] **Cold start**: opcional, no montar Swagger en prod + `TypeORM logging:false`
      (ya no es crítico: 1.5 s).
- [ ] **Variables DB en Preview/Development**: quedaron solo en Production; si se
      usan deploys de preview, re-agregarlas.
- [ ] **Monitoreo/uptime** de la VM (alertas si MariaDB cae o el disco se llena).
