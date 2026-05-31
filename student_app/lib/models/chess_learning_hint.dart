enum HintKind {
  greatMove,
  alternative,
  nextMove,
}

class ChessLearningHint {
  ChessLearningHint({
    required this.kind,
    required this.title,
    required this.message,
    this.suggestedSan,
    this.playedSan,
    this.highlightFrom,
    this.highlightTo,
  });

  final HintKind kind;
  final String title;
  final String message;
  final String? suggestedSan;
  final String? playedSan;
  final String? highlightFrom;
  final String? highlightTo;
}
