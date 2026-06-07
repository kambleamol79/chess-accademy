-- Manual Zoom details for batch schedule rows
USE `chess_academy`;

ALTER TABLE `forms`
  ADD COLUMN `zoom_username` VARCHAR(255) DEFAULT NULL AFTER `zoom_start_url`,
  MODIFY COLUMN `zoom_password` VARCHAR(100) DEFAULT NULL;
