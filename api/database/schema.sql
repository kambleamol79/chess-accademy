-- Chess Academy — full schema (chess_academy)
-- forms = batch schedule spreadsheet; enrollments link students to form rows

CREATE DATABASE IF NOT EXISTS `chess_academy`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `chess_academy`;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `puzzle_attempts`;
DROP TABLE IF EXISTS `puzzles`;
DROP TABLE IF EXISTS `games`;
DROP TABLE IF EXISTS `class_materials`;
DROP TABLE IF EXISTS `form_enrollments`;
DROP TABLE IF EXISTS `invoices`;
DROP TABLE IF EXISTS `students`;
DROP TABLE IF EXISTS `coaches`;
DROP TABLE IF EXISTS `refresh_tokens`;
DROP TABLE IF EXISTS `leads`;
DROP TABLE IF EXISTS `settings`;
DROP TABLE IF EXISTS `forms`;
DROP TABLE IF EXISTS `users`;

SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------------
-- Auth
-- ---------------------------------------------------------------------------

CREATE TABLE `users` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `email` VARCHAR(255) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `role` ENUM('admin', 'coach', 'student', 'accountant') NOT NULL DEFAULT 'student',
  `first_name` VARCHAR(100) NOT NULL,
  `last_name` VARCHAR(100) NOT NULL,
  `phone` VARCHAR(20) DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_users_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `refresh_tokens` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `token_hash` VARCHAR(255) NOT NULL,
  `expires_at` DATETIME NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_refresh_user` (`user_id`),
  CONSTRAINT `fk_refresh_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Batch schedule (spreadsheet)
-- ---------------------------------------------------------------------------

CREATE TABLE `forms` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `highlight` ENUM('blue', 'beige') NOT NULL DEFAULT 'beige',
  `batch` VARCHAR(50) NOT NULL,
  `module` VARCHAR(100) DEFAULT NULL,
  `time` VARCHAR(20) NOT NULL,
  `days_summary` VARCHAR(20) NOT NULL,
  `day_1` VARCHAR(10) NOT NULL,
  `coach_1` VARCHAR(100) DEFAULT NULL,
  `day_2` VARCHAR(10) NOT NULL,
  `coach_2` VARCHAR(100) DEFAULT NULL,
  `notes` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_forms_batch` (`batch`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Profiles
-- ---------------------------------------------------------------------------

CREATE TABLE `coaches` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `title` VARCHAR(100) DEFAULT NULL,
  `bio` TEXT DEFAULT NULL,
  `rating` INT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_coaches_user` (`user_id`),
  CONSTRAINT `fk_coaches_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `students` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `parent_name` VARCHAR(150) DEFAULT NULL,
  `parent_phone` VARCHAR(20) DEFAULT NULL,
  `date_of_birth` DATE DEFAULT NULL,
  `chess_rating` INT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_students_user` (`user_id`),
  CONSTRAINT `fk_students_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `form_enrollments` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `form_id` INT UNSIGNED NOT NULL,
  `student_id` INT UNSIGNED NOT NULL,
  `enrolled_at` DATE NOT NULL,
  `status` ENUM('active', 'completed', 'dropped') NOT NULL DEFAULT 'active',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_form_student` (`form_id`, `student_id`),
  CONSTRAINT `fk_enrollment_form` FOREIGN KEY (`form_id`) REFERENCES `forms` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_enrollment_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Billing
-- ---------------------------------------------------------------------------

CREATE TABLE `invoices` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` INT UNSIGNED NOT NULL,
  `amount` DECIMAL(10, 2) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `due_date` DATE DEFAULT NULL,
  `status` ENUM('pending', 'paid', 'overdue', 'cancelled') NOT NULL DEFAULT 'pending',
  `paid_at` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_invoices_student` (`student_id`),
  CONSTRAINT `fk_invoices_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Chess training
-- ---------------------------------------------------------------------------

CREATE TABLE `puzzles` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(200) DEFAULT NULL,
  `fen` VARCHAR(100) NOT NULL,
  `solution_moves` VARCHAR(500) NOT NULL,
  `difficulty` ENUM('easy', 'medium', 'hard') NOT NULL DEFAULT 'medium',
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_puzzles_user` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `puzzle_attempts` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `puzzle_id` INT UNSIGNED NOT NULL,
  `student_id` INT UNSIGNED NOT NULL,
  `is_correct` TINYINT(1) NOT NULL DEFAULT 0,
  `attempted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_attempt_puzzle` (`puzzle_id`),
  KEY `idx_attempt_student` (`student_id`),
  CONSTRAINT `fk_attempt_puzzle` FOREIGN KEY (`puzzle_id`) REFERENCES `puzzles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_attempt_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `games` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` INT UNSIGNED NOT NULL,
  `coach_id` INT UNSIGNED DEFAULT NULL,
  `title` VARCHAR(200) DEFAULT NULL,
  `pgn` TEXT NOT NULL,
  `notes` TEXT DEFAULT NULL,
  `reviewed_at` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_games_student` (`student_id`),
  CONSTRAINT `fk_games_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_games_coach` FOREIGN KEY (`coach_id`) REFERENCES `coaches` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `class_materials` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `form_id` INT UNSIGNED NOT NULL,
  `title` VARCHAR(200) NOT NULL,
  `type` ENUM('pdf', 'video', 'link') NOT NULL DEFAULT 'link',
  `url` VARCHAR(500) NOT NULL,
  `uploaded_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_materials_form` (`form_id`),
  CONSTRAINT `fk_materials_form` FOREIGN KEY (`form_id`) REFERENCES `forms` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_materials_user` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Leads (prospective students — spreadsheet columns)
-- ---------------------------------------------------------------------------

CREATE TABLE `leads` (
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
  `status_int` VARCHAR(20) DEFAULT NULL,
  `not_interested` VARCHAR(20) DEFAULT NULL,
  `paid` VARCHAR(20) DEFAULT NULL,
  `dnp` VARCHAR(20) DEFAULT NULL,
  `additional` TEXT DEFAULT NULL,
  `review` TEXT DEFAULT NULL,
  `updated_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_leads_captured` (`captured_at`),
  CONSTRAINT `fk_leads_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `settings` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `key` VARCHAR(100) NOT NULL,
  `value` JSON NOT NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_settings_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
