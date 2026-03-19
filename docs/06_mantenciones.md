# Módulo de Mantenciones

Este documento describe la estructura, flujo y pasos recomendados para implementar el módulo de mantenciones en el sistema enfoque-qr.

## 1. Modelo de Datos

La tabla principal ya existe: `equipment_maintenances`. Se recomienda agregar una tabla para fotos asociadas a cada mantención y, si se requieren varios documentos por mantención, una tabla adicional para documentos.

**Tablas implementadas:**

- `equipment_maintenances`
    - id
    - equipment_id (FK)
    - user_id (FK)
    - description
    - performed_at (datetime)
    - technician
    - status
    - created_at, updated_at, deleted_at

- `equipment_maintenance_photos`
    - id
    - maintenance_id (FK a equipment_maintenances)
    - file_path (ruta relativa: `/mantenciones/{id}/fotos/{archivo}`)
    - uploaded_at

- `equipment_maintenance_documents`
    - id
    - maintenance_id (FK a equipment_maintenances)
    - name
    - file_path (ruta relativa: `/mantenciones/{id}/documentos/{archivo}`)
    - uploaded_at

> **Nota:** El campo `file_path` en la tabla principal no se utiliza, ya que se soportan múltiples archivos por mantención.

## 2. Flujo de Usuario

### a. Escaneo y Acceso
1. El usuario escanea el QR del equipo.
2. Accede a la tarjeta del equipo (Next.js, página `/qr/[token]`).
3. En la tarjeta se muestra:
    - Datos del equipo
    - Documentos
    - Historial de mantenciones (fecha, estado, responsable, botón Ver)
    - Botón: **Agregar Mantención** (si tiene permisos)

### b. Registro de Mantención
1. Al hacer clic en "Agregar Mantención":
   - Formulario básico:
    - Descripción breve
    - Fecha (auto o editable)
    - Técnico responsable
    - Subida de fotos (opcional, múltiples)
    - Subida de documentos (opcional, múltiples)
    - Botón: **Guardar** o **Completar mantención**
2. Si se guarda sin completar, la mantención queda como **incompleta** y puede ser editada luego.
3. El usuario puede volver a la mantención y completarla (agregar detalles, fotos, documentos, marcar como completada).

### c. Formulario Completo
1. Permite editar/agregar toda la información requerida:
    - Checklist de tareas realizadas (opcional)
    - Repuestos usados (opcional)
    - Observaciones
    - Fotos adicionales
    - Adjuntar archivos (documentos, resumen, etc.)
2. Al finalizar, marcar como **completada**.

## 3. Endpoints Implementados (API)

- `GET /maintenances/equipment/:equipmentId` — Listar mantenciones de un equipo (con responsable y estado)
- `POST /maintenances/equipment/:equipmentId` — Crear mantención
- `GET /maintenances/:id` — Ver detalle de mantención
- `PUT /maintenances/:id` — Editar mantención
- `POST /maintenances/:id/photos` — Subir fotos (múltiples, campo `photos[]`)
- `POST /maintenances/:id/documents` — Subir documentos (múltiples, campo `documents[]`)
- `POST /maintenances/:id/complete` — Marcar como completada

## 4. Interfaz de Usuario (Front)

- En la tarjeta del equipo (`/qr/[token]`):
    - Muestra historial de mantenciones reales (fecha, estado, responsable, botón Ver)
    - Botón para agregar nueva mantención (si tiene permisos)
- En la vista de mantención:
    - Formulario editable
    - Subida de fotos y documentos
    - Botón para marcar como completada

## 5. Permisos y Seguridad

- Solo usuarios autenticados pueden agregar o editar mantenciones
- Solo usuarios de la institución pueden ver/agregar mantenciones de sus equipos

## 6. Consideraciones Técnicas

- Los archivos de fotos y documentos se almacenan en subcarpetas `/mantenciones/{id}/fotos/` y `/mantenciones/{id}/documentos/` dentro de `public`.
- El backend expone la carpeta `public` como estática para acceso directo desde el frontend.
- El path guardado en la base de datos es relativo y se puede usar directamente en el front.
- Se valida la presencia de archivos y se retorna error si falta alguno al subir.
- El responsable se muestra usando el nombre completo del usuario si está disponible, o el campo técnico.
- Permitir guardar mantenciones como borrador.
- Registrar usuario y fecha de cada acción.
- Notificar (opcional) al completar una mantención.

---
## 7. Actualizaciones de Base de Datos

### 13/03/2026 - Agregar hora a performed_at
Para poder almacenar la hora de la mantención, se cambió el tipo de dato de `performed_at` de `date` a `datetime`.

```sql
ALTER TABLE equipment_maintenances MODIFY COLUMN performed_at DATETIME;
```

---
**Siguiente paso:**
1. Implementar modelo de fotos y documentos si se requieren múltiples archivos por mantención
2. Crear endpoints y vistas según el flujo anterior
3. Probar el flujo escaneando un QR y registrando una mantenció