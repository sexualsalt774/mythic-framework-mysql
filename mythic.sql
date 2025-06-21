
DROP TABLE IF EXISTS `crafting_cooldowns`;
CREATE TABLE IF NOT EXISTS `crafting_cooldowns` (
  `bench` varchar(64) NOT NULL,
  `id` varchar(64) NOT NULL,
  `expires` bigint(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

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
  KEY `name` (`name`) USING BTREE
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

DROP TABLE IF EXISTS `meth_tables`;
CREATE TABLE IF NOT EXISTS `meth_tables` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `tier` int(11) NOT NULL DEFAULT 1,
  `created` bigint(20) NOT NULL,
  `cooldown` bigint(20) DEFAULT NULL,
  `recipe` varchar(512) NOT NULL,
  `active_cook` varchar(512) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `placed_meth_tables`;
CREATE TABLE IF NOT EXISTS `placed_meth_tables` (
  `table_id` int(11) NOT NULL,
  `owner` bigint(20) DEFAULT NULL,
  `placed` bigint(20) NOT NULL DEFAULT 0,
  `expires` bigint(20) NOT NULL DEFAULT 0,
  `coords` varchar(255) NOT NULL,
  `heading` double NOT NULL DEFAULT 0,
  PRIMARY KEY (`table_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `placed_props`;
CREATE TABLE IF NOT EXISTS `placed_props` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `model` varchar(255) NOT NULL DEFAULT '',
  `coords` varchar(255) NOT NULL,
  `heading` double NOT NULL DEFAULT 0,
  `created` datetime NOT NULL DEFAULT current_timestamp(),
  `creator` bigint(20) NOT NULL,
  `is_frozen` tinyint(1) NOT NULL DEFAULT 0,
  `is_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `type` int(11) NOT NULL DEFAULT 0,
  `name_override` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `outfit_codes`;
CREATE TABLE IF NOT EXISTS `outfit_codes` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`Code` VARCHAR(50) NULL DEFAULT NULL COLLATE 'latin1_swedish_ci',
	`Label` VARCHAR(25) NULL DEFAULT NULL COLLATE 'latin1_swedish_ci',
	`Data` LONGTEXT NULL DEFAULT NULL COLLATE 'latin1_swedish_ci',
	PRIMARY KEY (`id`) USING BTREE
)
COLLATE='latin1_swedish_ci'
ENGINE=InnoDB
AUTO_INCREMENT=16
;

-- Start of mongo to mysql conversion

DROP TABLE IF EXISTS `weed`;
CREATE TABLE IF NOT EXISTS `weed` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `is_male` TINYINT(1) NOT NULL,
  `x` DOUBLE NOT NULL,
  `y` DOUBLE NOT NULL,
  `z` DOUBLE NOT NULL,
  `growth` FLOAT NOT NULL DEFAULT 0,
  `output` FLOAT NOT NULL DEFAULT 1,
  `material` INT(11) NOT NULL, --VARCHAR(50) NOT NULL, -- UNSURE IF I SHOULD DO INT OR VARCHAR SINCE IT IS A NUMBER? ALL ISSUES FIXED AS INT
  `planted` INT(11) NOT NULL,
  `water` FLOAT NOT NULL DEFAULT 100,
  `fertilizer_type` VARCHAR(32) DEFAULT NULL,
  `fertilizer_value` FLOAT DEFAULT NULL,
  `fertilizer_time` INT(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `billboards`;
CREATE TABLE IF NOT EXISTS `billboards` (
  `billboardId` VARCHAR(64) NOT NULL,
  `billboardUrl` VARCHAR(512) DEFAULT NULL,
  PRIMARY KEY (`billboardId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `scenes`;
CREATE TABLE IF NOT EXISTS `scenes` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `x` FLOAT NOT NULL,
  `y` FLOAT NOT NULL,
  `z` FLOAT NOT NULL,
  `route` INT NOT NULL DEFAULT 1,
  `text` TEXT NOT NULL,
  `font` INT NOT NULL DEFAULT 1,
  `size` FLOAT NOT NULL DEFAULT 0.35,
  `outline` TINYINT(1) NOT NULL DEFAULT 0,
  `text_color_r` INT NOT NULL DEFAULT 255,
  `text_color_g` INT NOT NULL DEFAULT 255,
  `text_color_b` INT NOT NULL DEFAULT 255,
  `background_type` INT NOT NULL DEFAULT 0,
  `background_opacity` INT NOT NULL DEFAULT 255,
  `background_color_r` INT NOT NULL DEFAULT 255,
  `background_color_g` INT NOT NULL DEFAULT 255,
  `background_color_b` INT NOT NULL DEFAULT 255,
  `background_h` FLOAT NOT NULL DEFAULT 0.02,
  `background_w` FLOAT NOT NULL DEFAULT 0.0,
  `background_x` FLOAT NOT NULL DEFAULT 0.0,
  `background_y` FLOAT NOT NULL DEFAULT 0.0,
  `background_rotation` FLOAT NOT NULL DEFAULT 0.0,
  `length` INT NOT NULL DEFAULT 6,
  `distance` FLOAT NOT NULL DEFAULT 7.5,
  `expires` BIGINT NULL DEFAULT NULL,
  `staff` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1; 

DROP TABLE IF EXISTS `characters`;
CREATE TABLE IF NOT EXISTS `characters` (
  `ID` INT(11) NOT NULL AUTO_INCREMENT,                         -- Internal unique row ID
  -- `_id` VARCHAR(48) DEFAULT NULL,                               -- MongoDB-style ID
  `User` VARCHAR(64) NOT NULL,                                  -- Account ID
  `First` VARCHAR(64) NOT NULL,
  `Last` VARCHAR(64) NOT NULL,
  `Phone` VARCHAR(32) NOT NULL UNIQUE,                          -- Phone must be unique
  `Gender` INT(11) NOT NULL,
  `Bio` TEXT DEFAULT NULL,
  `Origin` JSON DEFAULT NULL,
  `DOB` BIGINT(20) DEFAULT NULL,                                -- Date of birth (Unix timestamp)
  `LastPlayed` BIGINT(20) DEFAULT NULL,
  `Jobs` JSON DEFAULT NULL,
  `SID` INT(11) NOT NULL UNIQUE,                                -- State ID
  `Cash` INT(11) NOT NULL DEFAULT 0,
  `New` TINYINT(1) NOT NULL DEFAULT 1,
  `Licenses` JSON DEFAULT NULL,
  `Deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `CryptoWallet` VARCHAR(64) DEFAULT NULL,
  `Crypto` JSON DEFAULT NULL,
  `Alias` JSON DEFAULT NULL,
  `Parole` JSON DEFAULT NULL,
  `Jailed` JSON DEFAULT NULL,
  `ICU` JSON DEFAULT NULL,
  `Apartment` JSON DEFAULT NULL,
  `GangChain` JSON DEFAULT NULL,
  `Preview` JSON DEFAULT NULL,
  `LSUNDGBan` JSON DEFAULT NULL,
  `Callsign` VARCHAR(32) DEFAULT NULL,
  `Team` VARCHAR(32) DEFAULT NULL,
  `TempJob` VARCHAR(64) DEFAULT NULL,
  `Ped` VARCHAR(64) DEFAULT NULL,
  `MDTHistory` JSON DEFAULT NULL,
  `States` JSON DEFAULT NULL,
  `Armor` INT(11) DEFAULT NULL,
  `HP` INT(11) DEFAULT NULL,
  `JobDuty` TINYINT(1) DEFAULT NULL,
  `Job` JSON DEFAULT NULL,
  `CashBank` INT(11) DEFAULT NULL,
  `Bank` INT(11) DEFAULT NULL,
  `Mugshot` VARCHAR(255) DEFAULT NULL,
  `Attorney` TINYINT(1) DEFAULT 0,
  `LastClockOn` BIGINT(20) DEFAULT NULL,
  `TimeClockedOn` BIGINT(20) DEFAULT NULL,
  `Flags` JSON DEFAULT NULL,
  `Qualifications` JSON DEFAULT NULL,
  `PhoneSettings` JSON DEFAULT NULL,
  `PhonePermissions` JSON DEFAULT NULL,
  `LaptopSettings` JSON DEFAULT NULL,
  `LaptopPermissions` JSON DEFAULT NULL,
  `LaptopApps` JSON DEFAULT NULL,
  `Apps` JSON DEFAULT NULL,
  `PreviewPed` VARCHAR(64) DEFAULT NULL,
  `PreviewData` JSON DEFAULT NULL,
  `Animations` JSON DEFAULT NULL,
  `Status` JSON DEFAULT NULL,
  `Addiction` JSON DEFAULT NULL,
  `InventorySettings` JSON DEFAULT NULL,
  `BankAccount` INT(11) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `User` (`User`),
  KEY `CryptoWallet` (`CryptoWallet`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `sequence`;
CREATE TABLE IF NOT EXISTS `sequence` (
  `key` VARCHAR(255) NOT NULL,
  `current` INT NOT NULL DEFAULT 1,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- Below needs to be worked on / formatted