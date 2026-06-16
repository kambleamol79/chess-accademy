-- Add student tournament CTA settings (safe to run multiple times).

INSERT INTO `settings` (`key`, `value`) VALUES
  ('today_tournament_url', '"https://www.chess.com/play/arena/31279193"'),
  ('today_tournament_label', '"Today''s tournament"'),
  ('today_tournament_timezone', '"Asia/Kolkata"'),
  ('today_tournament_visible_from', '""'),
  ('today_tournament_visible_until', '""')
ON DUPLICATE KEY UPDATE `key` = `key`;
