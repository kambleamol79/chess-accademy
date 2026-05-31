-- Live student vs student chess + scheduled tournaments

USE `chess_academy`;

CREATE TABLE IF NOT EXISTS `chess_tournaments` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(200) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `starts_at` DATETIME NOT NULL,
  `time_control_minutes` TINYINT UNSIGNED NOT NULL DEFAULT 10,
  `status` ENUM('scheduled', 'registration', 'active', 'finished', 'cancelled') NOT NULL DEFAULT 'scheduled',
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_chess_tournaments_starts` (`starts_at`),
  KEY `idx_chess_tournaments_status` (`status`),
  CONSTRAINT `fk_chess_tournaments_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `chess_tournament_entries` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tournament_id` INT UNSIGNED NOT NULL,
  `student_id` INT UNSIGNED NOT NULL,
  `score` DECIMAL(5, 1) NOT NULL DEFAULT 0,
  `joined_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_tournament_student` (`tournament_id`, `student_id`),
  CONSTRAINT `fk_tournament_entries_tournament` FOREIGN KEY (`tournament_id`) REFERENCES `chess_tournaments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tournament_entries_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `chess_live_matches` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tournament_id` INT UNSIGNED DEFAULT NULL,
  `white_student_id` INT UNSIGNED NOT NULL,
  `black_student_id` INT UNSIGNED NOT NULL,
  `status` ENUM('waiting', 'active', 'completed', 'abandoned') NOT NULL DEFAULT 'waiting',
  `result` ENUM('pending', 'white_win', 'black_win', 'draw') NOT NULL DEFAULT 'pending',
  `time_control_minutes` TINYINT UNSIGNED NOT NULL DEFAULT 10,
  `white_ms_remaining` INT UNSIGNED NOT NULL DEFAULT 600000,
  `black_ms_remaining` INT UNSIGNED NOT NULL DEFAULT 600000,
  `clock_side` ENUM('w', 'b') DEFAULT NULL,
  `clock_since` DATETIME DEFAULT NULL,
  `start_fen` VARCHAR(120) NOT NULL DEFAULT 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
  `current_fen` VARCHAR(120) NOT NULL,
  `started_at` DATETIME DEFAULT NULL,
  `ended_at` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_live_matches_tournament` (`tournament_id`),
  KEY `idx_live_matches_status` (`status`),
  CONSTRAINT `fk_live_matches_tournament` FOREIGN KEY (`tournament_id`) REFERENCES `chess_tournaments` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_live_matches_white` FOREIGN KEY (`white_student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_live_matches_black` FOREIGN KEY (`black_student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `chess_live_moves` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `match_id` INT UNSIGNED NOT NULL,
  `ply` SMALLINT UNSIGNED NOT NULL,
  `uci` VARCHAR(12) NOT NULL,
  `san` VARCHAR(16) NOT NULL,
  `color` ENUM('w', 'b') NOT NULL,
  `student_id` INT UNSIGNED NOT NULL,
  `fen_after` VARCHAR(120) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_live_moves_match_ply` (`match_id`, `ply`),
  KEY `idx_live_moves_match` (`match_id`),
  CONSTRAINT `fk_live_moves_match` FOREIGN KEY (`match_id`) REFERENCES `chess_live_matches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_live_moves_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `chess_matchmaking_queue` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` INT UNSIGNED NOT NULL,
  `tournament_id` INT UNSIGNED DEFAULT NULL,
  `joined_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_queue_student` (`student_id`),
  KEY `idx_queue_tournament` (`tournament_id`),
  CONSTRAINT `fk_queue_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_queue_tournament` FOREIGN KEY (`tournament_id`) REFERENCES `chess_tournaments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
