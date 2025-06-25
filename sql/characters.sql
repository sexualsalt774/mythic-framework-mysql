-- Characters System Tables
DROP TABLE IF EXISTS `characters`;
CREATE TABLE IF NOT EXISTS `characters` (
  `ID` INT(11) NOT NULL AUTO_INCREMENT,                         -- Internal unique row ID
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
  `Wardrobe` JSON DEFAULT NULL,
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