-- Dealership System Tables
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