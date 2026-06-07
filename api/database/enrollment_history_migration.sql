-- Allow multiple enrollment rows per student/batch (history via status).
-- Run once: mysql -u root -p chess_academy < api/database/enrollment_history_migration.sql

USE `chess_academy`;

ALTER TABLE `form_enrollments`
  DROP INDEX `uk_form_student`,
  ADD KEY `idx_enrollment_student_status` (`student_id`, `status`),
  ADD KEY `idx_enrollment_form_status` (`form_id`, `status`);
