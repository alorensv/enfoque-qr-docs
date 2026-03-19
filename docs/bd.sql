-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Versión del servidor:         8.0.45 - MySQL Community Server - GPL
-- SO del servidor:              Linux
-- HeidiSQL Versión:             12.10.0.7000
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- Volcando estructura para tabla enfoqueqr.equipments
CREATE TABLE IF NOT EXISTS `equipments` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `serial_number` varchar(255) DEFAULT NULL,
  `equipment_photo` varchar(255) DEFAULT NULL,
  `description` text,
  `status` varchar(50) DEFAULT NULL,
  `institution_id` bigint unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `institution_id` (`institution_id`),
  KEY `idx_equipments_name` (`name`),
  KEY `idx_equipments_serial_number` (`serial_number`),
  KEY `idx_equipments_status` (`status`),
  KEY `idx_equipments_institution_status` (`institution_id`,`status`),
  KEY `idx_equipments_created_at` (`created_at`),
  CONSTRAINT `equipments_ibfk_1` FOREIGN KEY (`institution_id`) REFERENCES `institutions` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla enfoqueqr.equipment_documents
CREATE TABLE IF NOT EXISTS `equipment_documents` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `equipment_id` bigint unsigned NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `original_name` varchar(255) DEFAULT NULL,
  `type` varchar(100) DEFAULT NULL,
  `file_path` varchar(255) NOT NULL,
  `is_private` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `equipment_id` (`equipment_id`),
  KEY `user_id` (`user_id`),
  KEY `idx_equipment_documents_name` (`name`),
  KEY `idx_equipment_documents_type` (`type`),
  KEY `idx_equipment_documents_created_at` (`created_at`),
  KEY `idx_equipment_documents_equipment_user` (`equipment_id`,`user_id`),
  CONSTRAINT `equipment_documents_ibfk_1` FOREIGN KEY (`equipment_id`) REFERENCES `equipments` (`id`),
  CONSTRAINT `equipment_documents_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla enfoqueqr.equipment_document_versions
CREATE TABLE IF NOT EXISTS `equipment_document_versions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `document_id` bigint unsigned NOT NULL,
  `version` int NOT NULL,
  `file_path` varchar(255) NOT NULL,
  `checksum` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `document_id` (`document_id`),
  KEY `idx_equipment_document_versions_version` (`version`),
  KEY `idx_equipment_document_versions_created_at` (`created_at`),
  CONSTRAINT `equipment_document_versions_ibfk_1` FOREIGN KEY (`document_id`) REFERENCES `equipment_documents` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla enfoqueqr.equipment_maintenances
CREATE TABLE IF NOT EXISTS `equipment_maintenances` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `equipment_id` bigint unsigned NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `description` text,
  `performed_at` date DEFAULT NULL,
  `technician` varchar(255) DEFAULT NULL,
  `status` varchar(50) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `equipment_id` (`equipment_id`),
  KEY `user_id` (`user_id`),
  KEY `idx_equipment_maintenances_status` (`status`),
  KEY `idx_equipment_maintenances_performed_at` (`performed_at`),
  KEY `idx_equipment_maintenances_equipment_user` (`equipment_id`,`user_id`),
  CONSTRAINT `equipment_maintenances_ibfk_1` FOREIGN KEY (`equipment_id`) REFERENCES `equipments` (`id`),
  CONSTRAINT `equipment_maintenances_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla enfoqueqr.equipment_maintenance_documents
CREATE TABLE IF NOT EXISTS `equipment_maintenance_documents` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `maintenance_id` bigint unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `file_path` varchar(255) NOT NULL,
  `uploaded_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `maintenance_id` (`maintenance_id`),
  KEY `idx_maintenance_documents_uploaded_at` (`uploaded_at`),
  KEY `idx_maintenance_documents_maintenance_uploaded` (`maintenance_id`,`uploaded_at`),
  KEY `idx_maintenance_documents_name` (`name`),
  CONSTRAINT `equipment_maintenance_documents_ibfk_1` FOREIGN KEY (`maintenance_id`) REFERENCES `equipment_maintenances` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla enfoqueqr.equipment_maintenance_logs
CREATE TABLE IF NOT EXISTS `equipment_maintenance_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `maintenance_id` bigint unsigned NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `action` varchar(50) NOT NULL,
  `description` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `maintenance_id` (`maintenance_id`),
  KEY `user_id` (`user_id`),
  KEY `idx_maintenance_logs_action` (`action`),
  KEY `idx_maintenance_logs_created_at` (`created_at`),
  CONSTRAINT `equipment_maintenance_logs_ibfk_1` FOREIGN KEY (`maintenance_id`) REFERENCES `equipment_maintenances` (`id`),
  CONSTRAINT `equipment_maintenance_logs_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla enfoqueqr.equipment_maintenance_photos
