-- Practice game history (CRM + mobile). Run against chess_academy.

USE `chess_academy`;

CREATE TABLE IF NOT EXISTS `practice_sessions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `mode` ENUM('vs_computer', 'free_play') NOT NULL DEFAULT 'vs_computer',
  `level` VARCHAR(20) DEFAULT NULL,
  `player_color` ENUM('white', 'black') NOT NULL DEFAULT 'white',
  `time_control_minutes` TINYINT UNSIGNED NOT NULL DEFAULT 10,
  `start_fen` VARCHAR(120) NOT NULL,
  `result` ENUM('ongoing', 'win', 'loss', 'draw', 'ended', 'timeout_win', 'timeout_loss') NOT NULL DEFAULT 'ongoing',
  `ended_at` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_practice_sessions_user_created` (`user_id`, `created_at` DESC),
  CONSTRAINT `fk_practice_sessions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `practice_moves` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `session_id` INT UNSIGNED NOT NULL,
  `ply` SMALLINT UNSIGNED NOT NULL,
  `san` VARCHAR(16) NOT NULL,
  `uci` VARCHAR(12) NOT NULL,
  `color` ENUM('w', 'b') NOT NULL,
  `player` ENUM('human', 'opponent') NOT NULL,
  `fen_after` VARCHAR(120) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_practice_moves_session_ply` (`session_id`, `ply`),
  KEY `idx_practice_moves_session` (`session_id`),
  CONSTRAINT `fk_practice_moves_session` FOREIGN KEY (`session_id`) REFERENCES `practice_sessions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
