# Registro de Escaneos QR (Scan Logs) - Plan de Implementación

## 📋 Resumen Ejecutivo

**Objetivo:** Cada vez que se escanee un código QR o se acceda a la tarjeta QR de un equipo, registrar el escaneo. Mostrar en la tabla de equipos del admin la cantidad de escaneos y permitir ver el detalle al hacer click.

**Alcance:**
- Registrar escaneos directos (acceso a `/qr/:token`)
- Registrar búsquedas universales (ya implementado en `searchBySerialInInstitution`)
- Mostrar columna de escaneos en tabla de equipos admin
- Modal/página de detalle de escaneos por equipo

**Impacto:** Medio - Requiere nuevo endpoint backend, modificación del frontend de tarjeta QR y de la tabla de equipos admin.

---

## 1️⃣ ANÁLISIS DEL ESTADO ACTUAL

### 1.1 Base de Datos (ya creada)

La tabla `qr_scan_logs` ya existe en la base de datos:

```sql
CREATE TABLE `qr_scan_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `qr_code_id` BIGINT UNSIGNED NOT NULL,
  `ip` VARCHAR(45) NULL DEFAULT NULL,
  `user_agent` TEXT NULL DEFAULT NULL,
  `scanned_at` TIMESTAMP NULL DEFAULT (CURRENT_TIMESTAMP),
  `updated_at` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  `search_type` ENUM('direct','universal') NULL DEFAULT 'direct'
    COMMENT 'Tipo de acceso: directo por QR específico o búsqueda universal',
  `search_query` VARCHAR(255) NULL DEFAULT NULL
    COMMENT 'Serial number buscado en caso de búsqueda universal',
  `institution_id` BIGINT UNSIGNED NULL DEFAULT NULL
    COMMENT 'Institución desde la cual se realizó la búsqueda universal',
  PRIMARY KEY (`id`),
  INDEX `qr_code_id` (`qr_code_id`),
  INDEX `idx_qr_scan_logs_ip` (`ip`),
  INDEX `idx_qr_scan_logs_scanned_at` (`scanned_at`),
  INDEX `idx_qr_scan_logs_search_type` (`search_type`),
  INDEX `idx_qr_scan_logs_search_query` (`search_query`),
  INDEX `idx_qr_scan_logs_institution` (`institution_id`),
  INDEX `idx_qr_scan_logs_type_institution` (`search_type`, `institution_id`),
  CONSTRAINT `fk_qr_scan_logs_institution`
    FOREIGN KEY (`institution_id`) REFERENCES `institutions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `qr_scan_logs_ibfk_1`
    FOREIGN KEY (`qr_code_id`) REFERENCES `equipment_qr_codes` (`id`) ON DELETE NO ACTION
) ENGINE=InnoDB;
```

### 1.2 Backend ya implementado

| Archivo | Estado | Descripción |
|---------|--------|-------------|
| `src/qr/entities/qr-scan-log.entity.ts` | ✅ Existe | Entidad TypeORM con campos: id, qrCodeId, searchType, searchQuery, institutionId, ip, userAgent, scannedAt |
| `src/qr/qr-scan-log.service.ts` | ✅ Existe | Métodos `create()` y `getStatsByInstitution()` |
| `src/qr/qr.module.ts` | ✅ Existe | Importa QrScanLog entity, exporta QrScanLogService |
| `src/equipment/equipment.service.ts` | ✅ Parcial | `searchBySerialInInstitution()` ya registra logs tipo `universal` |

### 1.3 Lo que falta implementar

| Componente | Estado | Descripción |
|------------|--------|-------------|
| Registro de escaneo directo | ❌ Falta | Al acceder a `/qr/:token` (tarjeta QR) no se registra el scan |
| Endpoint scan count por equipo | ❌ Falta | `GET /equipments/:id/scan-count` |
| Endpoint detalle de scans | ❌ Falta | `GET /equipments/:id/scan-logs` con paginación |
| Columna "Escaneos" en tabla admin | ❌ Falta | Mostrar cantidad clickeable en `front/pages/admin/equipos.js` |
| Modal/detalle de escaneos | ❌ Falta | Vista con IP, fecha, tipo, user agent |

---

## 2️⃣ IMPLEMENTACIÓN BACKEND

### 2.1 Registrar escaneo directo al acceder a tarjeta QR

**Opción A (recomendada): Endpoint dedicado llamado desde el frontend**

Crear un endpoint público `POST /qr/:token/scan` que el frontend llame al cargar la tarjeta QR.

