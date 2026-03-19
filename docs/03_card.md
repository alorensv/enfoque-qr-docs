# Vista UX/UI para Ficha de Equipo (Versión Actualizada)

## Objetivo
Diseñar una vista de información del equipo que sea clara, moderna y amigable, priorizando la experiencia en dispositivos móviles (`mobile-first`) pero manteniendo una excelente visualización en escritorio. La vista debe ser útil tanto para el público general como para administradores con permisos de gestión.

---

## Estructura General

- **Header:**
  - Nombre del equipo, descripción y estado (con un `badge` de color).
  - Foto del equipo (si está disponible).

- **Resumen de Última Mantención:**
  - Una sección destacada que muestra la información clave de la última mantención registrada: fecha, estado y responsable.

- **Detalles del Equipo:**
  - Información técnica y de identificación, como número de serie, fecha de creación y token del QR.

- **Sección de Documentación:**
  - Listado de documentos públicos y privados (visibles según el rol del usuario).
  - Opción para descargar cada documento.
  - Para administradores, opción para marcar documentos como inactivos.

- **Historial de Mantenciones:**
  - Lista cronológica de todas las mantenciones realizadas.
  - Para cada mantención, se muestra fecha, estado y responsable.
  - Acceso para ver el detalle completo de cada mantención.
  - Para administradores, un botón para agregar nuevas mantenciones.

- **Acceso de Administrador:**
  - Un enlace discreto al final de la página para que los usuarios con permisos puedan iniciar sesión. Se elimina el campo de "código de acceso" para evitar confusión al público general.

---

## Diseño Mobile (ejemplo visual)

```
+------------------------------------+
| Equipo X                           |
| Descripción breve del equipo...    |
| [Activo]                           |
|                            [Foto]  |
+------------------------------------+
| Última Mantención                  |
| Fecha: 12/01/2026   Estado: OK     |
| Resp: Juan Pérez                   |
+------------------------------------+
| Detalles del Equipo                |
| N/S: 123-ABC   Creado: 10/10/2025  |
+------------------------------------+
| Documentación                      |
| - Manual.pdf         [Descargar]   |
| - Certificado.pdf    [Descargar]   |
+------------------------------------+
| Historial de Mantenciones [Nueva +]|
| - 12/01/2026 - OK      [Ver]       |
| - 10/11/2025 - OK      [Ver]       |
+------------------------------------+
| ¿Eres administrador? Inicia sesión |
+------------------------------------+
```

---

## Detalles de UX/UI
- **Jerarquía Visual Clara:** La información más relevante (nombre, estado, última mantención) se presenta primero y de forma destacada.
- **Colores y Estados:** Uso consistente de colores para los estados (ej. verde para `activo`, gris para `inactivo`, amarillo para `pendiente`).
- **Diseño Limpio y Espaciado:** Se utilizan tarjetas y separadores para agrupar la información de forma lógica, mejorando la legibilidad.
- **Acceso Discreto para Admins:** El inicio de sesión no interrumpe la experiencia del usuario general, pero es fácilmente accesible para quien lo necesita.
- **Mobile-first:** El diseño está optimizado para ser completamente funcional y legible en pantallas pequeñas.

---

## Flujos de Usuario
1. **Vista Pública:** Un usuario escanea el QR y ve la información general del equipo, su última mantención, detalles y documentos públicos.
2. **Inicio de Sesión de Admin:** Un administrador hace clic en el enlace "Inicia sesión aquí", es redirigido a una página de login y, tras autenticarse, vuelve a la ficha con permisos elevados.
3. **Vista de Administrador:** El administrador ve toda la información, incluyendo documentos privados, y tiene acceso a acciones como agregar mantenciones o desactivar documentos.

---

## Sugerencia de Componentes (React/Next.js + TailwindCSS)
- `EquipoHeader`
- `UltimaMantencionCard`
- `EquipoDetails`
- `DocumentosList`
- `MantencionesList`
- `AdminLoginLink`

---

Esta estructura actualizada refleja el diseño implementado, ofreciendo una experiencia de usuario superior y una clara separación entre la vista pública y las funcionalidades de administración.