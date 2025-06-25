-- Loans System Tables
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