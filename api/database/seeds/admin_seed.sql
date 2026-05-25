-- Default admin: admin@chessacademy.local / Admin@123456

USE `chess_academy`;

INSERT INTO `users` (`email`, `password_hash`, `role`, `first_name`, `last_name`, `phone`)
VALUES (
  'admin@chessacademy.local',
  '$2y$12$SKuVv2tv2g/JxFzGWx7RT.6Iz6BiiaGIt6g3i/VeFhsIghfWr1Age',
  'admin',
  'System',
  'Admin',
  NULL
);

-- Password is: Admin@123456
-- Generate your own: php -r "echo password_hash('YourPass', PASSWORD_BCRYPT);"

INSERT INTO `settings` (`key`, `value`) VALUES
  ('academy_name', '"Chess Academy"'),
  ('timezone', '"Asia/Kolkata"'),
  ('default_batch_fee', '1500');
