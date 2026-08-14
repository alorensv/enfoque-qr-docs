---
name: pm-dashboard
description: >-
  Genera un dashboard de jefe de proyectos en HTML analizando la rama main del
  repositorio y un documento de objetivo. Produce dashboard.html con el estilo
  visual de ReservaHotel mostrando tareas en progreso y completadas (Kanban),
  equipo, portafolio, integración con GitHub, agentes IA y agentes QA. Úsalo
  cuando el usuario pida "generar dashboard PM", analizar el estado del proyecto,
  un panel de seguimiento, o invoque /pm-dashboard.
allowed-tools: Read, Grep, Glob, Bash, Write
---

# /pm-dashboard — Generador de dashboard de jefe de proyectos

Tu tarea es analizar este repositorio y producir un archivo `dashboard.html`
autocontenido, con la presentación visual de la plantilla incluida, poblado con
datos reales extraídos del proyecto.

El argumento opcional `$ARGUMENTS` es la ruta a un documento de objetivo
(por ejemplo `goals.md`). Si no se entrega, busca `goals.md`, `OBJETIVO.md`,
`GOALS.md` o el README en la raíz.

## Paso 1 — Leer el objetivo

Lee el documento de objetivo (o el README como respaldo). De ahí obtienes:
metas/fases del proyecto, alcance, y el foco actual. Si no hay ninguno, continúa
solo con el análisis del código y déjalo anotado en el resumen final.

## Paso 2 — Analizar la rama main

Confirma la rama (`git rev-parse --abbrev-ref HEAD`) y reúne contexto:

- **Estructura y stack**: usa Glob/Grep sobre manifests (`package.json`,
  `requirements.txt`, `pyproject.toml`, `go.mod`, `Cargo.toml`, etc.), config de
  framework, y la estructura de carpetas. Identifica lenguaje, framework, y si es
  monorepo (varios paquetes/apps = varios "proyectos" en el portafolio).
- **Rutas / API y modelo de datos**: localiza rutas (carpetas `routes/`, `api/`,
  `pages/`, controladores) y esquema de datos (migraciones, `schema.prisma`,
  archivos `.sql`, modelos ORM). Sirve para los módulos del portafolio.
- **Historial**: `git log --oneline -20` y, si está, milestones del proyecto.

## Paso 3 — Datos de GitHub (si `gh` está disponible)

Comprueba `gh auth status`. Si está autenticado, usa el CLI; si no, sáltalo sin
fallar y marca esas secciones como placeholder.

- Issues: `gh issue list --state all --limit 200 --json number,title,state,labels,assignees,milestone`
- PRs: `gh pr list --state all --limit 100 --json number,title,state,author`
- Repo: `gh repo view --json name,defaultBranchRef`

## Paso 4 — Derivar las vistas

- **Kanban** (sección Tablero): una tarjeta por issue/PR.
  - `Backlog` = issues abiertos sin asignar o sin etiqueta de progreso.
  - `En progreso` = issues abiertos asignados o con label `in progress`/`wip`.
  - `En revisión` = Pull Requests abiertos.
  - `Completado` = issues cerrados + PRs mergeados (muestra los más recientes).
  - Cada tarjeta lleva `proj-tag` (color por proyecto) y las iniciales del responsable.
- **Equipo**: una tarjeta por persona asignada/contribuidora. La "carga" es el
  porcentaje de tareas activas de esa persona sobre el total activo del equipo.
- **Portafolio**: una `module-card` por proyecto (o por área en monorepo), con
  barra de avance y un puñado de módulos/fases.
- **Foco del sprint**: 1–2 frases sintetizadas del objetivo + los issues abiertos
  de mayor prioridad. Lista 2–3 próximos pasos concretos.
- **GitHub / Agentes IA / Agentes QA**: rellena GitHub con métricas reales del
  repo (issues/PRs/branch protection) si tienes `gh`. Las secciones de Agentes IA
  y QA son **andamiaje** (requieren backend para funcionar de verdad): déjalas con
  el contenido de ejemplo de la plantilla, o vacíalas, pero no inventes keys.

## Paso 5 — Regla de honestidad sobre el % de avance

**No adivines el porcentaje de avance a partir del código.** Calcúlalo solo desde
señales verificables: issues cerrados vs. totales, milestones, o el checklist del
documento de objetivo. Si para algún número no tienes fuente, usa un valor neutro
y márcalo con "(estimado)" o un guion, en lugar de un porcentaje falso con aire
de certeza.

## Paso 6 — Generar el HTML

1. Lee la plantilla `template.html` que está **en este mismo directorio de skill**
   (junto a este `SKILL.md`).
2. Reemplaza el contenido marcado con comentarios `<!-- PM:... -->` y los datos de
   ejemplo por los datos reales. **No toques los bloques `<style>`**: la
   presentación (estilo ReservaHotel) debe quedar idéntica.
3. Mantén exactamente las mismas clases CSS (`kpi-card`, `kan-card`, `badge`,
   `module-card`, `proj-tag`, `avatar`, etc.). Para colorear proyectos y avatares
   reutiliza las variables existentes (`--gold-dark`, `--info`, `--success`,
   `--warning`, `--error`).
4. Escribe el resultado en `dashboard.html` en la raíz del repo (o en la ruta que
   indique el usuario).

## Paso 7 — Reportar

Imprime un resumen corto: qué se pobló con datos reales, qué quedó como
placeholder por falta de backend o de `gh`, y cómo abrir el archivo
(`open dashboard.html` / publicarlo en GitHub Pages).

## Notas

- El archivo debe quedar **autocontenido** (todo el CSS embebido; solo carga las
  fuentes de Google Fonts por CDN). Así se abre en cualquier navegador o se sube
  tal cual a GitHub Pages.
- No incluyas secretos ni API keys en el HTML bajo ninguna circunstancia.
