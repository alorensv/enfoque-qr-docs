-- EnfoqueQR - Modelo de Datos MySQL (Actualizado)

CREATE TABLE instituciones (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    estado TINYINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    INDEX idx_nombre (nombre),
    INDEX idx_estado (estado)
) ENGINE=InnoDB;

CREATE TABLE usuarios (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    estado TINYINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    INDEX idx_email (email),
    INDEX idx_estado (estado)
) ENGINE=InnoDB;

CREATE TABLE usuario_profiles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    usuario_id BIGINT UNSIGNED NOT NULL,
    nombres VARCHAR(150),
    apellidos VARCHAR(150),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
    INDEX idx_usuario_id (usuario_id)
) ENGINE=InnoDB;

CREATE TABLE usuario_institucion (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    usuario_id BIGINT UNSIGNED,
    institucion_id BIGINT UNSIGNED,
    estado TINYINT DEFAULT 1, -- 1=activo, 0=inactivo
    rol ENUM('ADMIN','OPERADOR') NOT NULL, -- rol a nivel de institución
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY uq_usuario_institucion (usuario_id, institucion_id),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
    FOREIGN KEY (institucion_id) REFERENCES instituciones(id),
    INDEX idx_usuario_id (usuario_id),
    INDEX idx_institucion_id (institucion_id),
    INDEX idx_estado (estado),
    INDEX idx_rol (rol)
) ENGINE=InnoDB;

CREATE TABLE equipos (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    institucion_id BIGINT UNSIGNED,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    estado TINYINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (institucion_id) REFERENCES instituciones(id),
    INDEX idx_institucion_id (institucion_id),
    INDEX idx_codigo (codigo),
    INDEX idx_nombre (nombre),
    INDEX idx_estado (estado)
) ENGINE=InnoDB;

CREATE TABLE codigo_qr (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    token VARCHAR(64) NOT NULL UNIQUE,
    url_publica VARCHAR(255) NOT NULL,
    imagen_path VARCHAR(255),
    estado ENUM('GENERADO','ENROLADO','ANULADO') DEFAULT 'GENERADO',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    INDEX idx_token (token),
    INDEX idx_estado (estado)
) ENGINE=InnoDB;

CREATE TABLE equipo_has_codigo_qr (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    equipo_id BIGINT UNSIGNED,
    codigo_qr_id BIGINT UNSIGNED,
    fecha_enrolamiento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY uq_equipo_codigoqr (equipo_id, codigo_qr_id),
    FOREIGN KEY (equipo_id) REFERENCES equipos(id),
    FOREIGN KEY (codigo_qr_id) REFERENCES codigo_qr(id),
    INDEX idx_equipo_id (equipo_id),
    INDEX idx_codigo_qr_id (codigo_qr_id)
) ENGINE=InnoDB;

CREATE TABLE documentos (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    equipo_id BIGINT UNSIGNED,
    titulo VARCHAR(200),
    estado TINYINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (equipo_id) REFERENCES equipos(id),
    INDEX idx_equipo_id (equipo_id),
    INDEX idx_estado (estado)
) ENGINE=InnoDB;

CREATE TABLE documento_versiones (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    documento_id BIGINT UNSIGNED,
    version INT,
    archivo_path VARCHAR(255),
    vigente TINYINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (documento_id) REFERENCES documentos(id),
    INDEX idx_documento_id (documento_id),
    INDEX idx_version (version),
    INDEX idx_vigente (vigente)
) ENGINE=InnoDB;

CREATE TABLE mantenciones (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    equipo_id BIGINT UNSIGNED,
    user_id BIGINT UNSIGNED,
    descripcion TEXT,
    fecha DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (equipo_id) REFERENCES equipos(id),
    FOREIGN KEY (user_id) REFERENCES usuarios(id),
    INDEX idx_equipo_id (equipo_id),
    INDEX idx_user_id (user_id),
    INDEX idx_fecha (fecha)
) ENGINE=InnoDB;

CREATE TABLE qr_scan_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    codigo_qr_id BIGINT UNSIGNED,
    ip VARCHAR(45),
    user_agent VARCHAR(255),
    scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (codigo_qr_id) REFERENCES codigo_qr(id),
    INDEX idx_codigo_qr_id (codigo_qr_id),
    INDEX idx_scanned_at (scanned_at)
) ENGINE=InnoDB;
