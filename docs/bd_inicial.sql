-- =========================
-- USUARIOS
-- =========================
CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  status TINYINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_profiles (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  full_name VARCHAR(255),
  phone VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE institutions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_institution (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  institution_id BIGINT UNSIGNED NOT NULL,
  role VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (institution_id) REFERENCES institutions(id)
);

-- =========================
-- EQUIPOS
-- =========================
CREATE TABLE equipments (
  id CHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  serial_number VARCHAR(255),
  description TEXT,
  status VARCHAR(50),
  institution_id BIGINT UNSIGNED,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (institution_id) REFERENCES institutions(id)
);

-- =========================
-- CÓDIGOS QR (PRE-GENERADOS Y ENROLABLES)
-- =========================
CREATE TABLE equipment_qr_codes (
  id CHAR(36) PRIMARY KEY,
  token VARCHAR(255) NOT NULL UNIQUE,
  equipment_id CHAR(36) NULL,
  enabled TINYINT DEFAULT 1,
  assigned_at TIMESTAMP NULL,
  revoked_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (equipment_id) REFERENCES equipments(id)
);

-- =========================
-- TRAZABILIDAD DE ESCANEOS
-- =========================
CREATE TABLE qr_scan_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  qr_code_id CHAR(36) NOT NULL,
  ip VARCHAR(45),
  user_agent TEXT,
  scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (qr_code_id) REFERENCES equipment_qr_codes(id)
);

-- =========================
-- DOCUMENTACIÓN
-- =========================
CREATE TABLE equipment_documents (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  equipment_id CHAR(36) NOT NULL,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (equipment_id) REFERENCES equipments(id)
);

CREATE TABLE equipment_document_versions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  document_id BIGINT UNSIGNED NOT NULL,
  version INT NOT NULL,
  file_path VARCHAR(255) NOT NULL,
  checksum VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (document_id) REFERENCES equipment_documents(id)
);

-- =========================
-- MANTENCIONES / SERVICIO TÉCNICO
-- =========================
CREATE TABLE equipment_maintenances (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  equipment_id CHAR(36) NOT NULL,
  description TEXT,
  performed_at DATE,
  technician VARCHAR(255),
  status VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (equipment_id) REFERENCES equipments(id)
);


CREATE TABLE codigo_qr (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    token VARCHAR(64) NOT NULL UNIQUE,
    url_publica VARCHAR(255) NOT NULL,
    imagen_path VARCHAR(255) NULL,
    estado ENUM('GENERADO','ENROLADO','ANULADO') DEFAULT 'GENERADO',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;
CREATE INDEX idx_codigo_qr_token ON codigo_qr(token);