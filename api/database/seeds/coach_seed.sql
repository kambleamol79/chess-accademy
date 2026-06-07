-- Default coach: coach@chessacademy.local / Coach@123456
-- Admins can add more coaches from the Coaches screen.

USE `chess_academy`;

INSERT INTO `users` (`email`, `password_hash`, `role`, `first_name`, `last_name`, `phone`)
VALUES (
  'coach@chessacademy.local',
  '$2y$12$9.L2TzmpEF5ImkKdj/gjCeq3RAAicizS8kXYsvOL8nBysb.muYuee',
  'coach',
  'Demo',
  'Coach',
  NULL
);

INSERT INTO `coaches` (`user_id`, `title`, `bio`, `rating`)
SELECT `id`, 'Coach', NULL, NULL FROM `users` WHERE `email` = 'coach@chessacademy.local' LIMIT 1;

-- Password is: Coach@123456
