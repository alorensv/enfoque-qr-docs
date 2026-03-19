# Permisos por Rol

Este documento define las capacidades de cada rol dentro del sistema para los diferentes módulos.

## 1. Equipos (Items)

### Super Administrador
*   **Visualizar:** Todos los equipos de la institución.
*   **Crear/Editar:** Puede crear y editar todos los equipos de la institución.
*   **Eliminar:** Puede eliminar cualquier equipo de la institución.

### Administrador
*   **Visualizar:** Todos los equipos de la institución.
*   **Crear/Editar:** Puede crear y editar todos los equipos de la institución..
*   **Eliminar:** Puede eliminar equipos de la institución.

### Usuario
*   **Visualizar:** Todos los equipos de la institución.
*   **Crear/Editar:** No tiene permisos.
*   **Eliminar:** No tiene permisos para eliminar equipos.

---

## 2. Usuarios

### Super Administrador
*   **Visualizar:** Todos los usuarios de la institución.
*   **Crear/Editar:** Puede crear y editar todos los usuarios (incluyendo otros Super y Administradores).
*   **Eliminar:** Puede eliminar todos los usuarios.

### Administrador
*   **Visualizar:** Todos los usuarios de la institución.
*   **Crear:** Puede crear usuarios, pero no puede asignar el rol super.
*   **Editar:** Puede editar todos los usuarios **menos** a los Super Administradores.
*   **Eliminar:** Puede eliminar todos los usuarios **menos** a los Super Administradores.

### Usuario
*   **Acceso:** No tiene acceso a la pestaña/módulo de Usuarios.

---

## 3. Clientes

### Super Administrador
*   **Visualizar:** Todos los clientes de la institución.
*   **Crear/Editar:** Puede crear y editar todos los clientes.
*   **Eliminar:** Puede eliminar todos los clientes.

### Administrador
*   **Visualizar:** Todos los clientes de la institución.
*   **Editar:** Puede editar todos los clientes.
*   **Eliminar:** Puede eliminar clientes (siempre que no tengan equipos críticos asociados).

### Usuario
*   **Acceso:** No tiene acceso a la pestaña/módulo de Clientes.

---

## 4. Mantenciones

### Super Administrador
*   **Visualizar:** Todas las mantenciones de la institución.
*   **Eliminar:** Puede eliminar todas las mantenciones de la institución.

### Administrador
*   **Visualizar:** Todas las mantenciones de la institución.
*   **Eliminar:** Puede eliminar todas las mantenciones de la institución.

### Usuario
*   **Visualizar:** Solo las mantenciones registradas por él mismo.
*   **Eliminar:** Solo puede eliminar las mantenciones creadas por él mismo.
