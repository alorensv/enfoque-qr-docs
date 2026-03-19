-- ============================================
-- Migración: Eliminar tabla codigo_qr
-- Fecha: 2026-02-23
-- Descripción: Consolidar toda la funcionalidad de QR en equipment_qr_codes
-- ============================================

-- PASO 1: Agregar columnas a equipment_qr_codes
ALTER TABLE `equipment_qr_codes`
ADD COLUMN `url_publica` VARCHAR(255) NULL DEFAULT NULL AFTER `equipment_id`,
ADD COLUMN `imagen_path` VARCHAR(255) NULL DEFAULT NULL AFTER `url_publica`;

-- PASO 2: Migrar datos de codigo_qr a equipment_qr_codes
-- Actualizar los registros existentes en equipment_qr_codes con los datos de codigo_qr
UPDATE `equipment_qr_codes` eqc
INNER JOIN `codigo_qr` cqr ON eqc.token = cqr.token
SET 
    eqc.url_publica = cqr.url_publica,
    eqc.imagen_path = cqr.imagen_path
WHERE cqr.deleted_at IS NULL;

-- PASO 3: Verificar datos migrados (EJECUTAR ANTES DE ELIMINAR)
-- SELECT 
--     eqc.id,
--     eqc.token,
--     eqc.url_publica,
--     eqc.imagen_path,
--     eqc.equipment_id,
--     cqr.url_publica as old_url,
--     cqr.imagen_path as old_imagen
-- FROM equipment_qr_codes eqc
-- LEFT JOIN codigo_qr cqr ON eqc.token = cqr.token
-- ORDER BY eqc.id DESC
-- LIMIT 20;

-- PASO 4: Eliminar tabla codigo_qr (SOLO DESPUÉS DE VERIFICAR)
-- DROP TABLE IF EXISTS `codigo_qr`;

-- ============================================
-- ROLLBACK (en caso de necesitar revertir)
-- ============================================
-- ALTER TABLE `equipment_qr_codes`
-- DROP COLUMN `url_publica`,
-- DROP COLUMN `imagen_path`;