**Archivo:** `src/qr/qr.controller.ts`

```typescript
/**
 * Registrar escaneo de QR (público)
 * POST /qr/:token/scan
 */
@Post(':token/scan')
@ApiOperation({ summary: 'Registrar escaneo de QR (público)' })
@ApiParam({ name: 'token', description: 'Token del código QR' })
@ApiResponse({ status: 201, description: 'Escaneo registrado' })
@ApiResponse({ status: 404, description: 'QR no encontrado' })
async registerScan(
  @Param('token') token: string,
  @Req() req: Request,
) {
  const qr = await this.qrService.findByToken(token);
  if (!qr) throw new NotFoundException('QR no encontrado');

  await this.qrScanLogService.create({
    qrCodeId: qr.id,
    ip: req.ip || req.socket?.remoteAddress || 'unknown',
    userAgent: req.headers['user-agent'] || 'unknown',
    searchType: 'direct',
  });

  return { success: true };
}
```

> **Nota:** Inyectar `QrScanLogService` en el constructor del `QrController`.

### 2.2 Obtener cantidad de escaneos por equipo

**Archivo:** `src/qr/qr-scan-log.service.ts` — agregar método:

```typescript
/**
 * Obtener conteo de escaneos para un equipo (a través de sus QR codes)
 */
async getCountByEquipmentId(equipmentId: number): Promise<number> {
  const result = await this.qrScanLogRepository
    .createQueryBuilder('log')
    .innerJoin('log.qrCode', 'qrCode')
    .where('qrCode.equipmentId = :equipmentId', { equipmentId })
    .andWhere('log.deletedAt IS NULL')
    .getCount();
  return result;
}

/**
 * Obtener conteos de escaneos para múltiples equipos en una sola query
 */
async getCountsByEquipmentIds(equipmentIds: number[]): Promise<Record<number, number>> {
  if (equipmentIds.length === 0) return {};

  const results = await this.qrScanLogRepository
    .createQueryBuilder('log')
    .innerJoin('log.qrCode', 'qrCode')
    .select('qrCode.equipmentId', 'equipmentId')
    .addSelect('COUNT(*)', 'total')
    .where('qrCode.equipmentId IN (:...equipmentIds)', { equipmentIds })
    .andWhere('log.deletedAt IS NULL')
    .groupBy('qrCode.equipmentId')
    .getRawMany();

  const map: Record<number, number> = {};
  for (const r of results) {
    map[Number(r.equipmentId)] = Number(r.total);
  }
  return map;
}

/**
 * Obtener logs de escaneo paginados por equipo
 */
async getLogsByEquipmentId(
  equipmentId: number,
  page: number = 1,
  limit: number = 20,
): Promise<{ data: QrScanLog[]; total: number; page: number; limit: number }> {
  const [data, total] = await this.qrScanLogRepository
    .createQueryBuilder('log')
    .innerJoin('log.qrCode', 'qrCode')
    .where('qrCode.equipmentId = :equipmentId', { equipmentId })
    .andWhere('log.deletedAt IS NULL')
    .orderBy('log.scannedAt', 'DESC')
    .skip((page - 1) * limit)
    .take(limit)
    .getManyAndCount();

  return { data, total, page, limit };
}
```

### 2.3 Nuevos endpoints en Equipment Controller

**Archivo:** `src/equipment/equipment.controller.ts` — agregar endpoints:

