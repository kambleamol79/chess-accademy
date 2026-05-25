-- Optional sample puzzles and invoice (run after admin + forms seeds)

USE `chess_academy`;

INSERT INTO `puzzles` (`title`, `fen`, `solution_moves`, `difficulty`, `created_by`)
VALUES (
  'Mate in 1',
  'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP1PP/RNBQKBNR b KQkq - 0 1',
  'e5e4',
  'easy',
  1
);
