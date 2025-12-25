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
- equipments
- equipment_qr_codes
- qr_scan_logs
- equipment_documents
- equipment_document_versions
- equipment_maintenances

# Entidad Equipments
Representa cualquier equipo físico o lógico del sistema.
Es la entidad central del dominio.
# Códigos QR
Los códigos QR existen independientemente del equipo.
Se enrolan mediante la asignación de equipment_id.
Se almacena la imgen en png/svg y se registra el path.
# Enrolamiento de QR
Un QR disponible cumple:
- equipment_id IS NULL
- enabled = 1
El enrolamiento es un UPDATE controlado.
# Trazabilidad de Escaneos
Cada escaneo público registra:
- Fecha y hora
- IP
- User-Agent
- Código QR escaneado
# Documentación Versionada
Los documentos pertenecen al equipo.
Cada documento puede tener múltiples versiones con control de integridad.
# Mantenciones
Registro histórico de servicio técnico y mantenciones realizadas al equipo.
# Seguridad
- Tokens no secuenciales
- Rate limiting
- DTO público restringido
- Logs de acceso
# Acceso Público
GET /qr/:token
Sin autenticación.
Solo lectura.
# Notificaciones
Eventos posibles:
- Escaneo QR
- Documento actualizado
- Mantención registrada
Procesamiento asíncrono recomendado.

# Estructura Frontend (Next.js)

/app
/components
/services
/admin
  /qrs
  /equipos
/qr/[token]

Vista pública
Panel administrativo
Cliente API desacoplado

# Estructura Backend (NestJS)

#/src/modules
  /auth
  /users
  /instituciones
  /equipos
  /qr
  /documentos
  /mantenciones
  /notificaciones

Arquitectura modular
Separación de responsabilidades
Preparado para microservicios

# Flujo de control y enrolamiento (UI)

Admin
 ↓
Lista "QR disponibles"
 ↓
Selecciona QR
 ↓
Selecciona equipo
 ↓
Confirmar enrolamiento

# Seguridad

Tokens no secuenciales
Acceso público solo lectura
Escaneos auditables
Roles administrativos
El token nunca debe revelar IDs
Usar tokens ≥ 32 caracteres
Índice único obligatorio

# Escalabilidad

Guardar path relativo, no absoluto:
Backend stateless
QRs regenerables
Storage desacoplado

# Roles de Usuario

Administrador
Operador
Usuario público

# Flujo generación masiva de QRS

Generación masiva de QRs (100, 1.000, n)
Creación de imagen QR
Persistencia del path
Enrolamiento posterior a equipo
Cambio de estado del QR

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

