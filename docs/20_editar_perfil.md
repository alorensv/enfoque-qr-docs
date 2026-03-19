# Editar Perfil

**Estado**: ✅ Completado

Implementar frontend y backend para la funcionalidad de editar perfil.

### Requerimientos:
- [x] **Frontend:** Crear una página para editar el perfil del usuario. (`/admin/perfil`)
- [x] **Backend:** Crear un endpoint para editar el perfil del usuario. (`GET /users/profile` y `PUT /users/profile`)

- [x] Permitir editar su contraseña.
- [x] No puede editar su rol.
- [x] No puede editar su email.
- [x] No puede editar su estado.
- [x] Usar diseño similar a la edición de un equipo.

### Cambios realizados:

**Backend (`UsersController` y `UsersService`):**
- Agregados endpoints `GET /users/profile` y `PUT /users/profile`.
- Agregado método `updateProfile` en `UsersService` que solo permite modificar `password`, `fullName` y `phone`.

**Frontend:**
- Modificado componente `AdminHeader.js` para que la opción de "Editar perfil" en el menú de usuario redirija a `/admin/perfil`.
- Creada la página `perfil.js` en `front/pages/admin`. Utilizando `AdminLayout` y el diseño similar de tarjeta utilizado en la edición de un equipo. Muestra "Email" y "Rol" deshabilitados (solo lectura). Permite editar nombre, teléfono y contraseña mediante una confirmación.
