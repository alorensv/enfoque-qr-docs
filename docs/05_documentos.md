# Gestión de Documentos de Equipos


## Modelo de Documento


Se agrega el campo `isPrivate` (boolean) para definir si el documento es privado (solo visible para usuarios autenticados y autorizados) o público (visible para todos los usuarios con acceso al equipo).

**Tabla equipment_documents (actualizada):**
- id
- equipment_id (FK)
- user_id (FK)
- name
- type
- file_path
- is_private (tinyint(1) DEFAULT 0)  -- 0: público, 1: privado
- created_at, updated_at, deleted_at

---

## Flujo de carga de documentos

1. El usuario accede a `/admin/docs/nuevo?equipmentId=ID` para cargar un documento asociado a un equipo.
2. El formulario solicita nombre, tipo, archivo del documento y si será privado o público (checkbox o selector).
3. Al guardar, el frontend obtiene el `institutionId` del usuario autenticado (desde el contexto de autenticación) y lo envía junto con el archivo, metadatos y el valor de `isPrivate` al backend.
4. El backend almacena el archivo en `public/equipos/{equipmentId}/documentos/`, registra la ruta y metadatos en la base de datos.

## Endpoint de carga de documentos

- **POST** `/equipments/:id/documents`
  - Formato: `multipart/form-data`
  - Campos requeridos:
    - `file`: archivo a subir
    - `name`: nombre del documento
    - `type`: tipo o extensión (opcional)
    - `userId`: id del usuario que sube el documento
    - `institutionId`: id de la institución (obtenido del usuario autenticado)
    - `isPrivate`: 1 si es privado, 0 si es público

### Ejemplo de payload (FormData)
```
file: manual.pdf
name: Manual de uso
userId: 1
institutionId: 2
isPrivate: 0
```

## Validaciones
- El backend valida que se reciba un archivo y un institutionId válido.
- El backend rechaza la carga si falta institutionId o el usuario no pertenece a una institución.
- El backend actualiza el campo `institution_id` del equipo si es diferente al institutionId recibido.
- El frontend muestra mensajes de error si falta algún dato o si la carga falla.

## Listado y descarga de documentos
- **GET** `/equipments/:id/documents`: lista los documentos asociados a un equipo. El backend filtra según permisos y visibilidad (`isPrivate`).
- **GET** `/equipments/documents/:docId/download`: descarga el archivo del documento. El backend valida si el usuario tiene acceso según `isPrivate` y permisos.

## Seguridad
- El institutionId siempre se obtiene del usuario autenticado, nunca del equipo ni del frontend manualmente.
- El backend valida la pertenencia del usuario a la institución antes de aceptar la carga.
- El backend actualiza la relación equipo-institución si corresponde.
- El backend valida la visibilidad del documento (`isPrivate`) y los permisos del usuario antes de mostrar o permitir descargar el archivo.

## Mejoras futuras
- Asociar el userId real del usuario autenticado (actualmente simulado).
- Implementar control de versiones de documentos.
- Permitir eliminar o actualizar documentos.
- Permitir cambiar la visibilidad (privado/público) de un documento después de creado.

---

**Última actualización:** 30/12/2025
