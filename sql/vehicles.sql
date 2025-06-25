-- Vehicles System Tables
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

DROP TABLE IF EXISTS `firearms`;
CREATE TABLE IF NOT EXISTS `firearms` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,          -- Unique firearm record ID
  `Serial` VARCHAR(64) NOT NULL UNIQUE,         -- Firearm serial number
  `Item` VARCHAR(64) NOT NULL,                  -- Item name/type
  `Model` VARCHAR(128) DEFAULT NULL,            -- Model label
  `Owner` JSON DEFAULT NULL,                    -- Owner info (SID, First, Last, Company, etc.)
  `PurchaseTime` BIGINT DEFAULT NULL,           -- Purchase timestamp
  `Scratched` TINYINT(1) DEFAULT 0,             -- Is serial scratched
  `FiledByPolice` TINYINT(1) DEFAULT 0,         -- Has it been filed by police
  `PoliceWeaponId` VARCHAR(64) DEFAULT NULL,    -- Police weapon ID if filed
  `Flags` JSON DEFAULT NULL,                    -- Array of flag objects
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `firearms_projectiles`;
CREATE TABLE IF NOT EXISTS `firearms_projectiles` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,         -- Unique auto-incrementing row ID
  `EvidenceId` VARCHAR(64) NOT NULL UNIQUE,    -- Your application's unique evidence ID
  `Weapon` JSON DEFAULT NULL,                  -- Weapon info (serial, name, etc.)
  `Coords` JSON DEFAULT NULL,                  -- Coordinates where found
  `AmmoType` VARCHAR(64) DEFAULT NULL,         -- Ammo type
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1; 