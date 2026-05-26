-- Student roster columns (spreadsheet layout). Run once on existing DB:
-- mysql -u root -p chess_academy < api/database/students_roster_migration.sql

USE `chess_academy`;

ALTER TABLE `students`
  ADD COLUMN `city` VARCHAR(100) DEFAULT NULL AFTER `chess_rating`,
  ADD COLUMN `level` VARCHAR(50) DEFAULT NULL AFTER `city`,
  ADD COLUMN `payment_date` DATE DEFAULT NULL AFTER `level`,
  ADD COLUMN `w_app` VARCHAR(30) DEFAULT NULL AFTER `payment_date`,
  ADD COLUMN `total_pay` VARCHAR(50) DEFAULT NULL AFTER `w_app`,
  ADD COLUMN `payment_received` VARCHAR(50) DEFAULT NULL AFTER `total_pay`,
  ADD COLUMN `month_jan` VARCHAR(50) DEFAULT NULL AFTER `payment_received`,
  ADD COLUMN `month_feb` VARCHAR(50) DEFAULT NULL AFTER `month_jan`,
  ADD COLUMN `month_mar` VARCHAR(50) DEFAULT NULL AFTER `month_feb`,
  ADD COLUMN `month_apr` VARCHAR(50) DEFAULT NULL AFTER `month_mar`,
  ADD COLUMN `month_may` VARCHAR(50) DEFAULT NULL AFTER `month_apr`,
  ADD COLUMN `month_jun` VARCHAR(50) DEFAULT NULL AFTER `month_may`,
  ADD COLUMN `month_jul` VARCHAR(50) DEFAULT NULL AFTER `month_jun`,
  ADD COLUMN `month_aug` VARCHAR(50) DEFAULT NULL AFTER `month_jul`,
  ADD COLUMN `month_sep` VARCHAR(50) DEFAULT NULL AFTER `month_aug`;
