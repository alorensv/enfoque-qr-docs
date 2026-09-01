-- =============================================================================
-- MIGRACIÓN: kv_store — estado compartido entre instancias (AUT-01 / AUT-02)
-- =============================================================================
-- synchronize está en false (ver CLAUDE.md) — este script se aplica a mano,
-- primero en local/dev, y en producción solo cuando el feature esté listo
-- para desplegarse (ver el flujo rama → preview → producción del proyecto).
--
-- POR QUÉ: en Vercel serverless cada instancia tiene su propia memoria, así que
-- la denylist de revocación de tokens (logout) no se veía entre instancias: un
-- token seguía siendo válido en cualquier lambda que no hubiera atendido el
-- logout. Esta tabla da ese estado compartido SIN sumar infraestructura nueva
-- (Redis/Upstash), reusando la MariaDB que ya está en producción con TLS y
-- backups diarios.
--
-- Solo la usan caminos FRÍOS (logout, /auth/refresh, intentos fallidos de
-- login). El rate limit por IP sigue en memoria por instancia a propósito: es
-- control anti-abuso, no frontera de seguridad, y no justifica un write a BD
-- en cada escaneo público de QR.
-- =============================================================================

CREATE TABLE IF NOT EXISTS kv_store (
  -- 191 chars: límite seguro para índice utf8mb4 en InnoDB.
  k          VARCHAR(191) NOT NULL,
  -- Contador para ventanas de rate limit / intentos fallidos. Las claves de
  -- denylist no lo usan (queda en 1).
  n          BIGINT NOT NULL DEFAULT 0,
  -- Vencimiento. Las lecturas descartan filas vencidas, así que una fila
  -- expirada equivale a inexistente aunque todavía no se haya barrido.
  expires_at DATETIME(3) NOT NULL,
  PRIMARY KEY (k),
  KEY idx_kv_store_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Barrido de filas vencidas. La app lo corre periódicamente mientras la
-- instancia está tibia, pero en serverless eso no está garantizado: dejar
-- también esta línea en el cron diario de la VM, junto al mysqldump de DAT-04.
--   DELETE FROM kv_store WHERE expires_at < NOW(3);
