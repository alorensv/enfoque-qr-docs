# Design System · Enfoque QR

> Sistema visual del **Panel Admin** de Enfoque QR. Lenguaje UI inspirado en la
> limpieza y el espaciado de plataformas SaaS B2B modernas (estilo "Clima
> Laboral"), pero con **identidad propia de Enfoque QR**: color primario
> **emerald/verde**, tipografía Inter y foco en trazabilidad + gestión.
>
> Esta guía es la referencia para futuras pantallas del panel. Los valores viven
> como **tokens** en `front/styles/globals.css` (variables CSS) y
> `front/tailwind.config.js` (extensión de Tailwind).

---

## 1. Brand

**Nombre:** Enfoque QR

**Personalidad:** tecnología, seguridad, confianza, gestión, trazabilidad,
modernidad, profesionalismo.

**Tono visual:** SaaS empresarial moderno. Limpio, claro, con aire. **Evitar** lo
excesivamente "cyber", oscuro o recargado. La profundidad se logra con
background + borde + espaciado + sombra muy sutil, no con efectos 3D,
neumorphism ni glassmorphism.

Prioridad de diseño: **claridad > jerarquía > consistencia > estética.**

---

## 2. Colores (tokens)

Color principal **emerald** (verde). Se usa para acciones principales, estados
activos, enlaces importantes, iconografía destacada e indicadores positivos.
**No** saturar toda la interfaz de verde: es un acento sobre un lienzo neutro.

```css
/* Primario */
--color-primary:        #059669;  /* emerald-600 · botones, activo, links */
--color-primary-hover:  #047857;  /* emerald-700 · hover/pressed */
--color-primary-strong: #065f46;  /* emerald-800 · texto sobre soft */
--color-primary-soft:   #ecfdf5;  /* emerald-50  · fondos suaves, chips */
--color-primary-soft2:  #d1fae5;  /* emerald-100 · bordes/hover suaves */

/* Estados */
--color-success:      #16a34a;   --color-success-soft: #dcfce7;
--color-warning:      #d97706;   --color-warning-soft: #fef3c7;
--color-danger:       #dc2626;   --color-danger-soft:  #fee2e2;
--color-info:         #2563eb;   --color-info-soft:    #dbeafe;
--color-neutral:      #64748b;   --color-neutral-soft: #f1f5f9;

/* Superficie / fondo */
--color-background:   #f8fafc;   /* lienzo (gris casi blanco) */
--color-surface:      #ffffff;   /* cards, sidebar, header */
--color-surface-soft: #f9fafb;   /* filas hover, inputs */
--color-border:       #e5e7eb;   /* borde estándar */
--color-border-soft:  #eef1f5;   /* borde muy sutil (cards) */

/* Texto */
--color-text-primary:   #0f172a; /* títulos, KPI */
--color-text-secondary: #475569; /* cuerpo */
--color-text-muted:     #94a3b8; /* captions, labels */
```

**Regla de accesibilidad:** ningún estado se comunica **solo** por color —
siempre acompañar con ícono, texto o forma (ej. badge con etiqueta, no solo un
punto de color).

---

## 3. Tipografía

Familia: **Inter** → `system-ui` → `sans-serif`.

| Rol      | Tamaño        | Peso | Uso |
|----------|---------------|------|-----|
| H1       | 1.75rem (28px)| 800  | Título de página / greeting |
| H2       | 1.25rem (20px)| 700  | Títulos de sección/card |
| H3       | 1rem (16px)   | 700  | Subtítulos, encabezados de bloque |
| KPI      | 1.875rem (30px)| 800 | Número grande de las tarjetas |
| Body     | 0.9375rem (15px)| 400| Texto general |
| Label    | 0.75rem (12px)| 600  | Etiquetas de card, uppercase + tracking |
| Caption  | 0.6875rem (11px)| 500| Notas secundarias |

Evitar tamaños excesivamente grandes: la interfaz prioriza lectura rápida de
información operativa.

---

## 4. Espaciado

Escala base (múltiplos de 4):

```
4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48
```

- Padding interno de cards: **24px** (lg) / **20px** (compactas).
- Gap entre KPI cards: **20–24px**.
- El layout mantiene bastante espacio negativo (aire). Nunca pegar elementos.

---

## 5. Border radius

```
sm: 8px    → inputs, badges, íconos pequeños
md: 12px   → botones, items de navegación, contenedores de ícono
lg: 16px   → cards principales
xl: 20px   → contenedores destacados / modales
full       → solo avatares y badges tipo pill
```

---

## 6. Sombras

Extremadamente suaves. La profundidad viene del borde + fondo, no de la sombra.

```css
--shadow-xs: 0 1px 2px rgba(15,23,42,.04);
--shadow-sm: 0 1px 3px rgba(15,23,42,.06), 0 1px 2px rgba(15,23,42,.04);
--shadow-md: 0 4px 12px rgba(15,23,42,.06);  /* hover de cards interactivas */
```

Prohibido: sombras oscuras, neumorphism, efectos 3D, glassmorphism marcado.

---

## 7. Layout

```
┌───────────────────────────────────────────────────────────┐
│ Sidebar │ Header (buscador · notif · usuario)             │
│ (blanco ├───────────────────────────────────────────────┤ │
│  full   │ Greeting + acción principal                    │ │
│  height)│ KPI · KPI · KPI · KPI                           │ │
│         │ Ranking / info        │ Resumen · Próx. pasos   │ │
└───────────────────────────────────────────────────────────┘
```

- **Sidebar** ocupa toda la altura a la izquierda (branding arriba, navegación
  al centro, configuración + usuario abajo).
- **Header** vive sobre el área de contenido (no sobre el sidebar).
- **Main** scrollea; ancho de contenido con `max-width` y centrado.

---

## 8. Componentes

### Sidebar
- Fondo **blanco**, borde derecho sutil, íconos lineales, mucho espacio vertical.
- Item activo: **fondo emerald muy suave**, texto emerald, ícono emerald, radio
  10–12px, barra/acento emerald a la izquierda.
- Hover: fondo gris muy claro. Texto gris oscuro en reposo.
- Colapsable (desktop) y off-canvas (mobile). Footer con **Configuración** y
  usuario actual.

### Header
- Blanco, minimalista. Hamburguesa (mobile) + buscador estilo Clima Laboral
  (fondo gris muy claro, borde sutil, ícono lupa, placeholder discreto) +
  notificaciones + avatar/menú.

### KPI Card
- Fondo blanco, borde sutil, radio 16px, ícono en contenedor suave (soft del
  color), número grande, label, dato secundario y progress cuando aplica.
- Sin gradients fuertes. Hover: sombra `md` + leve elevación del ícono.

### Cards de contenido (ranking, resumen, próximos pasos)
- Blancas, borde sutil, radio 16px. El "Resumen General" es **secundario**: no
  compite con los KPI (nada de fondo oscuro). "Próximos pasos" es
  **action-oriented** (emerald soft + links/acciones).

### Botón primario
- Fondo `--color-primary`, texto blanco, radio 10–12px, sombra `xs`.
- Estados: default / hover (`--color-primary-hover`) / active (translate 1px) /
  disabled (opacidad 0.5, sin puntero) / loading (spinner + texto).

---

## 9. Estados

| Componente | Estados |
|---|---|
| Button     | default · hover · active · disabled · loading |
| Card       | default · hover (si es interactiva) |
| Navigation | default · hover · active |
| KPI        | normal · positive · warning · critical · unavailable |
| Progress   | normal · success · warning · danger |

---

## 10. Iconografía

Una sola familia: **íconos lineales** (estilo Lucide/Heroicons), grosor moderado
(~1.8), `stroke="currentColor"`. Se implementan como **SVG inline** (sin agregar
dependencias). No mezclar estilos ni rellenos sólidos con lineales.

---

## 11. Responsive

| Breakpoint | Ancho | Comportamiento |
|---|---|---|
| Desktop | ≥1440px | Layout completo, KPI en 4 columnas |
| Laptop  | 1024–1439px | KPI 4 col, contenido 2/3 + 1/3 |
| Tablet  | 768–1023px | KPI 2 col, secciones apiladas, sidebar off-canvas |
| Mobile  | <768px | KPI 1 col, sidebar → navegación móvil, header simplificado, padding reducido |

No es un "shrink" del desktop: el sidebar se vuelve off-canvas con overlay,
las grillas se reorganizan y los targets táctiles se mantienen (≥40px).

---

## 12. Accesibilidad

- Contraste adecuado (texto sobre fondos claros; emerald-700+ para texto verde).
- **Focus states** visibles (anillo emerald suave) y navegación por teclado.
- Botones semánticos (`<button>`/`<a>`), `aria-label` en íconos de acción.
- Targets táctiles ≥40px. Estados nunca dependen solo del color.

---

## 13. Microinteracciones

Sutiles: hover, transición de color en botones/nav, animación de progress,
apertura/cierre del sidebar. Duraciones ~150–250ms. Nada excesivo: la interfaz
debe sentirse profesional y rápida.

---

## 14. Principios de UI (resumen)

1. Lienzo neutro + acento emerald medido.
2. Aire generoso, jerarquía clara, lectura rápida.
3. Cards livianas (borde + sombra sutil), radio consistente.
4. Una sola familia tipográfica y de íconos.
5. Reutilizar componentes y tokens; no duplicar.
6. Accesible y responsive de verdad, no por escala.
