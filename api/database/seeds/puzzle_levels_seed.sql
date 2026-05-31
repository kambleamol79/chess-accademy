-- Extra puzzles for student app (easy / medium / hard)
USE `chess_academy`;

INSERT INTO `puzzles` (`title`, `fen`, `solution_moves`, `difficulty`, `created_by`) VALUES
(
  'Fork the king',
  'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4',
  'h5f7',
  'easy',
  1
),
(
  'Win the queen',
  'rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
  'f3g5 e8g8 g5f7',
  'medium',
  1
),
(
  'Back rank mate',
  '6k1/5ppp/8/8/8/8/5PPP/4R1K1 w - - 0 1',
  'e1e8',
  'easy',
  1
),
(
  'Smothered mate pattern',
  'rnb1kbnr/pppp1ppp/8/4q3/2B1P3/8/PPPP1PPP/RNBQK1NR w KQkq - 4 3',
  'c4f7 e8e7 f7d5',
  'hard',
  1
),
(
  'Pin and win',
  'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4',
  'c4f7 e8f7 f3g5 f7g8 g5e6',
  'hard',
  1
);