```typescript
/**
 * Obtener cantidad de escaneos por equipo
 * GET /equipments/:id/scan-count
 */
@UseGuards(JwtAuthGuard)
@Get(':id/scan-count')
@ApiCookieAuth('token')
@ApiOperation({ summary: 'Obtener cantidad de escaneos QR del equipo' })
@ApiParam({ name: 'id', description: 'ID del equipo' })
@ApiResponse({ status: 200, description: 'Cantidad de escaneos' })
async getScanCount(@Param('id') id: string) {
  const numId = parseInt(id, 10);
  if (isNaN(numId)) throw new NotFoundException('ID inválido');
  const count = await this.qrScanLogService.getCountByEquipmentId(numId);
  return { equipmentId: numId, scanCount: count };
}

/**
 * Obtener detalle de escaneos por equipo (paginado)
 * GET /equipments/:id/scan-logs?page=1&limit=20
 */
@UseGuards(JwtAuthGuard)
@Get(':id/scan-logs')
@ApiCookieAuth('token')
@ApiOperation({ summary: 'Obtener detalle de escaneos QR del equipo' })
@ApiParam({ name: 'id', description: 'ID del equipo' })
@ApiQuery({ name: 'page', required: false, type: Number })
@ApiQuery({ name: 'limit', required: false, type: Number })
@ApiResponse({ status: 200, description: 'Lista paginada de escaneos' })
async getScanLogs(
  @Param('id') id: string,
  @Query('page') page: string = '1',
  @Query('limit') limit: string = '20',
) {
  const numId = parseInt(id, 10);
  if (isNaN(numId)) throw new NotFoundException('ID inválido');
  return this.qrScanLogService.getLogsByEquipmentId(
    numId,
    parseInt(page, 10),
    parseInt(limit, 10),
  );
}

/**
 * Obtener conteo de escaneos en lote (para la tabla de equipos)
 * POST /equipments/scan-counts
 * Body: { equipmentIds: [1, 2, 3] }
 */
@UseGuards(JwtAuthGuard)
@Post('scan-counts')
@ApiCookieAuth('token')
@ApiOperation({ summary: 'Obtener conteo de escaneos en lote' })
@ApiBody({ schema: { properties: { equipmentIds: { type: 'array', items: { type: 'number' } } } } })
@ApiResponse({ status: 200, description: 'Mapa de equipmentId -> scanCount' })
async getScanCounts(@Body() body: { equipmentIds: number[] }) {
  const counts = await this.qrScanLogService.getCountsByEquipmentIds(body.equipmentIds);
  return counts;
}
```

> **Nota:** Inyectar `QrScanLogService` en el constructor del `EquipmentController`. Requiere que `QrModule` exporte `QrScanLogService` (ya lo hace).

### 2.4 Resumen de cambios backend

| Archivo | Acción | Detalle |
|---------|--------|---------|
| `src/qr/qr.controller.ts` | Modificar | Agregar endpoint `POST /qr/:token/scan`, inyectar `QrScanLogService` |
| `src/qr/qr-scan-log.service.ts` | Modificar | Agregar `getCountByEquipmentId()`, `getCountsByEquipmentIds()`, `getLogsByEquipmentId()` |
| `src/equipment/equipment.controller.ts` | Modificar | Agregar `GET :id/scan-count`, `GET :id/scan-logs`, `POST scan-counts`. Inyectar `QrScanLogService` |
| `src/equipment/equipment.module.ts` | Verificar | Asegurar que importa `QrModule` (ya lo hace con `forwardRef`) |

---

## 3️⃣ IMPLEMENTACIÓN FRONTEND

### 3.1 Registrar escaneo al cargar tarjeta QR

**Archivo:** `front/pages/qr/[token].js`

Al cargar la tarjeta QR, hacer un POST para registrar el escaneo. Usar `useEffect` al obtener los datos del QR:

```javascript
// Dentro del useEffect que carga datos del QR, después de obtener qrData:
// Registrar escaneo (fire-and-forget, no bloquear la UI)
fetch(`${process.env.NEXT_PUBLIC_API_URL}/qr/${token}/scan`, {
  method: 'POST',
  credentials: 'include',
}).catch(() => {}); // Ignorar errores silenciosamente
```

**Ubicación:** Dentro del `.then(async ([qrData, equipoData]) => { ... })` después de `setQr(qrData)`, aproximadamente en la línea 50 del archivo actual.

### 3.2 Columna "Escaneos" en tabla de equipos admin

**Archivo:** `front/pages/admin/equipos.js`

#### 3.2.1 Agregar state para mapa de escaneos

```javascript
const [scanMap, setScanMap] = useState({}); // { [equipoId]: scanCount }
```

#### 3.2.2 Obtener conteos en lote al cargar equipos

Dentro del `useEffect` que carga equipos, después de obtener `data`, agregar:

```javascript
// Obtener conteos de escaneos en lote
if (data.length > 0) {
  const equipmentIds = data.map(e => e.id);
  fetch(`${process.env.NEXT_PUBLIC_API_URL}/equipments/scan-counts`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'include',
    body: JSON.stringify({ equipmentIds }),
  })
    .then(res => res.ok ? res.json() : {})
    .then(counts => setScanMap(counts))
    .catch(() => {});
}
```

#### 3.2.3 Agregar columna en la tabla

En el `<thead>`, agregar después de la columna "QR":

```html
<th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Escaneos</th>
```

En el `<tbody>`, agregar después de la celda de QR:

