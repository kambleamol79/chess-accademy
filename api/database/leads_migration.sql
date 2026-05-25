-- Run if chess_academy already exists: mysql -u root -p chess_academy < database/leads_migration.sql

USE `chess_academy`;

CREATE TABLE IF NOT EXISTS `leads` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `captured_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `child_name` VARCHAR(150) NOT NULL,
  `parents_name` VARCHAR(150) DEFAULT NULL,
  `phone` VARCHAR(30) DEFAULT NULL,
  `email` VARCHAR(255) DEFAULT NULL,
  `age` VARCHAR(20) DEFAULT NULL,
  `std` VARCHAR(50) DEFAULT NULL,
  `city` VARCHAR(100) DEFAULT NULL,
  `q1` ENUM('Yes', 'No') DEFAULT NULL,
  `q2` ENUM('Yes', 'No') DEFAULT NULL,
  `q3` ENUM('Yes', 'No') DEFAULT NULL,
  `time_slot` VARCHAR(50) DEFAULT NULL,
  `attd_no` VARCHAR(50) DEFAULT NULL,
  `module` VARCHAR(100) DEFAULT NULL,
  `status_int` VARCHAR(20) DEFAULT NULL COMMENT 'INT when interested',
  `not_interested` VARCHAR(20) DEFAULT NULL,
  `paid` VARCHAR(20) DEFAULT NULL COMMENT 'PAID when paid',
  `dnp` VARCHAR(20) DEFAULT NULL,
  `additional` TEXT DEFAULT NULL,
  `review` TEXT DEFAULT NULL,
  `updated_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_leads_captured` (`captured_at`),
  KEY `idx_leads_child` (`child_name`),
  CONSTRAINT `fk_leads_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
