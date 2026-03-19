# Configuración de Apariencia por Institución

## Objetivo
Permitir que la plataforma se personalice visualmente (colores, logos) según la institución del usuario que ha iniciado sesión o la institución a la que pertenece un equipo.

## Solución Propuesta
Se recomienda crear una nueva tabla llamada `institution_settings` en lugar de agregar columnas a la tabla `institutions`. Esta aproximación ofrece mayor escalabilidad y mantiene la estructura de la base de datos más organizada.

### Ventajas de una tabla `institution_settings`:
1.  **Escalabilidad:** Facilita la adición de nuevas opciones de personalización en el futuro (ej. `logo_url`, `font_family`, `favicon_url`) sin alterar la tabla principal de instituciones.
2.  **Organización:** Separa claramente los datos de identificación de la institución de sus configuraciones de apariencia, siguiendo el principio de responsabilidad única.
3.  **Rendimiento:** Las consultas que solo requieren datos básicos de la institución (como su nombre) no se verán sobrecargadas con datos de configuración que no son necesarios en ese contexto.

---

## Estructura de la Base de Datos

Se creará una nueva tabla `institution_settings` con una relación uno a uno con la tabla `institutions`.

### Script SQL

```sql
-- Crear la nueva tabla para configuraciones de la institución
CREATE TABLE IF NOT EXISTS `institution_settings` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `institution_id` bigint unsigned NOT NULL,
  `primary_color` VARCHAR(7) NULL DEFAULT '#000000' COMMENT 'Color principal en formato hexadecimal',
  `secondary_color` VARCHAR(7) NULL DEFAULT '#FFFFFF' COMMENT 'Color secundario en formato hexadecimal',
  `logo_url` VARCHAR(255) NULL COMMENT 'URL del logo de la institución',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `institution_id` (`institution_id`),
  CONSTRAINT `institution_settings_ibfk_1` FOREIGN KEY (`institution_id`) REFERENCES `institutions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

### Consideraciones
-   La relación `institution_id` es `UNIQUE` para asegurar que cada institución tenga como máximo un registro de configuración.
-   Se utiliza `ON DELETE CASCADE` para que, si una institución es eliminada, su configuración asociada también se elimine automáticamente, manteniendo la integridad de los datos.
-   Se han añadido valores por defecto para los colores para asegurar que siempre haya un fallback visual.