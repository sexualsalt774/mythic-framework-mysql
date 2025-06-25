-- Inventory System Tables
DROP TABLE IF EXISTS `inventory`;
CREATE TABLE IF NOT EXISTS `inventory` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8mb3 NOT NULL DEFAULT '0',
  `slot` int(11) DEFAULT NULL,
  `item_id` varchar(255) CHARACTER SET utf8mb3 DEFAULT NULL,
  `quality` int(11) DEFAULT NULL,
  `information` varchar(1024) CHARACTER SET utf8mb3 NOT NULL DEFAULT '0',
  `dropped` tinyint(4) NOT NULL DEFAULT 0,
  `creationDate` bigint(20) NOT NULL DEFAULT 0,
  `expiryDate` bigint(20) NOT NULL DEFAULT -1,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_inventory_name` (`name`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1164831 DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `inventory_shop_logs`;
CREATE TABLE IF NOT EXISTS `inventory_shop_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date` datetime NOT NULL DEFAULT current_timestamp(),
  `inventory` varchar(255) NOT NULL DEFAULT '0',
  `item` varchar(255) NOT NULL DEFAULT '0',
  `count` int(11) NOT NULL DEFAULT 0,
  `itemId` bigint(20) DEFAULT NULL,
  `buyer` int(11) NOT NULL DEFAULT 0,
  `metadata` varchar(512) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=91 DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `crafting_cooldowns`;
CREATE TABLE IF NOT EXISTS `crafting_cooldowns` (
  `bench` varchar(64) NOT NULL,
  `id` varchar(64) NOT NULL,
  `expires` bigint(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `entitytypes`;
CREATE TABLE IF NOT EXISTS `entitytypes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `slots` int(11) NOT NULL DEFAULT 0,
  `capacity` int(11) NOT NULL DEFAULT 0,
  `name` varchar(255) NOT NULL,
  `shop` tinyint(1) DEFAULT 0,
  `itemSet` int(11) DEFAULT NULL,
  `isVehicle` tinyint(1) DEFAULT 0,
  `isTrunk` tinyint(1) DEFAULT 0,
  `isGlovebox` tinyint(1) DEFAULT 0,
  `free` tinyint(1) DEFAULT 0,
  `trash` tinyint(1) DEFAULT 0,
  `restriction` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_name` (`name`),
  KEY `idx_shop` (`shop`),
  KEY `idx_itemSet` (`itemSet`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `schematics`;
CREATE TABLE IF NOT EXISTS `schematics` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `bench` varchar(255) NOT NULL,
  `item` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_bench_item` (`bench`, `item`),
  KEY `idx_bench` (`bench`),
  KEY `idx_item` (`item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 