```jsx
<td className="px-6 py-4 whitespace-nowrap text-center">
  <button
    onClick={() => handleOpenScanDetail(equipo.id, equipo.name)}
    className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-amber-50 text-amber-700 hover:bg-amber-100 text-sm font-bold transition cursor-pointer"
    title="Ver detalle de escaneos"
  >
    <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
      <path strokeLinecap="round" strokeLinejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
    </svg>
    {scanMap[equipo.id] || 0}
  </button>
</td>
```

### 3.3 Modal de detalle de escaneos

Agregar un modal que se muestra al hacer click en el conteo de escaneos.

#### 3.3.1 States adicionales

```javascript
const [scanDetailModal, setScanDetailModal] = useState(false);
const [scanDetailEquipo, setScanDetailEquipo] = useState(null);
const [scanLogs, setScanLogs] = useState([]);
const [scanLogsLoading, setScanLogsLoading] = useState(false);
const [scanLogsPage, setScanLogsPage] = useState(1);
const [scanLogsTotal, setScanLogsTotal] = useState(0);
```

#### 3.3.2 Función para abrir el modal

```javascript
const handleOpenScanDetail = async (equipmentId, equipmentName) => {
  setScanDetailEquipo({ id: equipmentId, name: equipmentName });
  setScanDetailModal(true);
  setScanLogsLoading(true);
  setScanLogsPage(1);
  try {
    const res = await fetch(
      `${process.env.NEXT_PUBLIC_API_URL}/equipments/${equipmentId}/scan-logs?page=1&limit=20`,
      { credentials: 'include' }
    );
    if (res.ok) {
      const result = await res.json();
      setScanLogs(result.data);
      setScanLogsTotal(result.total);
    }
  } catch {}
  setScanLogsLoading(false);
};
```

#### 3.3.3 Función para paginación

```javascript
const handleScanLogsPageChange = async (newPage) => {
  if (!scanDetailEquipo) return;
  setScanLogsLoading(true);
  setScanLogsPage(newPage);
  try {
    const res = await fetch(
      `${process.env.NEXT_PUBLIC_API_URL}/equipments/${scanDetailEquipo.id}/scan-logs?page=${newPage}&limit=20`,
      { credentials: 'include' }
    );
    if (res.ok) {
      const result = await res.json();
      setScanLogs(result.data);
      setScanLogsTotal(result.total);
    }
  } catch {}
  setScanLogsLoading(false);
};
```

#### 3.3.4 Componente del modal

```jsx
{/* Modal de detalle de escaneos */}
{scanDetailModal && (
  <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
    <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl max-h-[80vh] overflow-hidden flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between px-6 py-4 border-b">
        <div>
          <h2 className="text-lg font-bold text-gray-900">Escaneos QR</h2>
          <p className="text-sm text-gray-500">{scanDetailEquipo?.name} — {scanLogsTotal} escaneos totales</p>
        </div>
        <button onClick={() => setScanDetailModal(false)} className="text-gray-400 hover:text-gray-600">
          <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      {/* Tabla de logs */}
      <div className="overflow-auto flex-1 px-6 py-4">
        {scanLogsLoading ? (
          <p className="text-center text-gray-400 py-8">Cargando...</p>
        ) : scanLogs.length === 0 ? (
          <p className="text-center text-gray-400 py-8">No hay escaneos registrados</p>
        ) : (
          <table className="min-w-full text-sm">
            <thead>
              <tr className="text-left text-xs text-gray-500 uppercase">
                <th className="pb-2">Fecha</th>
                <th className="pb-2">Tipo</th>
                <th className="pb-2">IP</th>
                <th className="pb-2">Búsqueda</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {scanLogs.map(log => (
                <tr key={log.id} className="hover:bg-gray-50">
                  <td className="py-2 pr-4">{new Date(log.scannedAt).toLocaleString('es-CL')}</td>
                  <td className="py-2 pr-4">
                    <span className={`px-2 py-0.5 rounded-full text-xs font-bold ${
                      log.searchType === 'direct'
                        ? 'bg-blue-100 text-blue-700'
                        : 'bg-purple-100 text-purple-700'
                    }`}>
                      {log.searchType === 'direct' ? 'Directo' : 'Universal'}
                    </span>
                  </td>
                  <td className="py-2 pr-4 text-gray-500 font-mono text-xs">{log.ip}</td>
                  <td className="py-2 text-gray-500">{log.searchQuery || '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Paginación */}
      {scanLogsTotal > 20 && (
        <div className="flex items-center justify-between px-6 py-3 border-t bg-gray-50">
          <span className="text-xs text-gray-500">
            Página {scanLogsPage} de {Math.ceil(scanLogsTotal / 20)}
          </span>
          <div className="flex gap-2">
            <button
              disabled={scanLogsPage <= 1}
              onClick={() => handleScanLogsPageChange(scanLogsPage - 1)}
              className="px-3 py-1 text-sm rounded bg-gray-200 hover:bg-gray-300 disabled:opacity-50"
            >Anterior</button>
            <button
              disabled={scanLogsPage >= Math.ceil(scanLogsTotal / 20)}
              onClick={() => handleScanLogsPageChange(scanLogsPage + 1)}
              className="px-3 py-1 text-sm rounded bg-gray-200 hover:bg-gray-300 disabled:opacity-50"
            >Siguiente</button>
          </div>
        </div>
      )}
    </div>
  </div>
)}
```

