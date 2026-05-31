enum PuzzleDifficulty {
  easy('Easy', 'Beginner tactics'),
  medium('Medium', 'Intermediate combinations'),
  hard('Hard', 'Advanced calculation');

  const PuzzleDifficulty(this.label, this.description);
  final String label;
  final String description;

  String get apiValue => name;
}

class ChessPuzzle {
  ChessPuzzle({
    required this.id,
    required this.fen,
    required this.solutionMoves,
    required this.difficulty,
    this.title,
  });

  factory ChessPuzzle.fromJson(Map<String, dynamic> json) {
    return ChessPuzzle(
      id: json['id'] as int,
      fen: json['fen'] as String,
      solutionMoves: json['solution_moves'] as String,
      difficulty: json['difficulty'] as String? ?? 'medium',
      title: json['title'] as String?,
    );
  }

  final int id;
  final String fen;
  final String solutionMoves;
  final String difficulty;
  final String? title;

  List<String> get solutionUci {
    return solutionMoves
        .trim()
        .split(RegExp(r'\s+'))
        .where((m) => m.isNotEmpty)
        .map((m) => m.toLowerCase())
        .toList();
  }
}
