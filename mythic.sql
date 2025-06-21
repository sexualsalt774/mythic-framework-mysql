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
  `material` INT(11) NOT NULL,
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
  `Apartment` TINYINT DEFAULT NULL,
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

DROP TABLE IF EXISTS `defaults`;
CREATE TABLE IF NOT EXISTS `defaults` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `collection` VARCHAR(255) NOT NULL UNIQUE,
  `date` BIGINT NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

DROP TABLE IF EXISTS `dealer_stock`;
CREATE TABLE IF NOT EXISTS `dealer_stock` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `vehicle` VARCHAR(50) NOT NULL,
  `quantity` INT NOT NULL DEFAULT 0,
  `dealership` VARCHAR(50) NOT NULL,
  `data` JSON NOT NULL,
  `lastStocked` BIGINT NOT NULL DEFAULT 0,
  `lastPurchase` BIGINT NOT NULL DEFAULT 0,
  `default` BOOLEAN NOT NULL DEFAULT FALSE,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

DROP TABLE IF EXISTS `locations`;
CREATE TABLE IF NOT EXISTS `locations` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `Type` VARCHAR(50) NOT NULL DEFAULT 'spawn',
  `Name` VARCHAR(100) NOT NULL,
  `Heading` FLOAT NOT NULL DEFAULT 0,
  `Coords` JSON NOT NULL,
  `default` BOOLEAN NOT NULL DEFAULT FALSE,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

DROP TABLE IF EXISTS `mdt_charges`;
CREATE TABLE IF NOT EXISTS `mdt_charges` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `title` VARCHAR(255) NOT NULL,
  `type` INT NOT NULL DEFAULT 1,
  `jail` INT NOT NULL DEFAULT 0,
  `fine` INT NOT NULL DEFAULT 0,
  `description` TEXT NOT NULL,
  `points` INT NOT NULL DEFAULT 0,
  `default` BOOLEAN NOT NULL DEFAULT FALSE,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

DROP TABLE IF EXISTS `mdt_warrants`;
CREATE TABLE IF NOT EXISTS `mdt_warrants` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `state` VARCHAR(50) NOT NULL DEFAULT 'active',
  `expires` BIGINT NOT NULL,
  `data` JSON NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `idx_state` (`state`),
  KEY `idx_expires` (`expires`)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

DROP TABLE IF EXISTS `mdt_tags`;
CREATE TABLE IF NOT EXISTS `mdt_tags` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `data` JSON NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

DROP TABLE IF EXISTS `mdt_notices`;
CREATE TABLE IF NOT EXISTS `mdt_notices` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `data` JSON NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

DROP TABLE IF EXISTS `roles`;
CREATE TABLE IF NOT EXISTS `roles` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `Abv` VARCHAR(50) NOT NULL,
  `Name` VARCHAR(100) NOT NULL,
  `Queue` JSON NOT NULL,
  `Permission` JSON NOT NULL,
  `default` BOOLEAN NOT NULL DEFAULT FALSE,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

DROP TABLE IF EXISTS `users`;
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(255),
  `forum` VARCHAR(255),
  `account` VARCHAR(255),
  `identifier` VARCHAR(255) UNIQUE,
  `verified` TINYINT DEFAULT 0,
  `joined` BIGINT,
  `groups` JSON,
  `avatar` VARCHAR(255),
  `priority` INT DEFAULT 0,
  `tokens` JSON,
  `default` TINYINT DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

