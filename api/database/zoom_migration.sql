-- Zoom recurring meeting fields on batch schedule rows
USE `chess_academy`;

ALTER TABLE `forms`
  ADD COLUMN `zoom_join_url` VARCHAR(500) DEFAULT NULL AFTER `notes`,
  ADD COLUMN `zoom_username` VARCHAR(255) DEFAULT NULL AFTER `zoom_join_url`,
  ADD COLUMN `zoom_password` VARCHAR(100) DEFAULT NULL AFTER `zoom_username`;
