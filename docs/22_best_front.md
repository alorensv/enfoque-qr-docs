# Mejoras Frontend – Referencia de Diseño

## Objetivos generales
- Mejorar login y layout del admin para que sean cómodos en dispositivos móviles y de escritorio.
- No cambiar lógica ni funcionalidades.
- Aplicar estética premium y moderna.

---

## Header Admin (`AdminHeader.js` + `ProfileMenu.js`)

### Decisiones de diseño UX/UI

#### Fuente
- **Inter** (Google Fonts) – sans-serif moderna, óptima legibilidad en interfaces de gestión.
- Se carga vía `<Head>` de Next.js con `font-display: swap` para rendimiento.
- Fallback: `system-ui, -apple-system, sans-serif`.

#### Color y fondo
- Gradiente profundo: `linear-gradient(135deg, #1e40af 0%, #1d4ed8 50%, #2563eb 100%)`
- Sombra: `0 2px 12px rgba(30,64,175,0.35)` – da profundidad sin ser intrusiva.

#### Logotipo / título
- Texto con gradiente blanco → blanco semi-transparente para efecto de luz.
- `font-weight: 700`, `letter-spacing: -0.01em` – lectura limpia y moderna.
- Texto simplificado: **"Enfoque QR"** (sin "- Admin").

---

### Sección de usuario (ProfileMenu)

#### Cambios realizados
- ❌ **Eliminada** la foto/imagen de perfil (`<img>`).
- ✅ **Avatar con iniciales**: círculo semitransparente que muestra las 2 primeras iniciales del nombre del usuario (ej. "AL" para "Alejandro Lorens"). Siempre visible, sin depender de imagen externa.
- ✅ **Nombre del usuario logeado**: `user?.name` extraído del contexto de autenticación (`AuthContext`).
- ✅ **Chevron animado**: flecha que rota 180° al abrir el dropdown.
- ✅ **Pill container**: borde sutil `rgba(255,255,255,0.2)` con fondo glassmorphism al hover/activo.

#### Lógica de iniciales
```js
const initials = user?.name
  ? user.name.split(' ').map((n) => n[0]).slice(0, 2).join('').toUpperCase()
  : 'U';
```

#### Dropdown (sin cambios funcionales)
- Opciones: **Editar perfil** → `/admin/perfil` | **Cerrar sesión**
- Se cierra al hacer clic afuera (`mousedown` listener).

---

## Sidebar Admin (`AdminSidebar.js`)

### Decisiones de diseño UX/UI

#### Paleta y fondo
- Fondo oscuro degradado: `linear-gradient(175deg, #0f172a 0%, #1e293b 100%)` – contraste fuerte con el contenido claro del main, crea jerarquía visual clara.
- Borde derecho sutil: `rgba(255,255,255,0.06)` – separación elegante sin líneas duras.
- Sombra derecha: `4px 0 32px rgba(0,0,0,0.35)` – profundidad y separación del contenido.

#### Íconos
- **Reemplazo de emojis por SVG inline** – resolución perfecta en cualquier pantalla, color controlable por CSS, más profesionales.
- Íconos a 20×20px, `stroke-width: 1.8` – trazo equilibrado, ni demasiado fino ni pesado.
- Color activo: `#60a5fa` (azul claro), inactivo: `#94a3b8` (gris slate).

#### Item activo
- Fondo con gradiente azul/indigo sutil: `linear-gradient(90deg, rgba(59,130,246,0.22), rgba(99,102,241,0.15))`.
- Borde izquierdo tipo "accent stripe": `box-shadow: inset 3px 0 0 #3b82f6`.
- Punto indicador con `box-shadow` glow a la derecha del label.

#### Tipografía y layout
- **Inter** consistente con el header.
- Label categórico (sección): uppercase, 0.68rem, tracking amplio, gris slate apagado.
- Texto items: 0.9rem, `letter-spacing: -0.01em`, transición de color suave.

#### Colapsar / expandir (desktop)
- Ancho: 240px expandido → 68px colapsado, transición `cubic-bezier(0.4,0,0.2,1)`.
- Botón circular con borde sutil, ícono chevron que rota 180° con CSS transition.
- Labels con `max-width` + `opacity` animados (no `display:none`) para transición fluida.
- **Tooltips en modo colapsado**: aparecen al hover sobre cada item, dark card con flecha.

#### Footer decorativo
- Punto verde con glow (`#22c55e`) + texto "Sistema activo" – da feedback visual de conexión.

#### Mobile (off-canvas)
- Sidebar fixed con `transform: translateX(-100%)` por defecto.
- Overlay semitransparente con `backdrop-filter: blur(2px)` al abrir.
- Se cierra al clickar el overlay.

---

## Estado de implementación

| Componente        | Estado     | Descripción                                                     |
|-------------------|------------|-----------------------------------------------------------------|
| `AdminHeader.js`  | ✅ Listo   | Fuente Inter, gradiente, título refinado                        |
| `ProfileMenu.js`  | ✅ Listo   | Sin foto, avatar iniciales, nombre del usuario, chevron animado |
| `AdminSidebar.js` | ✅ Listo   | Dark navy, SVG icons, item activo, colapsable, tooltips, mobile |
| `AdminLayout.js`  | ✅ Listo   | Estilos inline coherentes con sistema de diseño                 |