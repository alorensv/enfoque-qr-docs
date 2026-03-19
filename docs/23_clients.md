# Módulo de Clientes

## Objetivo Principal
Implementar la gestión de clientes en el panel de administración, permitiendo registrarlos, administrarlos y asociarlos directamente a los equipos existentes o nuevos.

## 1. Diseño de Base de Datos

### Nueva Tabla / Entidad: `clients`
- `id` (Primary Key, tipo numérico o UUID según la arquitectura del proyecto).
- `institution_id` (Foreign Key, Obligatorio) - ID de la institución a la que pertenece el cliente (se obtiene del usuario autenticado).
- `name` (String, Obligatorio) - Nombre o razón social del cliente.
- `email` (String, Opcional, Único) - Correo electrónico de contacto.
- `phone` (String, Opcional) - Teléfono de contacto.
- `address` (String, Opcional) - Dirección física.
- `created_at` (Timestamp)
- `updated_at` (Timestamp)

**Script SQL sugerido:**
```sql
CREATE TABLE clients (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    institution_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_clients_institution FOREIGN KEY (institution_id) REFERENCES institutions(id) ON DELETE CASCADE
);
```

### Modificación de la Tabla / Entidad: `equipments` (Equipos)
- Añadir nuevo campo: `client_id` (Foreign Key, Nullable) referenciando a `clients(id)`.
- **Relación:** Un cliente puede tener múltiples equipos asociados (Uno a Muchos - `1:N`).

**Script SQL sugerido:**
```sql
ALTER TABLE equipments 
ADD COLUMN client_id BIGINT UNSIGNED NULL AFTER institution_id;

ALTER TABLE equipments 
ADD CONSTRAINT fk_equipment_client 
FOREIGN KEY (client_id) 
REFERENCES clients(id) 
ON DELETE SET NULL;
```

## 2. Requerimientos del Backend

### Endpoints para Clientes (`/clients`)
- `GET /clients`: Obtener la lista de todos los clientes (aplicar paginación y búsqueda). **Debe filtrar solo los clientes asociados al `institution_id` del usuario autenticado.**
- `GET /clients/:id`: Obtener los detalles de un cliente específico, **previa validación de que pertenezca a la misma institución.**
- `POST /clients`: Crear un nuevo cliente. Se debe validar campos obligatorios. El `institution_id` **debe ser inferido** automáticamente usando el token JWT / datos del usuario en sesión (por seguridad, no debe venir desde el frontend).
- `PUT/PATCH /clients/:id`: Actualizar la información de un cliente existente.
- `DELETE /clients/:id`: Eliminar un cliente. (Se debe definir la regla de negocio: si se borra un cliente, sus equipos deben de cambiar `client_id` a `null` o aplicar borrado en cascada/bloqueo de borrado predeterminado).

### Endpoints para Equipos (`/equipments` o similar)
- **Creación / Edición:** Modificar los DTOs para permitir enviar y guardar opcionalmente el `client_id` al momento de interactuar con un equipo.
- **Asignación rápida (`PATCH`):** Modificar la actualización del equipo para cambiar de cliente fácilmente.

## 3. Requerimientos del Frontend

### 3.1 Gestión de Clientes (Sección Admin)
- Agregar `Clientes` en el menú lateral (ej: debajo de Usuarios).
- **Página `/admin/clientes`:** Tabla principal con los datos del cliente (Nombre, Email, Teléfono, y opcionalmente número de equipos asociados).
- **Formulario / Modal:** Crear y editar clientes de forma amigable usando los componentes existentes del diseño estético (botones, modales).

### 3.2 Formulario de Creación/Edición de Equipos
- Integrar un campo de selección (Dropdown/Select) en el formulario de creación de equipos.
- Dicho campo debe hacer un llamado (`fetch`) a `GET /clients` para mostrar una lista poblada con los nombres de todos los clientes disponibles.

### 3.3 Listado de Equipos (`/admin/equipos`)
- En la tabla o cuadrícula de equipos, visualizar una columna/etiqueta con el "Cliente" al que pertenece.
- **Acción Rápida de Asignación:** En las acciones de la fila del equipo (o mediante selección múltiple), proveer una opción llamada "Asociar a Cliente" que levante un Modal ligero con el selector de clientes y actualice el equipo rápidamente sin pasar por el formulario completo de edición.

## 4. Próxima Hoja de Ruta (Checklist de Ejecución)
- [x] Generar entidad, DTOs, controlador y servicio para `Client` en el proyecto Backend (NestJS).
- [x] Modificar la entidad y DTOs actuales de `Equipment` (NestJS).
- [x] Procesar la migración o sincronización de base de datos necesaria (TypeORM u otro).
- [ ] Construir y diseñar las páginas para Clientes en el Frontend (React/Next.js).
- [ ] Actualizar los componentes de equipos (`EquipmentForm`, `EquipmentList`) e incorporar el llamado al endpoint de clientes.