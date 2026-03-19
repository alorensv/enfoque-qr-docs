Habilitar página /admin/mantenciones con el listado de mentenciones activas y eliminadas.

En el caso de las eliminadas, se debe mostrar un botón para restaurarlas.

En el caso de las activas, se debe mostrar un botón para eliminarlas.

Debe tener similar lógica al listado de documentos.

**✓ Implementado**
- Backend: Endpoint `GET /maintenances/admin/all` agregado.
- Backend: Endpoint `POST /maintenances/:id/restore` agregado.
- Frontend: Página `/admin/mantenciones` construida listando activos e inactivos, con botones de restaurar y borrar.