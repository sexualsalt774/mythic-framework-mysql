-- Properties System Tables
DROP TABLE IF EXISTS `properties`;
CREATE TABLE IF NOT EXISTS `properties` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `type` VARCHAR(50) NOT NULL,
  `label` VARCHAR(255) NOT NULL,
  `price` INT NOT NULL DEFAULT 0,
  `sold` TINYINT(1) NOT NULL DEFAULT 0,
  `owner` JSON DEFAULT NULL,
  `location` JSON DEFAULT NULL,
  `upgrades` JSON DEFAULT NULL,
  `data` JSON DEFAULT NULL,
  `keys` JSON DEFAULT NULL,
  `soldAt` INT DEFAULT NULL,
  `foreclosed` TINYINT(1) NOT NULL DEFAULT 0,
  `foreclosedTime` INT DEFAULT NULL,
  `locked` TINYINT(1) NOT NULL DEFAULT 1,
  `interior` VARCHAR(50) DEFAULT NULL,
  `unlisted` TINYINT(1) NOT NULL DEFAULT 0,
  `default` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `idx_type` (`type`),
  KEY `idx_sold` (`sold`),
  KEY `idx_foreclosed` (`foreclosed`),
  KEY `idx_label` (`label`),
  KEY `idx_unlisted` (`unlisted`)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

DROP TABLE IF EXISTS `properties_furniture`;
CREATE TABLE IF NOT EXISTS `properties_furniture` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `property_id` int(11) NOT NULL,
  `furniture` json NOT NULL,
  `position` json NOT NULL,
  `rotation` json NOT NULL,
  `placed_by` json NOT NULL,
  `placed_at` bigint(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_property_id` (`property_id`),
  KEY `idx_placed_at` (`placed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 