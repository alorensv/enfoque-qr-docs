# Página de Usuarios

## Objetivo
Gestionar los usuarios de la institución, permitiendo visualizar, editar y eliminar usuarios. La funcionalidad está diseñada con un estilo y estructura similar a la página de equipos.

## Características Implementadas

### Backend

Se ha creado un módulo completo de usuarios en el backend con la siguiente estructura:

#### 1. Módulo de Usuarios (`backend/src/users/`)

**users.service.ts**
- `findByInstitution(institutionId)`: Lista todos los usuarios de una institución específica
- `findOne(userId, institutionId)`: Obtiene un usuario específico verificando que pertenezca a la institución
- `remove(userId, institutionId)`: Elimina (soft delete) la relación usuario-institución

**users.controller.ts**
- `GET /users`: Lista todos los usuarios de la institución del usuario autenticado
- `GET /users/:id`: Obtiene detalles de un usuario específico
- `DELETE /users/:id`: Elimina un usuario de la institución

**users.module.ts**
- Módulo que integra el controlador, servicio y entidades relacionadas
- Exporta el servicio para uso en otros módulos

#### 2. Guard de Autenticación (`backend/src/auth/jwt-auth.guard.ts`)

Se creó un guard JWT reutilizable que extiende `AuthGuard('jwt')` de Passport para proteger las rutas con autenticación.

#### 3. Integración con App Module

El módulo de usuarios se agregó a `app.module.ts` para que esté disponible en toda la aplicación.

### Frontend

#### Página de Usuarios (`front/pages/admin/usuarios.js`)

La página implementa las siguientes funcionalidades:

1. **Listado de Usuarios**
   - Muestra nombre completo, email, rol y estado
   - Diseño responsivo con tabla estilizada
   - Estados visuales (loading, error, lista vacía)
   - Solo muestra usuarios de la institución del usuario autenticado

2. **Badges de Estado y Rol**
   - **Roles**: Admin (morado), Editor (azul), User (gris)
   - **Estado**: Activo (verde), Inactivo (gris)

3. **Acciones por Usuario**
   - Dropdown con opciones al hacer clic en el menú de tres puntos
   - Editar usuario (redirige a `/admin/usuarios/:id/editar`)
   - Eliminar usuario (con confirmación)

4. **Botón de Nuevo Usuario**
   - Header con botón destacado para crear usuarios
   - Redirige a `/admin/usuarios/nuevo`

5. **Estados Visuales**
   - Spinner de carga animado
   - Mensaje de error con icono
   - Estado vacío con ilustración y call-to-action

#### Integración con Navegación

El menú lateral (`AdminSidebar.js`) ya contiene el enlace a la página de usuarios con el icono 👤.

## Estructura de Datos

### Usuario en la Respuesta del Backend

```json
{
  "id": 1,
  "email": "usuario@ejemplo.com",
  "fullName": "Juan Pérez",
  "role": "admin",
  "status": 1,
  "createdAt": "2024-01-15T10:30:00.000Z",
  "userInstitutionId": 5
}
```

### Relación con Entidades

- **users**: Información básica del usuario (email, password, status)
- **user_profiles**: Datos del perfil (fullName, phone)
- **user_institution**: Relación entre usuario e institución (role, deletedAt)

## Consideraciones de Seguridad

1. **Autenticación Requerida**: Todos los endpoints están protegidos con `JwtAuthGuard`
2. **Aislamiento por Institución**: Los usuarios solo pueden ver y gestionar usuarios de su propia institución
3. **Soft Delete**: Al eliminar un usuario, se marca `deletedAt` en `user_institution`, preservando datos históricos
4. **Credentials Include**: Las peticiones frontend incluyen cookies de autenticación

## Próximos Pasos

Para completar la funcionalidad:

1. **Crear formulario de nuevo usuario** (`/admin/usuarios/nuevo`)
   - Campos: email, password, nombre completo, teléfono, rol
   - Validaciones frontend y backend
   - Creación en tablas `users`, `user_profiles` y `user_institution`

2. **Crear formulario de edición** (`/admin/usuarios/:id/editar`)
   - Pre-cargado con datos del usuario
   - Permitir cambio de rol, nombre, email, estado
   - Actualización de múltiples tablas

3. **Validaciones adicionales**
   - Verificar que no se pueda eliminar el último admin
   - Prevenir auto-eliminación del usuario actual
   - Validación de email único por institución

4. **Permisos granulares**
   - Solo admins pueden crear/eliminar usuarios
   - Editores pueden ver pero no modificar

