-- =============================================================================
-- CONSULTAS SQL PARA OBTENER TODO EL DETALLE DE UN EQUIPO
-- =============================================================================
-- Este archivo contiene consultas para obtener toda la información relacionada
-- con un equipo, incluyendo documentos, mantenciones, logs, códigos QR, etc.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. INFORMACIÓN BÁSICA DEL EQUIPO
-- -----------------------------------------------------------------------------
-- Obtiene datos principales del equipo junto con su institución
SELECT 
    e.id,
    e.name,
    e.serial_number,
    e.equipment_photo,
    e.description,
    e.status,
    e.institution_id,
    e.created_at,
    e.updated_at,
    e.deleted_at,
    i.id as institution_id,
    i.name as institution_name,
    i.created_at as institution_created_at
FROM equipments e
LEFT JOIN institutions i ON e.institution_id = i.id
WHERE e.id = ? AND e.deleted_at IS NULL;

-- -----------------------------------------------------------------------------
-- 2. CÓDIGOS QR DEL EQUIPO
-- -----------------------------------------------------------------------------
-- Obtiene todos los códigos QR asignados al equipo
SELECT 
    qr.id,
    qr.token,
    qr.equipment_id,
    qr.url_publica,
    qr.imagen_path,
    qr.enabled,
    qr.assigned_at,
    qr.revoked_at,
    qr.created_at,
    qr.updated_at,
    qr.deleted_at
FROM equipment_qr_codes qr
WHERE qr.equipment_id = ? 
    AND qr.deleted_at IS NULL
ORDER BY qr.created_at DESC;

-- -----------------------------------------------------------------------------
-- 3. LOGS DE ESCANEO QR
-- -----------------------------------------------------------------------------
-- Obtiene los logs de escaneo de los códigos QR del equipo
SELECT 
    qsl.id,
    qsl.qr_code_id,
    qsl.ip,
    qsl.user_agent,
    qsl.scanned_at,
    qr.token as qr_token,
    qr.url_publica
FROM qr_scan_logs qsl
INNER JOIN equipment_qr_codes qr ON qsl.qr_code_id = qr.id
WHERE qr.equipment_id = ? 
    AND qsl.deleted_at IS NULL
ORDER BY qsl.scanned_at DESC;

-- -----------------------------------------------------------------------------
-- 4. DOCUMENTOS DEL EQUIPO
-- -----------------------------------------------------------------------------
-- Obtiene todos los documentos asociados al equipo
SELECT 
    ed.id,
    ed.equipment_id,
    ed.user_id,
    ed.name,
    ed.original_name,
    ed.type,
    ed.file_path,
    ed.is_private,
    ed.created_at,
    ed.updated_at,
    ed.deleted_at,
    u.username as uploaded_by_username,
    u.email as uploaded_by_email,
    up.full_name as uploaded_by_full_name
FROM equipment_documents ed
LEFT JOIN users u ON ed.user_id = u.id
LEFT JOIN user_profiles up ON u.id = up.user_id
WHERE ed.equipment_id = ? 
    AND ed.deleted_at IS NULL
ORDER BY ed.created_at DESC;

-- -----------------------------------------------------------------------------
-- 5. MANTENCIONES DEL EQUIPO
-- -----------------------------------------------------------------------------
-- Obtiene todas las mantenciones del equipo con datos del usuario
SELECT 
    em.id,
    em.equipment_id,
    em.user_id,
    em.description,
    em.performed_at,
    em.technician,
    em.status,
    em.created_at,
    em.updated_at,
    em.deleted_at,
    u.username as created_by_username,
    u.email as created_by_email,
    up.full_name as created_by_full_name
FROM equipment_maintenances em
LEFT JOIN users u ON em.user_id = u.id
LEFT JOIN user_profiles up ON u.id = up.user_id
WHERE em.equipment_id = ? 
    AND em.deleted_at IS NULL
ORDER BY em.performed_at DESC, em.created_at DESC;

-- -----------------------------------------------------------------------------
-- 6. FOTOS DE MANTENCIONES
-- -----------------------------------------------------------------------------
-- Obtiene todas las fotos de las mantenciones de un equipo
SELECT 
    emp.id,
    emp.maintenance_id,
    emp.file_path,
    emp.uploaded_at,
    em.description as maintenance_description,
    em.performed_at as maintenance_performed_at
