-- Seed data matching the batch schedule spreadsheet (IB-1 … IB-8)

USE `chess_academy`;

INSERT INTO `forms` (
  `highlight`, `batch`, `module`, `time`, `days_summary`, `day_1`, `coach_1`, `day_2`, `coach_2`, `notes`
) VALUES
  ('blue',  'IB - 1', NULL, '07.00-08.00', 'MON/TUE', 'MON', 'CHAITANY', 'TUE', 'CHAITANY', NULL),
  ('blue',  'IB - 2', NULL, '07.00-08.00', 'MON/TUE', 'MON', NULL,       'TUE', NULL,       NULL),
  ('beige', 'IB - 3', NULL, '07.00-08.00', 'MON/TUE', 'MON', NULL,       'TUE', NULL,       NULL),
  ('beige', 'IB - 4', NULL, '07.00-08.00', 'MON/TUE', 'MON', NULL,       'TUE', NULL,       NULL),
  ('blue',  'IB - 5', NULL, '07.00-08.00', 'THU/FRI', 'THU', NULL,       'FRI', NULL,       NULL),
  ('beige', 'IB - 6', NULL, '07.00-08.00', 'THU/FRI', 'THU', NULL,       'FRI', NULL,       NULL),
  ('beige', 'IB - 7', NULL, '07.00-08.00', 'THU/FRI', 'THU', NULL,       'FRI', NULL,       NULL),
  ('beige', 'IB - 8', NULL, '07.00-08.00', 'THU/FRI', 'THU', NULL,       'FRI', NULL,       NULL);
