-- Payment receipt + lead source on students. Run once:
-- mysql -u root -p chess_academy < api/database/leads_payment_migration.sql

USE `chess_academy`;

ALTER TABLE `students`
  ADD COLUMN `payment_receipt_path` VARCHAR(255) DEFAULT NULL AFTER `month_sep`,
  ADD COLUMN `source_lead_id` INT UNSIGNED DEFAULT NULL AFTER `payment_receipt_path`,
  ADD KEY `idx_students_source_lead` (`source_lead_id`);
