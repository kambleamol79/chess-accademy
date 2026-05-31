-- Zoom recurring meeting fields on batch schedule rows
USE `chess_academy`;

ALTER TABLE `forms`
  ADD COLUMN `zoom_meeting_id` VARCHAR(50) DEFAULT NULL AFTER `notes`,
  ADD COLUMN `zoom_join_url` VARCHAR(500) DEFAULT NULL AFTER `zoom_meeting_id`,
  ADD COLUMN `zoom_start_url` VARCHAR(500) DEFAULT NULL AFTER `zoom_join_url`,
  ADD COLUMN `zoom_password` VARCHAR(20) DEFAULT NULL AFTER `zoom_start_url`;
