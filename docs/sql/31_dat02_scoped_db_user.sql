-- =============================================================================
-- MIGRACIÓN: usuario de BD acotado a DML (DAT-02)
-- =============================================================================
-- synchronize está en false (ver CLAUDE.md) — este script se aplica a mano,
-- por SSH como root, cuando se decida desplegar (ver el flujo del proyecto).
--
-- POR QUÉ: `enfoque` (el usuario que usa la app en producción) tiene
-- GRANT ALL PRIVILEGES sobre `enfoqueqr` — incluye DDL (CREATE/DROP/ALTER/
-- INDEX) que el runtime nunca usa (`synchronize:false`, sin una sola
-- sentencia DDL en el código; las migraciones se aplican a mano por SSH como
-- root, nunca con las credenciales de la app). Si esas credenciales alguna
-- vez se filtran (variable de entorno expuesta, log, etc.), hoy un atacante
-- podría alterar el esquema entero, no solo leer/escribir filas.
--
-- Reemplazo: `enfoqueqr_app`, solo SELECT/INSERT/UPDATE/DELETE — el mínimo
-- que el runtime necesita, verificado corriendo la suite e2e completa contra
-- él antes de aplicar esto en producción.
--
-- ORDEN DE CORTE (no hacerlo todo de una): crear el usuario nuevo, cambiar
-- DB_USER/DB_PASS en Vercel, verificar tráfico real, y SOLO DESPUÉS revocar
-- privilegios del usuario `enfoque` viejo (o dejarlo sin uso) — nunca tocar
-- el usuario en producción mientras algo todavía lo esté usando.
-- =============================================================================

CREATE USER IF NOT EXISTS 'enfoqueqr_app'@'%' IDENTIFIED BY '__REEMPLAZAR_CON_PASSWORD_FUERTE__';
GRANT SELECT, INSERT, UPDATE, DELETE ON enfoqueqr.* TO 'enfoqueqr_app'@'%';
FLUSH PRIVILEGES;

-- Verificación:
--   SHOW GRANTS FOR 'enfoqueqr_app'@'%';
-- Debe mostrar exactamente SELECT, INSERT, UPDATE, DELETE — nada de CREATE,
-- DROP, ALTER, INDEX, REFERENCES, etc.

-- Paso posterior, SOLO cuando Vercel ya esté usando 'enfoqueqr_app' en
-- producción y se haya verificado con tráfico real (no ejecutar junto con lo
-- de arriba):
--   REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'enfoque'@'%';
--   GRANT SELECT, INSERT, UPDATE, DELETE ON enfoqueqr.* TO 'enfoque'@'%';
--   -- (se deja 'enfoque' vivo con el mismo alcance acotado, no se borra el
--   -- usuario — evita romper cualquier conexión que todavía lo referencie
--   -- por nombre, ej. un script de operación olvidado).
