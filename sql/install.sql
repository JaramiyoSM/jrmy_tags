CREATE TABLE IF NOT EXISTS `jrmy_tags_grants` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `namespace` CHAR(16) COLLATE utf8mb4_bin NOT NULL,
    `owner_type` VARCHAR(16) COLLATE utf8mb4_bin NOT NULL,
    `owner_identifier` VARCHAR(96) COLLATE utf8mb4_bin NOT NULL,
    `owner_name` VARCHAR(80) NOT NULL,
    `style_key` VARCHAR(48) COLLATE utf8mb4_bin NOT NULL,
    `label` VARCHAR(48) NOT NULL,
    `subtitle` VARCHAR(64) DEFAULT NULL,
    `emoji` VARCHAR(32) DEFAULT NULL,
    `granted_by_type` VARCHAR(16) COLLATE utf8mb4_bin NOT NULL,
    `granted_by_identifier` VARCHAR(96) COLLATE utf8mb4_bin NOT NULL,
    `granted_by_name` VARCHAR(80) NOT NULL,
    `expires_at` BIGINT UNSIGNED DEFAULT NULL,
    `granted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `owner_style` (`namespace`, `owner_type`, `owner_identifier`, `style_key`),
    KEY `owner_active` (`namespace`, `owner_type`, `owner_identifier`, `expires_at`),
    KEY `style_active` (`namespace`, `style_key`, `expires_at`),
    KEY `owner_name` (`namespace`, `owner_name`),
    KEY `expiry_sweep` (`namespace`, `expires_at`),
    KEY `admin_recent` (`namespace`, `updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `jrmy_tags_profiles` (
    `namespace` CHAR(16) COLLATE utf8mb4_bin NOT NULL,
    `owner_type` VARCHAR(16) COLLATE utf8mb4_bin NOT NULL,
    `owner_identifier` VARCHAR(96) COLLATE utf8mb4_bin NOT NULL,
    `selected_grant_id` BIGINT UNSIGNED DEFAULT NULL,
    `visible` TINYINT(1) NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`namespace`, `owner_type`, `owner_identifier`),
    KEY `selected_grant` (`selected_grant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `jrmy_tags_audit` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `namespace` CHAR(16) COLLATE utf8mb4_bin NOT NULL,
    `action` VARCHAR(24) COLLATE utf8mb4_bin NOT NULL,
    `actor_type` VARCHAR(16) COLLATE utf8mb4_bin NOT NULL,
    `actor_identifier` VARCHAR(96) COLLATE utf8mb4_bin NOT NULL,
    `actor_name` VARCHAR(80) NOT NULL,
    `target_type` VARCHAR(16) COLLATE utf8mb4_bin NOT NULL,
    `target_identifier` VARCHAR(96) COLLATE utf8mb4_bin NOT NULL,
    `target_name` VARCHAR(80) NOT NULL,
    `grant_id` BIGINT UNSIGNED DEFAULT NULL,
    `style_key` VARCHAR(48) COLLATE utf8mb4_bin DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `target_history` (`namespace`, `target_type`, `target_identifier`, `created_at`),
    KEY `actor_history` (`namespace`, `actor_type`, `actor_identifier`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
