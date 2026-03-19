
CREATE TABLE institutions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    status TINYINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    INDEX idx_name (name),
    INDEX idx_status (status)
) ENGINE=InnoDB;

CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    status TINYINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    INDEX idx_email (email),
    INDEX idx_status (status)
) ENGINE=InnoDB;

CREATE TABLE user_profiles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    first_name VARCHAR(150),
    last_name VARCHAR(150),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB;

CREATE TABLE user_institution (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED,
    institution_id BIGINT UNSIGNED,
    status TINYINT DEFAULT 1, -- 1=active, 0=inactive
    role ENUM('ADMIN','OPERATOR') NOT NULL, -- role at institution level
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY uq_user_institution (user_id, institution_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (institution_id) REFERENCES institutions(id),
    INDEX idx_user_id (user_id),
    INDEX idx_institution_id (institution_id),
    INDEX idx_status (status),
    INDEX idx_role (role)
) ENGINE=InnoDB;

CREATE TABLE devices (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    institution_id BIGINT UNSIGNED,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    status TINYINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (institution_id) REFERENCES institutions(id),
    INDEX idx_institution_id (institution_id),
    INDEX idx_code (code),
    INDEX idx_name (name),
    INDEX idx_status (status)
) ENGINE=InnoDB;

CREATE TABLE qr_codes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    token VARCHAR(64) NOT NULL UNIQUE,
    public_url VARCHAR(255) NOT NULL,
    image_path VARCHAR(255),
    status ENUM('GENERATED','ENROLLED','CANCELLED') DEFAULT 'GENERATED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    INDEX idx_token (token),
    INDEX idx_status (status)
) ENGINE=InnoDB;

CREATE TABLE device_has_qr_code (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    device_id BIGINT UNSIGNED,
    qr_code_id BIGINT UNSIGNED,
    enrollment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY uq_device_qrcode (device_id, qr_code_id),
    FOREIGN KEY (device_id) REFERENCES devices(id),
    FOREIGN KEY (qr_code_id) REFERENCES qr_codes(id),
    INDEX idx_device_id (device_id),
    INDEX idx_qr_code_id (qr_code_id)
) ENGINE=InnoDB;

CREATE TABLE documents (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    device_id BIGINT UNSIGNED,
    title VARCHAR(200),
    status TINYINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (device_id) REFERENCES devices(id),
    INDEX idx_device_id (device_id),
    INDEX idx_status (status)
) ENGINE=InnoDB;

CREATE TABLE document_versions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    document_id BIGINT UNSIGNED,
    version INT,
    file_path VARCHAR(255),
    current TINYINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (document_id) REFERENCES documents(id),
    INDEX idx_document_id (document_id),
    INDEX idx_version (version),
    INDEX idx_current (current)
) ENGINE=InnoDB;

CREATE TABLE maintenances (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    device_id BIGINT UNSIGNED,
    user_id BIGINT UNSIGNED,
    description TEXT,
    date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (device_id) REFERENCES devices(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    INDEX idx_device_id (device_id),
    INDEX idx_user_id (user_id),
    INDEX idx_date (date)
) ENGINE=InnoDB;

CREATE TABLE qr_scan_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    qr_code_id BIGINT UNSIGNED,
    ip VARCHAR(45),
    user_agent VARCHAR(255),
    scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (qr_code_id) REFERENCES qr_codes(id),
    INDEX idx_qr_code_id (qr_code_id),
    INDEX idx_scanned_at (scanned_at)
) ENGINE=InnoDB;


-- Token to remember session (authentication)
ALTER TABLE users
ADD remember_token VARCHAR(100) NULL;
