enum PracticeMode {
  freePlay('Free play', 'Move both sides freely'),
  vsComputer('Vs Stockfish', 'Play against Stockfish on your device');

  const PracticeMode(this.label, this.description);
  final String label;
  final String description;
}

enum ComputerLevel {
  beginner('Beginner', 'Stockfish ~1000 Elo', 1, 0),
  intermediate('Intermediate', 'Stockfish ~1600 Elo', 3, 2),
  advanced('Advanced', 'Full-strength Stockfish', 4, 4);

  const ComputerLevel(this.label, this.description, this.searchDepth, this.quiescenceDepth);
  final String label;
  final String description;
  final int searchDepth;
  final int quiescenceDepth;
}

/// Display name for the practice opponent.
const String academyBotName = 'Stockfish';

enum PlayerColor {
  white('White'),
  black('Black');

  const PlayerColor(this.label);
  final String label;
}

/// Per-player clock for practice games.
enum GameTimeControl {
  blitz5('5 min', 5 * 60),
  rapid10('10 min', 10 * 60),
  rapid15('15 min', 15 * 60);

  const GameTimeControl(this.label, this.seconds);
  final String label;
  final int seconds;

  int get initialMs => seconds * 1000;
}