CREATE TABLE IF NOT EXISTS `equipment_maintenance_photos` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `maintenance_id` bigint unsigned NOT NULL,
  `file_path` varchar(255) NOT NULL,
  `uploaded_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `maintenance_id` (`maintenance_id`),
  KEY `idx_maintenance_photos_uploaded_at` (`uploaded_at`),
  KEY `idx_maintenance_photos_maintenance_uploaded` (`maintenance_id`,`uploaded_at`),
  CONSTRAINT `equipment_maintenance_photos_ibfk_1` FOREIGN KEY (`maintenance_id`) REFERENCES `equipment_maintenances` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla enfoqueqr.equipment_qr_codes
CREATE TABLE IF NOT EXISTS `equipment_qr_codes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `token` varchar(255) NOT NULL,
  `equipment_id` bigint unsigned DEFAULT NULL,
  `url_publica` varchar(255) DEFAULT NULL,
  `imagen_path` varchar(255) DEFAULT NULL,
  `enabled` tinyint DEFAULT '1',
  `assigned_at` timestamp NULL DEFAULT NULL,
  `revoked_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `batch_id` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `token` (`token`),
  KEY `equipment_id` (`equipment_id`),
  KEY `idx_equipment_qr_codes_enabled` (`enabled`),
  KEY `idx_equipment_qr_codes_equipment_enabled` (`equipment_id`,`enabled`),
  KEY `batch_id` (`batch_id`),
  CONSTRAINT `equipment_qr_codes_ibfk_1` FOREIGN KEY (`equipment_id`) REFERENCES `equipments` (`id`),
  CONSTRAINT `equipment_qr_codes_ibfk_2` FOREIGN KEY (`batch_id`) REFERENCES `qr_batches` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla enfoqueqr.institutions
CREATE TABLE IF NOT EXISTS `institutions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_institutions_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla enfoqueqr.institution_settings
CREATE TABLE IF NOT EXISTS `institution_settings` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `institution_id` bigint unsigned NOT NULL,
  `primary_color` varchar(7) DEFAULT '#000000' COMMENT 'Color principal en formato hexadecimal',
  `secondary_color` varchar(7) DEFAULT '#FFFFFF' COMMENT 'Color secundario en formato hexadecimal',
  `logo_url` varchar(255) DEFAULT NULL COMMENT 'URL del logo de la institución',
  `logo_url_white` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `institution_id` (`institution_id`),
  CONSTRAINT `institution_settings_ibfk_1` FOREIGN KEY (`institution_id`) REFERENCES `institutions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla enfoqueqr.qr_batches
CREATE TABLE IF NOT EXISTS `qr_batches` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `batch_code` varchar(50) NOT NULL,
  `prefix` varchar(50) DEFAULT NULL,
  `quantity` int NOT NULL,
  `created_by` bigint unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `notes` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `batch_code` (`batch_code`),
  KEY `created_by` (`created_by`),
  CONSTRAINT `qr_batches_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla enfoqueqr.qr_scan_logs
CREATE TABLE IF NOT EXISTS `qr_scan_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `qr_code_id` bigint unsigned NOT NULL,
  `ip` varchar(45) DEFAULT NULL,
  `user_agent` text,
  `scanned_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `qr_code_id` (`qr_code_id`),
  KEY `idx_qr_scan_logs_ip` (`ip`),
  KEY `idx_qr_scan_logs_scanned_at` (`scanned_at`),
  CONSTRAINT `qr_scan_logs_ibfk_1` FOREIGN KEY (`qr_code_id`) REFERENCES `equipment_qr_codes` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla enfoqueqr.users
CREATE TABLE IF NOT EXISTS `users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `remember_token` varchar(255) DEFAULT NULL,
  `status` tinyint DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  KEY `idx_users_status` (`status`),
  KEY `idx_users_created_at` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla enfoqueqr.user_institution
CREATE TABLE IF NOT EXISTS `user_institution` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `institution_id` bigint unsigned NOT NULL,
  `role` enum('super','admin','institution_user') DEFAULT 'institution_user',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `institution_id` (`institution_id`),
  KEY `idx_user_institution_role` (`role`),
  KEY `idx_user_institution_user_institution` (`user_id`,`institution_id`),
  CONSTRAINT `user_institution_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `user_institution_ibfk_2` FOREIGN KEY (`institution_id`) REFERENCES `institutions` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla enfoqueqr.user_profiles
CREATE TABLE IF NOT EXISTS `user_profiles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `full_name` varchar(255) DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `idx_user_profiles_full_name` (`full_name`),
  CONSTRAINT `user_profiles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- La exportación de datos fue deseleccionada.

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
