# 29 — Política de parcheo (PAT-02)

## 1️⃣ Objetivo

Definir, por escrito, en cuánto tiempo se aplica un parche de seguridad
según su severidad — el hallazgo PAT-02 de la auditoría de ciberseguridad
no era que faltara el mecanismo (ver más abajo, ya corre solo), sino que
no había un SLA documentado al que responsabilizar ese mecanismo.

## 2️⃣ SLA por severidad

| Severidad | Plazo máximo | Ejemplos |
|---|---|---|
| **Crítico** | ≤ 72 horas | RCE no autenticado, bypass de autenticación, fuga masiva de datos |
| **Alto** | ≤ 7 días | Escalación de privilegios, DoS explotable remotamente, RCE autenticado |
| **Medio** | ≤ 30 días | XSS reflejado, fugas de información acotadas, DoS con requisitos altos |
| **Bajo** | ≤ 90 días | Hallazgos informativos, mejoras de configuración sin explotación conocida |

El plazo cuenta desde que el parche está **disponible** (CVE publicado con
fix, o versión nueva liberada), no desde que se detecta — el detector
(`pnpm audit`/Semgrep en CI) corre en cada PR y en cada push a `main`, así
que en la práctica la detección es casi inmediata.

## 3️⃣ Alcance — dos capas, dos mecanismos distintos

### a) Sistema operativo de la VM (`enfoque-qr-db`)

**Ya automatizado, no requiere acción manual para el caso normal.**
`unattended-upgrades` está instalado, habilitado y configurado
(verificado 11-sep-2026: `systemctl is-enabled` → `enabled`,
`APT::Periodic::Unattended-Upgrade "1"` en
`/etc/apt/apt.conf.d/20auto-upgrades`) — aplica parches de seguridad de
Debian solo, sin intervención.

**Lo que el SLA de arriba cubre acá**: un parche Crítico/Alto que por
algún motivo no llegue solo (paquete fuera del canal `-security`, o que
requiera reinicio de un servicio que `unattended-upgrades` no reinicia
por defecto) — verificar y aplicar a mano dentro del plazo.

Verificación manual cuando haga falta:

```bash
gcloud compute ssh enfoque-qr-db --zone=southamerica-east1-c --project=produccion-ldc \
  --command="sudo apt list --upgradable 2>/dev/null"
```

### b) Dependencias de la aplicación (backend y front)

**Gate automático en CI**, no un cron: `pnpm audit --audit-level=high` en
GitHub Actions (`audit.yml`, ambos repos) corre en cada `push`/`pull_request`
a `main` — bloquea el merge si aparece algo HIGH o CRITICAL. No hay una
revisión periódica aparte: el gate es la revisión, y corre en cada cambio.

**Cómo se aplica el SLA acá en la práctica**: cuando el gate bloquea un PR
por una CVE nueva (no introducida por ese PR — ya pasó 3 veces:
`fast-uri`, luego `multer`/`js-yaml` en el backend, `next`/`sharp` en el
front), se resuelve en una rama aparte dedicada solo a ese pin, se mergea
esa primero, y recién después se rebasea el/los PR(s) bloqueados. Un
CRITICAL real (como el RCE de `next` del 11-sep-2026) se trata con el
plazo de 72h de la tabla de arriba, no se deja esperando al próximo PR que
lo encuentre por casualidad.

## 4️⃣ Lo que este documento NO cubre

- **MariaDB en sí** (el motor de BD, no el SO): actualizarlo es un cambio
  más delicado (requiere ventana de mantenimiento, backup previo, ensayo
  — ver el runbook de `/to_prod`), fuera del alcance de "parcheo
  automático". Se trata caso a caso, no por SLA fijo.
- **Imagen Docker de desarrollo** (`docker/docker-compose.yml`): no es
  producción, no tiene el mismo apuro — se actualiza al ritmo normal de
  mantenimiento del proyecto.

## 5️⃣ Responsable

Mientras el proyecto tenga un solo desarrollador, la responsabilidad de
aplicar el parche dentro del plazo recae en esa misma persona — este
documento existe para que el plazo quede escrito y no dependa de la
memoria de nadie, no para asignarlo a un tercero que hoy no existe.