FROM equipment_maintenance_photos emp
INNER JOIN equipment_maintenances em ON emp.maintenance_id = em.id
WHERE em.equipment_id = ? 
    AND em.deleted_at IS NULL
ORDER BY emp.uploaded_at DESC;

-- -----------------------------------------------------------------------------
-- 7. DOCUMENTOS DE MANTENCIONES
-- -----------------------------------------------------------------------------
-- Obtiene todos los documentos de las mantenciones de un equipo
SELECT 
    emd.id,
    emd.maintenance_id,
    emd.name,
    emd.file_path,
    emd.uploaded_at,
    em.description as maintenance_description,
    em.performed_at as maintenance_performed_at
FROM equipment_maintenance_documents emd
INNER JOIN equipment_maintenances em ON emd.maintenance_id = em.id
WHERE em.equipment_id = ? 
    AND em.deleted_at IS NULL
ORDER BY emd.uploaded_at DESC;

-- -----------------------------------------------------------------------------
-- 8. LOGS DE MANTENCIONES
-- -----------------------------------------------------------------------------
-- Obtiene todos los logs de las mantenciones de un equipo
SELECT 
    eml.id,
    eml.maintenance_id,
    eml.user_id,
    eml.action,
    eml.description,
    eml.created_at,
    em.description as maintenance_description,
    em.performed_at as maintenance_performed_at,
    u.username as user_username,
    u.email as user_email,
    up.full_name as user_full_name
FROM equipment_maintenance_logs eml
INNER JOIN equipment_maintenances em ON eml.maintenance_id = em.id
LEFT JOIN users u ON eml.user_id = u.id
LEFT JOIN user_profiles up ON u.id = up.user_id
WHERE em.equipment_id = ? 
    AND em.deleted_at IS NULL
ORDER BY eml.created_at DESC;

-- -----------------------------------------------------------------------------
-- 9. RESUMEN COMPLETO DEL EQUIPO
-- -----------------------------------------------------------------------------
-- Obtiene un resumen con contadores de elementos relacionados
SELECT 
    e.id,
    e.name,
    e.serial_number,
    e.equipment_photo,
    e.description,
    e.status,
    e.institution_id,
    i.name as institution_name,
    e.created_at,
    e.updated_at,
    -- Contadores
    COUNT(DISTINCT qr.id) as total_qr_codes,
    COUNT(DISTINCT CASE WHEN qr.enabled = 1 THEN qr.id END) as active_qr_codes,
    COUNT(DISTINCT ed.id) as total_documents,
    COUNT(DISTINCT em.id) as total_maintenances,
    COUNT(DISTINCT emp.id) as total_maintenance_photos,
    COUNT(DISTINCT emd.id) as total_maintenance_documents,
    COUNT(DISTINCT eml.id) as total_maintenance_logs,
    COUNT(DISTINCT qsl.id) as total_qr_scans,
    -- Fechas relevantes
    MAX(qsl.scanned_at) as last_qr_scan,
    MAX(em.performed_at) as last_maintenance_date,
    MAX(em.created_at) as last_maintenance_created
FROM equipments e
LEFT JOIN institutions i ON e.institution_id = i.id
LEFT JOIN equipment_qr_codes qr ON e.id = qr.equipment_id AND qr.deleted_at IS NULL
LEFT JOIN equipment_documents ed ON e.id = ed.equipment_id AND ed.deleted_at IS NULL
LEFT JOIN equipment_maintenances em ON e.id = em.equipment_id AND em.deleted_at IS NULL
LEFT JOIN equipment_maintenance_photos emp ON em.id = emp.maintenance_id
LEFT JOIN equipment_maintenance_documents emd ON em.id = emd.maintenance_id
LEFT JOIN equipment_maintenance_logs eml ON em.id = eml.maintenance_id
LEFT JOIN qr_scan_logs qsl ON qr.id = qsl.qr_code_id AND qsl.deleted_at IS NULL
WHERE e.id = ? AND e.deleted_at IS NULL
GROUP BY e.id;

-- -----------------------------------------------------------------------------
-- 10. DETALLE COMPLETO DE UNA MANTENCIÓN ESPECÍFICA
-- -----------------------------------------------------------------------------
-- Obtiene todos los detalles de una mantención en particular
SELECT 
    em.id,
    em.equipment_id,
    em.user_id,
    em.description,
    em.performed_at,
    em.technician,
    em.status,
    em.created_at,
    em.updated_at,
    -- Datos del equipo
    e.name as equipment_name,
    e.serial_number as equipment_serial,
    -- Datos del usuario creador
    u.username as created_by_username,
    u.email as created_by_email,
    up.full_name as created_by_full_name,
    -- Contadores
    COUNT(DISTINCT emp.id) as total_photos,
    COUNT(DISTINCT emd.id) as total_documents,
    COUNT(DISTINCT eml.id) as total_logs
