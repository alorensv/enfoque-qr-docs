# Descripción del Proyecto
Enfoque QR es un módulo que permite generar códigos QR de forma anticipada y luego enrolarlos
a equipos.
Cada QR dirige a una URL absoluta pública que permite consultar ficha del equipo, documentación
técnica,
historial de servicio, trazabilidad de escaneos y gatillos de notificaciones.

# Principios del Diseño
- Los códigos QR se pueden generar antes de ser asignados o al momento de crear el equipo.
- El QR contiene únicamente una URL absoluta con un token.
- El token es el único identificador persistido.
- El equipo es la entidad central del dominio.
- La imagen QR es regenerable y no crítica.

# Stack Tecnológico
Frontend: Next.js (Vercel)
Backend: NestJS (AWS)
Base de Datos: MySQL (AWS RDS)
Infraestructura local: Docker + Docker Compose

# Arquitectura General
QR Scan
↓
Next.js (ruta pública /qr/:token)
↓
NestJS API
↓
MySQL

# Arquitectura Tecnológica

Frontend: Next.js (React) – Vercel
Backend: NestJS – AWS
Base de datos: MySQL 8 – AWS RDS
Storage de imágenes QR: Local / S3
Comunicación: REST API

# Flujo del Código QR
1. Backend genera token único
2. Se construye URL absoluta (https://app.dominio.cl/qr/{token})
3. Se genera imagen QR (PNG / SVG)
4. QR se imprime o distribuye
5. Usuario escanea QR
6. Se valida token en backend
7. Se registra trazabilidad
8. Se retorna ficha pública

# Modelo de Datos – Entidades
- users
- user_profiles
- institutions
- user_institution
- devices
- device_has_qr_code
- qr_codes
- qr_scan_logs
- documents
- document_versions
- maintenances

# Entidad Equipments
# Entity: Devices
Represents any physical or logical device in the system.
It is the central entity of the domain.
# Códigos QR
# QR Codes
QR codes exist independently of the device.
They are enrolled by assigning device_id.
The QR image is stored in png/svg format and the path is registered.
# Enrolamiento de QR
A QR code is available if:
- device_id IS NULL
- enabled = 1
Enrollment is a controlled UPDATE.
# Trazabilidad de Escaneos
Each public scan records:
- Date and time
- IP
- User-Agent
- Scanned QR code
# Documentación Versionada
Documents belong to the device.
Each document can have multiple versions with integrity control.
# Mantenciones
Historical record of technical service and maintenances performed on the device.
# Seguridad
-- Non-sequential tokens
-- Rate limiting
-- Restricted public DTO
-- Access logs
# Acceso Público
GET /qr/:token
No authentication required.
Read-only.
# Notificaciones
Possible events:
- QR scanned
- Document updated
- Maintenance registered
Asynchronous processing recommended.

# Estructura Frontend (Next.js)

/app
/components
/services
/admin
  /qrs
  /devices
/qr/[token]

Public view
Admin panel
Decoupled API client

# Estructura Backend (NestJS)

#/src/modules
  /auth
  /users
  /institutions
  /devices
  /qr
  /documents
  /maintenances
  /notifications

Modular architecture
Separation of responsibilities
Ready for microservices

# Flujo de control y enrolamiento (UI)

Admin
 ↓
List "Available QRs"
 ↓
Select QR
 ↓
Select device
 ↓
Confirm enrollment

# Seguridad

Non-sequential tokens
Public access is read-only
Auditable scans
Administrative roles
Token must never reveal IDs
Use tokens ≥ 32 characters
Unique index required

# Escalabilidad

Save relative path, not absolute:
Stateless backend
Regenerable QRs
Decoupled storage

# Roles de Usuario

Administrator
Operator
Public user

# Flujo generación masiva de QRS

Bulk QR generation (100, 1,000, n)
QR image creation
Path persistence
Post-enrollment to device
QR status change

# Deploy
Frontend: Vercel
Backend: AWS (EC2 / ECS)
Base de Datos: AWS RDS MySQL

# Roadmap
MVP:
- QR público
- Ficha equipo
- Documentos
- Escaneos
v1:
- Mantenciones
- Versionado
- Notificaciones
v2:
- Firma digital
- Auditoría
- Integraciones

## Instalación de dependencias backend

Ejecuta estos comandos en la carpeta `backend` para instalar las dependencias necesarias:

```bash
npm install @nestjs/common @nestjs/typeorm typeorm
npm install --save-dev @types/node
```