### 3.4 Resumen de cambios frontend

| Archivo | Acción | Detalle |
|---------|--------|---------|
| `front/pages/qr/[token].js` | Modificar | Agregar `POST /qr/:token/scan` al cargar tarjeta (fire-and-forget) |
| `front/pages/admin/equipos.js` | Modificar | Agregar columna "Escaneos", estado `scanMap`, llamada a `POST /equipments/scan-counts`, modal de detalle con paginación |
| `front/services/api.js` | Opcional | Agregar métodos `getScanCounts()` y `getScanLogs()` al `equipmentApi` |

---

## 4️⃣ ORDEN DE IMPLEMENTACIÓN

### Paso 1: Backend — Métodos en QrScanLogService
1. Agregar `getCountByEquipmentId()` en `src/qr/qr-scan-log.service.ts`
2. Agregar `getCountsByEquipmentIds()` en `src/qr/qr-scan-log.service.ts`
3. Agregar `getLogsByEquipmentId()` en `src/qr/qr-scan-log.service.ts`

### Paso 2: Backend — Endpoint registro de escaneo directo
4. Inyectar `QrScanLogService` en `QrController`
5. Agregar endpoint `POST /qr/:token/scan` en `src/qr/qr.controller.ts`

### Paso 3: Backend — Endpoints de consulta en Equipment
6. Inyectar `QrScanLogService` en `EquipmentController`
7. Agregar `GET /equipments/:id/scan-count` en `src/equipment/equipment.controller.ts`
8. Agregar `GET /equipments/:id/scan-logs` en `src/equipment/equipment.controller.ts`
9. Agregar `POST /equipments/scan-counts` en `src/equipment/equipment.controller.ts`

### Paso 4: Frontend — Registro de escaneo
10. Modificar `front/pages/qr/[token].js` para llamar a `POST /qr/:token/scan`

### Paso 5: Frontend — Tabla de equipos con escaneos
11. Agregar state `scanMap` y fetch de conteos en `front/pages/admin/equipos.js`
12. Agregar columna "Escaneos" en la tabla
13. Implementar modal de detalle con paginación

### Paso 6: Pruebas
14. Verificar que al acceder a `/qr/:token` se registra un scan en `qr_scan_logs`
15. Verificar que la tabla de equipos muestra conteos correctos
16. Verificar que el modal muestra el detalle paginado
17. Verificar que las búsquedas universales siguen registrándose correctamente

---

## 5️⃣ ENDPOINTS API RESULTANTES

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| `POST` | `/qr/:token/scan` | Público | Registrar escaneo de QR |
| `GET` | `/equipments/:id/scan-count` | JWT | Obtener cantidad de escaneos del equipo |
| `GET` | `/equipments/:id/scan-logs?page=1&limit=20` | JWT | Obtener detalle paginado de escaneos |
| `POST` | `/equipments/scan-counts` | JWT | Obtener conteos en lote `{ equipmentIds: [...] }` |

---

## 6️⃣ CONSIDERACIONES

- **Rendimiento:** Usar `POST /equipments/scan-counts` en lote en lugar de N llamadas individuales para la tabla de equipos.
- **Fire-and-forget:** El registro de escaneo desde el frontend no debe bloquear la carga de la tarjeta QR. Ignorar errores silenciosamente.
- **Privacidad:** La IP y user agent son datos personales. Considerar política de retención de datos.

---

## 7️⃣ SEGURIDAD Y DEDUPLICACIÓN DE ESCANEOS

### 7.1 Problema