FROM equipment_maintenances em
LEFT JOIN equipments e ON em.equipment_id = e.id
LEFT JOIN users u ON em.user_id = u.id
LEFT JOIN user_profiles up ON u.id = up.user_id
LEFT JOIN equipment_maintenance_photos emp ON em.id = emp.maintenance_id
LEFT JOIN equipment_maintenance_documents emd ON em.id = emd.maintenance_id
LEFT JOIN equipment_maintenance_logs eml ON em.id = eml.maintenance_id
WHERE em.id = ? AND em.deleted_at IS NULL
GROUP BY em.id;

-- -----------------------------------------------------------------------------
-- 11. HISTORIAL COMPLETO DE ACTIVIDAD DEL EQUIPO
-- -----------------------------------------------------------------------------
-- Obtiene un timeline unificado de todas las actividades del equipo
SELECT 
    'EQUIPMENT_CREATED' as activity_type,
    e.id as equipment_id,
    NULL as related_id,
    'Equipo creado' as activity_description,
    NULL as user_id,
    NULL as username,
    e.created_at as activity_date
FROM equipments e
WHERE e.id = ?

UNION ALL

SELECT 
    'QR_ASSIGNED' as activity_type,
    qr.equipment_id,
    qr.id as related_id,
    CONCAT('Código QR asignado: ', qr.token) as activity_description,
    NULL as user_id,
    NULL as username,
    qr.assigned_at as activity_date
FROM equipment_qr_codes qr
WHERE qr.equipment_id = ? AND qr.assigned_at IS NOT NULL AND qr.deleted_at IS NULL

UNION ALL

SELECT 
    'QR_SCANNED' as activity_type,
    qr.equipment_id,
    qsl.id as related_id,
    CONCAT('QR escaneado desde IP: ', COALESCE(qsl.ip, 'desconocida')) as activity_description,
    NULL as user_id,
    NULL as username,
    qsl.scanned_at as activity_date
FROM qr_scan_logs qsl
INNER JOIN equipment_qr_codes qr ON qsl.qr_code_id = qr.id
WHERE qr.equipment_id = ? AND qsl.deleted_at IS NULL

UNION ALL

SELECT 
    'DOCUMENT_UPLOADED' as activity_type,
    ed.equipment_id,
    ed.id as related_id,
    CONCAT('Documento subido: ', ed.name) as activity_description,
    ed.user_id,
    u.username,
    ed.created_at as activity_date
FROM equipment_documents ed
LEFT JOIN users u ON ed.user_id = u.id
WHERE ed.equipment_id = ? AND ed.deleted_at IS NULL

UNION ALL

SELECT 
    'MAINTENANCE_CREATED' as activity_type,
    em.equipment_id,
    em.id as related_id,
    CONCAT('Mantención registrada', COALESCE(CONCAT(' - ', em.technician), '')) as activity_description,
    em.user_id,
    u.username,
    em.created_at as activity_date
FROM equipment_maintenances em
LEFT JOIN users u ON em.user_id = u.id
WHERE em.equipment_id = ? AND em.deleted_at IS NULL

UNION ALL

SELECT 
    'MAINTENANCE_LOG' as activity_type,
    em.equipment_id,
    eml.id as related_id,
    CONCAT('Log de mantención: ', eml.action) as activity_description,
    eml.user_id,
    u.username,
    eml.created_at as activity_date
FROM equipment_maintenance_logs eml
INNER JOIN equipment_maintenances em ON eml.maintenance_id = em.id
LEFT JOIN users u ON eml.user_id = u.id
WHERE em.equipment_id = ? AND em.deleted_at IS NULL

ORDER BY activity_date DESC;

-- =============================================================================
-- NOTAS DE USO:
-- =============================================================================
-- Reemplazar el símbolo ? con el ID del equipo que se desea consultar
-- Ejemplo: WHERE e.id = 1 (en lugar de WHERE e.id = ?)
--
-- Para MySQL/MariaDB usar parámetros preparados con el símbolo ?
-- Para PostgreSQL usar $1, $2, etc.
-- =============================================================================
