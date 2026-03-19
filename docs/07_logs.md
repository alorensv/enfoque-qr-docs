
Se requiere almacenar logs para todos los cambios sobre una mantención. Registro, cambio de estado y otros.

## Sugerencia de tabla para almacenar los logs

**Nombre:** `equipment_maintenance_log`

| Campo                | Tipo           | Descripción                                 |
|----------------------|----------------|---------------------------------------------|
| id                   | bigint (PK)    | Identificador único del log                 |
| maintenance_id       | bigint (FK)    | Referencia a la mantención                  |
| user_id              | bigint (FK)    | Usuario que realizó la acción               |
| action               | varchar(50)    | Tipo de acción (registro, cambio estado, etc)|
| description          | text           | Descripción detallada del cambio            |
| created_at           | timestamp      | Fecha y hora del evento                     |

## Sugerencia de servicio para almacenar logs

Crear un servicio `MaintenanceLogService` con métodos como:

- `createLog(maintenanceId: number, userId: number, action: string, description: string): Promise<MaintenanceLog>`
	- Registra un nuevo log asociado a una mantención.
- `getLogsByMaintenance(maintenanceId: number): Promise<MaintenanceLog[]>`
	- Obtiene todos los logs de una mantención específica.

Este servicio puede ser inyectado en los controladores o servicios donde se realicen cambios sobre mantenciones para registrar automáticamente los eventos relevantes.