El endpoint `POST /qr/:token/scan` es **público** (no requiere JWT). Sin protección:
- Un usuario que recarga la página genera múltiples registros idénticos.
- Un bot puede hacer miles de requests inflando los conteos artificialmente.

### 7.2 Solución implementada (doble capa)

#### Capa 1 — Rate limiter por IP (anti-bot)

**Ubicación:** `src/qr/qr.controller.ts` — función `checkScanRateLimit()`

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| Máx. requests | 20 | Requests permitidos por ventana |
| Ventana | 1 minuto | Cada IP puede hacer máx 20 POST/min |
| Respuesta si excede | `429 Too Many Requests` | El frontend lo ignora (fire-and-forget) |
| Almacenamiento | `Map` en memoria | Se limpia cada 5 minutos |

**Flujo:**
1. Llega `POST /qr/:token/scan` desde IP `X`.
2. Se busca `X` en el `Map`. Si no existe o la ventana expiró → `count = 1`, permitir.
3. Si `count < 20` → `count++`, permitir.
4. Si `count >= 20` → retornar HTTP 429 (bloqueo temporal).
5. Cada 5 minutos un `setInterval` borra entradas expiradas del `Map`.

```
IP 192.168.1.1 → req #1 ✅ → req #2 ✅ → ... → req #20 ✅ → req #21 ❌ 429
                                                              (esperar 1 min)
```

> **Nota:** En entornos con múltiples instancias (cluster), el rate limiter es por proceso. Para escalar, migrar a Redis.

#### Capa 2 — Deduplicación por IP + QR (10 minutos)

**Ubicación:** `src/qr/qr-scan-log.service.ts` — método `existsRecentScan()`

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| Ventana dedup | 10 minutos | Misma IP + mismo QR → no duplicar |
| Consulta | `SELECT` en `qr_scan_logs` | Busca registro donde `ip = X AND qr_code_id = Y AND scanned_at > (now - 10min)` |
| Índice aprovechado | `idx_qr_scan_logs_ip` + `qr_code_id` | Consulta rápida |

**Flujo dentro de `create()`:**
1. Antes de insertar, ejecutar `existsRecentScan(qrCodeId, ip)`.
2. Si existe registro reciente → retornar `null` (no insertar, no error).
3. Si no existe → insertar normalmente.

```
Usuario escanea QR a las 10:00 → ✅ INSERT (primer registro)
Usuario recarga a las 10:02    → ❌ null (dedup, ya hay registro a las 10:00)
Usuario recarga a las 10:11    → ✅ INSERT (pasaron >10 min)
```

### 7.3 Diagrama de flujo completo

```
POST /qr/:token/scan
        │
        ▼
┌─────────────────┐
│ Rate limit IP?  │──── count >= 20 ──→ HTTP 429
│ (20 req/min)    │
└───────┬─────────┘
        │ OK
        ▼
┌─────────────────┐
│ QR existe?      │──── no ──→ HTTP 404
└───────┬─────────┘
        │ sí
        ▼
┌─────────────────────────┐
│ Existe scan reciente    │──── sí ──→ { success: true } (silencioso, sin INSERT)
│ misma IP + QR < 10 min? │
└───────┬─────────────────┘
        │ no
        ▼
   INSERT en qr_scan_logs
        │
        ▼
   { success: true }
```

### 7.4 Configuración

Los valores se pueden ajustar directamente en el código:

| Archivo | Constante | Valor actual | Descripción |
|---------|-----------|-------------|-------------|
| `qr.controller.ts` | `RATE_LIMIT_MAX` | `20` | Máx requests por ventana |
| `qr.controller.ts` | `RATE_LIMIT_WINDOW_MS` | `60_000` (1 min) | Ventana de rate limit |
| `qr-scan-log.service.ts` | `windowMinutes` param | `10` | Ventana de deduplicación |

### 7.5 Impacto en el frontend

El frontend ya maneja ambos escenarios correctamente gracias al patrón **fire-and-forget**:

```javascript
// front/pages/qr/[token].js — no se bloquea ante 429 ni ante dedup
fetch(`${process.env.NEXT_PUBLIC_API_URL}/qr/${token}/scan`, {
  method: 'POST',
  credentials: 'include',
}).catch(() => {}); // Ignora errores silenciosamente
```

- Si recibe **429** → `.catch()` lo absorbe, la tarjeta QR carga normalmente.
- Si el backend deduplica → responde `{ success: true }` sin insertar, transparente.
