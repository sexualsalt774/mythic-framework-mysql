-- Phone System Tables
DROP TABLE IF EXISTS `phone_contacts`;
CREATE TABLE IF NOT EXISTS `phone_contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `character` int(11) NOT NULL,
  `number` varchar(20) NOT NULL,
  `name` varchar(100) NOT NULL,
  `color` varchar(20) DEFAULT NULL,
  `avatar` varchar(255) DEFAULT NULL,
  `favorite` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_character` (`character`),
  KEY `idx_number` (`number`),
  KEY `idx_favorite` (`favorite`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `phone_messages`;
CREATE TABLE IF NOT EXISTS `phone_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner` int(11) NOT NULL,
  `number` varchar(20) NOT NULL,
  `message` text NOT NULL,
  `time` bigint(20) NOT NULL,
  `method` tinyint(1) DEFAULT 0,
  `unread` tinyint(1) DEFAULT 0,
  `read` tinyint(1) DEFAULT 0,
  `deleted` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_owner` (`owner`),
  KEY `idx_number` (`number`),
  KEY `idx_time` (`time`),
  KEY `idx_read` (`read`),
  KEY `idx_deleted` (`deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `phone_calls`;
CREATE TABLE IF NOT EXISTS `phone_calls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner` varchar(20) NOT NULL,
  `number` varchar(20) NOT NULL,
  `time` bigint(20) NOT NULL,
  `duration` int(11) DEFAULT -1,
  `method` tinyint(1) DEFAULT 0,
  `limited` tinyint(1) DEFAULT 0,
  `anonymous` tinyint(1) DEFAULT 0,
  `decryptable` tinyint(1) DEFAULT 0,
  `unread` tinyint(1) DEFAULT 0,
  `deleted` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_owner` (`owner`),
  KEY `idx_number` (`number`),
  KEY `idx_time` (`time`),
  KEY `idx_deleted` (`deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `character_emails`;
CREATE TABLE IF NOT EXISTS `character_emails` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner` int(11) NOT NULL,
  `sender` varchar(255) NOT NULL,
  `time` bigint(20) NOT NULL,
  `subject` varchar(255) NOT NULL,
  `body` text NOT NULL,
  `unread` tinyint(1) DEFAULT 0,
  `flags` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_owner` (`owner`),
  KEY `idx_sender` (`sender`),
  KEY `idx_time` (`time`),
  KEY `idx_unread` (`unread`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `character_documents`;
CREATE TABLE IF NOT EXISTS `character_documents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` text NOT NULL,
  `time` bigint(20) NOT NULL,
  `sharedWith` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_owner` (`owner`),
  KEY `idx_time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `irc_channels`;
CREATE TABLE IF NOT EXISTS `irc_channels` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `slug` varchar(100) NOT NULL,
  `joined` bigint(20) NOT NULL,
  `character` int(11) NOT NULL,
  `name` varchar(100) NOT NULL UNIQUE,
  `messages` json DEFAULT '[]',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_channel_name` (`name`),
  KEY `idx_character` (`character`),
  KEY `idx_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `irc_messages`;
CREATE TABLE IF NOT EXISTS `irc_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `channel` varchar(100) NOT NULL,
  `from_user` varchar(100) NOT NULL,
  `message` text NOT NULL,
  `time` bigint(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_channel` (`channel`),
  KEY `idx_time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 