DROP TABLE IF EXISTS `bans`;
CREATE TABLE IF NOT EXISTS `bans` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `account` INT,
  `identifier` VARCHAR(255),
  `expires` BIGINT,
  `reason` TEXT,
  `issuer` VARCHAR(255),
  `active` TINYINT(1) DEFAULT 1,
  `started` BIGINT,
  `tokens` JSON,
  `unbanned` JSON,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_account` (`account`),
  INDEX `idx_identifier` (`identifier`),
  INDEX `idx_active` (`active`)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

DROP TABLE IF EXISTS `logs`;
CREATE TABLE IF NOT EXISTS `logs` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `date` BIGINT NOT NULL,
  `level` VARCHAR(50) NOT NULL,
  `component` VARCHAR(100) NOT NULL,
  `log` TEXT NOT NULL,
  `data` JSON NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

DROP TABLE IF EXISTS `storage_units`;
CREATE TABLE IF NOT EXISTS `storage_units` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `label` VARCHAR(255) NOT NULL,
  `owner` JSON DEFAULT NULL,
  `level` INT(11) NOT NULL DEFAULT 1,
  `location` JSON NOT NULL,
  `managedBy` VARCHAR(100) NOT NULL,
  `lastAccessed` BIGINT(20) DEFAULT NULL,
  `passcode` VARCHAR(8) NOT NULL DEFAULT '0000',
  `soldBy` JSON DEFAULT NULL,
  `soldAt` BIGINT(20) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `managedBy` (`managedBy`),
  KEY `level` (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `business_tvs`;
CREATE TABLE IF NOT EXISTS `business_tvs` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `tv` VARCHAR(100) NOT NULL,
  `link` TEXT NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tv` (`tv`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Casino Big Wins Table
DROP TABLE IF EXISTS `casino_bigwins`;
CREATE TABLE IF NOT EXISTS `casino_bigwins` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `Type` VARCHAR(100) NOT NULL,
  `Time` BIGINT(20) NOT NULL,
  `Winner` JSON NOT NULL,
  `Prize` INT(11) NOT NULL,
  `MetaData` JSON DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `Time` (`Time`),
  KEY `Type` (`Type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Casino Statistics Table
DROP TABLE IF EXISTS `casino_statistics`;
CREATE TABLE IF NOT EXISTS `casino_statistics` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `SID` INT(11) NOT NULL,
  `stats` JSON DEFAULT NULL,
  `TotalAmountWon` BIGINT(20) NOT NULL DEFAULT 0,
  `TotalAmountLost` BIGINT(20) NOT NULL DEFAULT 0,
  `AmountWon` JSON DEFAULT NULL,
  `AmountLost` JSON DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `SID` (`SID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Casino Config Table
DROP TABLE IF EXISTS `casino_config`;
CREATE TABLE IF NOT EXISTS `casino_config` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `key` VARCHAR(255) NOT NULL,
  `data` JSON NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `peds`;
CREATE TABLE IF NOT EXISTS `peds` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `Char` INT(11) NOT NULL,
  `Ped` JSON NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `Char` (`Char`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `dealer_data`;
CREATE TABLE IF NOT EXISTS `dealer_data` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `dealership` VARCHAR(100) NOT NULL,
  `data` JSON NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `dealership` (`dealership`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dealer Records Table
DROP TABLE IF EXISTS `dealer_records`;
CREATE TABLE IF NOT EXISTS `dealer_records` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `dealership` VARCHAR(100) NOT NULL,
  `time` BIGINT(20) NOT NULL,
  `type` VARCHAR(50) NOT NULL,
  `vehicle` JSON NOT NULL,
  `profitPercent` FLOAT DEFAULT NULL,
  `salePrice` INT(11) NOT NULL,
  `dealerProfits` INT(11) NOT NULL,
  `commission` INT(11) NOT NULL,
  `seller` JSON NOT NULL,
  `buyer` JSON NOT NULL,
  `newQuantity` INT(11) DEFAULT NULL,
  `loan` JSON DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `dealership` (`dealership`),
  KEY `time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dealer Records Buybacks Table
DROP TABLE IF EXISTS `dealer_records_buybacks`;
CREATE TABLE IF NOT EXISTS `dealer_records_buybacks` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `dealership` VARCHAR(100) NOT NULL,
  `time` BIGINT(20) NOT NULL,
  `type` VARCHAR(50) NOT NULL,
  `vehicle` JSON NOT NULL,
  `profitPercent` FLOAT DEFAULT NULL,
  `salePrice` INT(11) NOT NULL,
  `dealerProfits` INT(11) NOT NULL,
  `commission` INT(11) NOT NULL,
  `seller` JSON NOT NULL,
  `buyer` JSON NOT NULL,
  `newQuantity` INT(11) DEFAULT NULL,
  `loan` JSON DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `dealership` (`dealership`),
  KEY `time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dealer Showrooms Table
DROP TABLE IF EXISTS `dealer_showrooms`;
CREATE TABLE IF NOT EXISTS `dealer_showrooms` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `dealership` VARCHAR(100) NOT NULL,
  `showroom` JSON NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `dealership` (`dealership`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `changelogs`;
CREATE TABLE IF NOT EXISTS `changelogs` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `date` BIGINT(20) NOT NULL,
  `title` VARCHAR(255) DEFAULT NULL,
  `content` TEXT DEFAULT NULL,
  `version` VARCHAR(50) DEFAULT NULL,
  `author` VARCHAR(100) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `vehicles`;
CREATE TABLE IF NOT EXISTS `vehicles` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `Type` INT(11) NOT NULL DEFAULT 0,
  `Vehicle` BIGINT(20) NOT NULL,
  `VIN` VARCHAR(50) NOT NULL,
  `RegisteredPlate` VARCHAR(20) DEFAULT NULL,
  `FakePlate` VARCHAR(20) DEFAULT NULL,
  `FakePlateData` JSON DEFAULT NULL,
  `Fuel` FLOAT NOT NULL DEFAULT 100.0,
  `Owner` JSON NOT NULL,
  `Storage` JSON NOT NULL,
  `Make` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
  `Model` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
  `Class` VARCHAR(10) NOT NULL DEFAULT 'Unknown',
  `Value` INT(11) DEFAULT NULL,
  `FirstSpawn` BOOLEAN NOT NULL DEFAULT TRUE,
  `Properties` JSON DEFAULT NULL,
  `RegistrationDate` BIGINT(20) NOT NULL,
  `Mileage` FLOAT NOT NULL DEFAULT 0.0,
  `DirtLevel` FLOAT NOT NULL DEFAULT 0.0,
  `Seized` BOOLEAN NOT NULL DEFAULT FALSE,
  `SeizedTime` BIGINT(20) DEFAULT NULL,
  `LastSave` BIGINT(20) DEFAULT NULL,
  `Flags` JSON DEFAULT NULL,
  `Strikes` JSON DEFAULT NULL,
  `Damage` JSON DEFAULT NULL,
  `DamagedParts` JSON DEFAULT NULL,
  `WheelFitment` JSON DEFAULT NULL,
  `Polish` JSON DEFAULT NULL,
  `Harness` INT(11) DEFAULT NULL,
  `Nitrous` JSON DEFAULT NULL,
  `NeonsDisabled` BOOLEAN DEFAULT FALSE,
  `ForcedAudio` JSON DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `VIN` (`VIN`),
  KEY `RegisteredPlate` (`RegisteredPlate`),
  KEY `FakePlate` (`FakePlate`),
  KEY `Type` (`Type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

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

DROP TABLE IF EXISTS `jobs`;
CREATE TABLE IF NOT EXISTS `jobs` (
  `_id` INT AUTO_INCREMENT PRIMARY KEY,
  `Type` VARCHAR(50) NOT NULL,
  `Id` VARCHAR(100) NOT NULL,
  `Name` VARCHAR(255) NOT NULL,
  `Salary` INT NOT NULL DEFAULT 0,
  `SalaryTier` INT NOT NULL DEFAULT 1,
  `Grades` JSON DEFAULT NULL,
  `Workplaces` JSON DEFAULT NULL,
  `Data` JSON DEFAULT NULL,
  `Owner` INT DEFAULT NULL,
  `LastUpdated` INT NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_job_id` (`Id`),
  KEY `idx_type` (`Type`),
  KEY `idx_last_updated` (`LastUpdated`)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

DROP TABLE IF EXISTS `loans`;
CREATE TABLE IF NOT EXISTS `loans` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `Creation` INT NOT NULL,
  `SID` INT NOT NULL,
  `Type` VARCHAR(50) NOT NULL,
  `AssetIdentifier` VARCHAR(255) NOT NULL,
  `Defaulted` TINYINT(1) NOT NULL DEFAULT 0,
  `InterestRate` DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  `Total` INT NOT NULL DEFAULT 0,
  `Remaining` INT NOT NULL DEFAULT 0,
  `Paid` INT NOT NULL DEFAULT 0,
  `DownPayment` INT NOT NULL DEFAULT 0,
  `TotalPayments` INT NOT NULL DEFAULT 0,
  `PaidPayments` INT NOT NULL DEFAULT 0,
  `MissablePayments` INT NOT NULL DEFAULT 0,
  `MissedPayments` INT NOT NULL DEFAULT 0,
  `TotalMissedPayments` INT NOT NULL DEFAULT 0,
  `NextPayment` INT NOT NULL DEFAULT 0,
  `LastPayment` INT NOT NULL DEFAULT 0,
  `LastMissedPayment` INT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `idx_sid` (`SID`),
  KEY `idx_type` (`Type`),
  KEY `idx_asset_identifier` (`AssetIdentifier`),
  KEY `idx_remaining` (`Remaining`),
  KEY `idx_defaulted` (`Defaulted`),
  KEY `idx_next_payment` (`NextPayment`),
  KEY `idx_missed_payments` (`MissedPayments`)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

DROP TABLE IF EXISTS `loans_credit_scores`;
CREATE TABLE IF NOT EXISTS `loans_credit_scores` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `SID` INT NOT NULL,
  `Score` INT NOT NULL DEFAULT 500,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_sid` (`SID`),
  KEY `idx_score` (`Score`)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- Below needs to be worked on / formatted

-- Bank Accounts Table
CREATE TABLE IF NOT EXISTS `bank_accounts` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `Account` int(11) NOT NULL,
    `Type` varchar(50) NOT NULL DEFAULT 'personal',
    `Owner` varchar(50) NOT NULL,
    `Name` varchar(255) DEFAULT NULL,
    `Balance` decimal(15,2) NOT NULL DEFAULT 0.00,
    `JointOwners` json DEFAULT NULL,
    `JobAccess` json DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `Account` (`Account`),
    KEY `Type` (`Type`),
    KEY `Owner` (`Owner`),
    KEY `Type_Owner` (`Type`, `Owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bank Account Transactions Table
CREATE TABLE IF NOT EXISTS `bank_accounts_transactions` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `Type` varchar(50) NOT NULL,
    `Timestamp` int(11) NOT NULL,
    `Account` int(11) NOT NULL,
    `Amount` decimal(15,2) NOT NULL,
    `Title` varchar(255) NOT NULL DEFAULT 'Unknown',
    `Description` text DEFAULT NULL,
    `TransactionAccount` int(11) DEFAULT NULL,
    `Data` json DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `Account` (`Account`),
    KEY `Timestamp` (`Timestamp`),
    KEY `Type` (`Type`),
    FOREIGN KEY (`Account`) REFERENCES `bank_accounts`(`Account`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;