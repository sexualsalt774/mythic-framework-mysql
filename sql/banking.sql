-- Banking System Tables
DROP TABLE IF EXISTS `bank_accounts`;
CREATE TABLE IF NOT EXISTS `bank_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Account` varchar(20) NOT NULL,
  `Name` varchar(255) NOT NULL,
  `Balance` int(11) NOT NULL DEFAULT 0,
  `Type` varchar(50) NOT NULL DEFAULT 'personal',
  `Owner` varchar(64) NOT NULL,
  `JobAccess` json DEFAULT NULL,
  `JointOwners` json DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` bigint(20) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `Account` (`Account`),
  KEY `idx_name` (`Name`),
  KEY `idx_owner` (`Owner`),
  KEY `idx_type` (`Type`),
  KEY `idx_active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `bank_accounts_transactions`;
CREATE TABLE IF NOT EXISTS `bank_accounts_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Type` varchar(50) NOT NULL,
  `Timestamp` bigint(20) NOT NULL,
  `Account` varchar(20) NOT NULL,
  `Amount` int(11) NOT NULL,
  `Title` varchar(255) NOT NULL,
  `Description` varchar(255) NOT NULL,
  `TransactionAccount` varchar(20) DEFAULT NULL,
  `Data` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_account` (`Account`),
  KEY `idx_type` (`Type`),
  KEY `idx_timestamp` (`Timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `store_bank_accounts`;
CREATE TABLE IF NOT EXISTS `store_bank_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Shop` int(11) NOT NULL,
  `Account` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_shop` (`Shop`),
  KEY `idx_shop` (`Shop`),
  KEY `idx_account` (`Account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 