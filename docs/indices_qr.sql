-- Script SQL para optimizar la tabla equipment_qr_codes
-- Ejecutar después de verificar que la tabla existe

-- Índices para mejorar performance en búsquedas
CREATE INDEX IF NOT EXISTS idx_equipment_id ON equipment_qr_codes(equipment_id);
CREATE INDEX IF NOT EXISTS idx_enabled ON equipment_qr_codes(enabled);
CREATE INDEX IF NOT EXISTS idx_assigned_at ON equipment_qr_codes(assigned_at);
CREATE INDEX IF NOT EXISTS idx_token ON equipment_qr_codes(token);
CREATE INDEX IF NOT EXISTS idx_batch_id ON equipment_qr_codes(batch_id);

-- Índice compuesto para búsqueda de QR disponibles
CREATE INDEX IF NOT EXISTS idx_available_qr 
ON equipment_qr_codes(equipment_id, enabled, revoked_at);

-- Verificar índices creados
SHOW INDEX FROM equipment_qr_codes;
