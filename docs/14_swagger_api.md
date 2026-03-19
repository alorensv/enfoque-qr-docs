# Documentación Swagger API

## Acceso a la documentación

La documentación interactiva de Swagger está disponible en:

```
http://localhost:3001/api-docs
```

## Características

### 1. Documentación completa de endpoints
- Todos los endpoints del API están documentados
- Descripción detallada de cada operación
- Parámetros requeridos y opcionales
- Ejemplos de respuestas

### 2. Autenticación
- **Cookie Auth**: Autenticación mediante cookie httpOnly `access_token`
- **JWT Bearer**: Token JWT en header Authorization

### 3. Tags organizados por módulo
- `auth` - Autenticación y gestión de sesiones
- `equipments` - Gestión de equipos y documentos
- `qr` - Códigos QR y validación
- `maintenances` - Mantenciones de equipos
- `users` - Gestión de usuarios
- `institutions` - Información de instituciones

## Uso de Swagger UI

### Probar endpoints autenticados

1. **Iniciar sesión**:
   - Ir al endpoint `POST /auth/login`
   - Click en "Try it out"
   - Ingresar credenciales:
     ```json
     {
       "email": "admin@enfoqueqr.cl",
       "password": "tu_password"
     }
     ```
   - Ejecutar la petición
   - La cookie se guardará automáticamente en el navegador

2. **Usar endpoints protegidos**:
   - Todos los endpoints marcados con 🔒 requieren autenticación
   - La cookie httpOnly se envía automáticamente con cada petición
   - Swagger UI maneja la autenticación de forma transparente

### Probar endpoints públicos

Los siguientes endpoints NO requieren autenticación:
- `GET /qr/:token` - Consultar información de QR
- `GET /qr/:token/image` - Descargar imagen QR
- `GET /equipments/by-qr/:token` - Consultar equipo por QR
- `GET /maintenances/:id/logs` - Ver logs de mantención
- `GET /maintenances/:id/photos` - Ver fotos de mantención
- `GET /maintenances/:id/documents` - Ver documentos de mantención
- `GET /maintenances/equipment/:equipmentId` - Ver mantenciones de equipo

## Endpoints principales

### Autenticación (`/auth`)
- `POST /auth/login` - Iniciar sesión
- `GET /auth/me` - Obtener perfil del usuario 🔒
- `POST /auth/logout` - Cerrar sesión

### Equipos (`/equipments`)
- `GET /equipments` - Listar equipos 🔒
- `GET /equipments/:id` - Ver detalles de equipo
- `POST /equipments` - Crear equipo 🔒
- `PUT /equipments/:id` - Actualizar equipo 🔒
- `DELETE /equipments/:id` - Eliminar equipo 🔒
- `GET /equipments/by-qr/:token` - Buscar por QR (público)
- `GET /equipments/:id/documents` - Listar documentos
- `POST /equipments/:id/documents` - Subir documento 🔒

### Códigos QR (`/qr`)
- `GET /qr` - Listar todos los QR 🔒
- `GET /qr/:token` - Consultar QR (público)
- `GET /qr/:token/image` - Descargar imagen (público)
- `POST /qr/generate-batch` - Generar lote de QR 🔒
- `GET /qr/available/list` - QR disponibles 🔒
- `POST /qr/:id/revoke` - Revocar QR 🔒

### Mantenciones (`/maintenances`)
- `GET /maintenances/equipment/:equipmentId` - Listar mantenciones (público)
- `POST /maintenances/equipment/:equipmentId` - Crear mantención 🔒
- `GET /maintenances/:id` - Ver mantención (público)
- `PUT /maintenances/:id` - Actualizar mantención 🔒
- `DELETE /maintenances/:id` - Eliminar mantención 🔒
- `POST /maintenances/:id/photos` - Subir foto 🔒
- `POST /maintenances/:id/documents` - Subir documento 🔒
- `POST /maintenances/:id/complete` - Completar mantención 🔒

### Usuarios (`/users`)
- `GET /users` - Listar usuarios 🔒
- `GET /users/:id` - Ver usuario 🔒
- `POST /users` - Crear usuario 🔒
- `PUT /users/:id` - Actualizar usuario 🔒
- `DELETE /users/:id` - Eliminar usuario 🔒

### Instituciones (`/institutions`)
- `GET /institutions/by-slug/:slug` - Buscar por slug
- `GET /institutions/:id` - Buscar por ID

## Notas técnicas

### Formato de respuestas
- Todos los endpoints retornan JSON
- Códigos de estado HTTP estándar:
  - `200` OK - Operación exitosa
  - `201` Created - Recurso creado
  - `401` Unauthorized - No autenticado
  - `404` Not Found - Recurso no encontrado
  - `500` Internal Server Error - Error del servidor

### Subida de archivos
- Los endpoints que aceptan archivos usan `multipart/form-data`
- Campos comunes:
  - `file` - Archivo a subir
  - `name` - Nombre descriptivo
  - `type` - Tipo de documento

### Paginación
- Endpoints con listados soportan paginación:
  - `page` - Número de página (default: 1)
  - `limit` - Elementos por página (default: 50)
  - `search` - Búsqueda de texto (opcional)

## Desarrollo

### Actualizar documentación Swagger

1. **Agregar decoradores a un nuevo endpoint**:
```typescript
@Get(':id')
@ApiOperation({ summary: 'Descripción del endpoint' })
@ApiParam({ name: 'id', description: 'Descripción del parámetro' })
@ApiResponse({ status: 200, description: 'Respuesta exitosa' })
@ApiResponse({ status: 404, description: 'No encontrado' })
async findOne(@Param('id') id: string) {
  // ...
}
```

2. **Marcar endpoint como protegido**:
```typescript
@UseGuards(JwtAuthGuard)
@ApiCookieAuth('access_token')
```

3. **Documentar body de petición**:
```typescript
@ApiBody({
  schema: {
    type: 'object',
    required: ['field1', 'field2'],
    properties: {
      field1: { type: 'string', example: 'valor ejemplo' },
      field2: { type: 'number', example: 123 }
    }
  }
})
```

### Configuración en main.ts

La configuración de Swagger se encuentra en `backend/src/main.ts`:
- Título y descripción del API
- Versión
- Tags organizados por módulo
- Esquemas de autenticación (Cookie + JWT)
- Personalización de la UI

## Recursos

- [Documentación NestJS Swagger](https://docs.nestjs.com/openapi/introduction)
- [OpenAPI Specification](https://swagger.io/specification/)
- [Swagger UI](https://swagger.io/tools/swagger-ui/)
