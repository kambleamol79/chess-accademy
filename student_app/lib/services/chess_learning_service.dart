import 'package:chess/chess.dart' as chess_lib;

import '../models/chess_learning_hint.dart';
import 'chess_engine.dart';

/// Generates educational hints after moves for student practice.
class ChessLearningService {
  ChessLearningService._();

  static const _centerSquares = {'d4', 'd5', 'e4', 'e5', 'c4', 'c5', 'f4', 'f5'};

  /// Feedback on the move the student just played.
  static ChessLearningHint feedbackOnMove(
    chess_lib.Chess beforeMove,
    String from,
    String to,
  ) {
    final played = _findVerboseMove(beforeMove, from, to);
    final best = ChessEngine.bestMoveForHint(beforeMove);
    final playedSan = played?['san'] as String? ?? '$from$to';

    if (best != null && best['from'] == from && best['to'] == to) {
      return ChessLearningHint(
        kind: HintKind.greatMove,
        title: 'Great move!',
        message: _explainMove(played, beforeMove.get(from)),
        suggestedSan: playedSan,
        highlightFrom: from,
        highlightTo: to,
      );
    }

    final bestSan = best != null
        ? (_findVerboseMove(beforeMove, best['from']!, best['to']!)['san'] as String? ?? '${best['from']}${best['to']}')
        : null;

    if (bestSan == null) {
      return ChessLearningHint(
        kind: HintKind.alternative,
        title: 'Learning tip',
        message: 'You played $playedSan. ${_explainMove(played, beforeMove.get(from))}',
        playedSan: playedSan,
      );
    }

    final bestVerbose = _findVerboseMove(beforeMove, best!['from']!, best!['to']!);

    return ChessLearningHint(
      kind: HintKind.alternative,
      title: 'Learning tip',
      message:
          'You played $playedSan. A strong alternative was $bestSan — ${_explainMove(bestVerbose, beforeMove.get(best['from']!))}',
      suggestedSan: bestSan,
      highlightFrom: best['from'],
      highlightTo: best['to'],
      playedSan: playedSan,
    );
  }

  /// Suggestion for the side to move in the current position.
  static ChessLearningHint? suggestForPosition(chess_lib.Chess game) {
    if (game.game_over) return null;

    final best = ChessEngine.bestMoveForHint(game);
    if (best == null) return null;
    return hintFromBestMove(game, best);
  }

  static ChessLearningHint hintFromBestMove(
    chess_lib.Chess game,
    Map<String, String> best,
  ) {
    final verbose = _findVerboseMove(game, best['from']!, best['to']!);
    final san = verbose['san'] as String? ?? '${best['from']}${best['to']}';

    return ChessLearningHint(
      kind: HintKind.nextMove,
      title: 'Suggestion for your next move',
      message: 'Consider $san — ${_explainMove(verbose, game.get(best['from']!))}',
      suggestedSan: san,
      highlightFrom: best['from'],
      highlightTo: best['to'],
    );
  }

  static Map<String, dynamic> _findVerboseMove(chess_lib.Chess game, String from, String to) {
    final moves = game.moves({'verbose': true}).cast<Map<String, dynamic>>();
    for (final move in moves) {
      if (move['from'] == from && move['to'] == to) {
        return move;
      }
    }
    return {'from': from, 'to': to, 'san': '$from$to'};
  }

  static String _explainMove(Map<String, dynamic>? move, chess_lib.Piece? piece) {
    if (move == null) return 'Keep developing pieces and control the center.';

    final flags = move['flags'] as String? ?? '';
    final to = move['to'] as String? ?? '';
    final captured = move['captured'];

    if (flags.contains('k') || flags.contains('q')) {
      return 'Castling improves king safety and connects your rooks.';
    }
    if (captured != null) {
      return 'Capturing material can win points — always check if the capture is safe.';
    }
    if (flags.contains('p')) {
      return 'Promoting a pawn is powerful — aim to push passed pawns.';
    }
    if (_centerSquares.contains(to)) {
      return 'Placing a piece toward the center increases control of the board.';
    }

    final type = piece?.type.name ?? '';
    if (type == 'p') {
      return 'Pawn moves open lines for your pieces — think about what opens next.';
    }
    if (type == 'n' || type == 'b') {
      return 'Developing knights and bishops early helps you castle faster.';
    }
    if (type == 'r') {
      return 'Rooks belong on open files where they can support your attack.';
    }
    if (type == 'q') {
      return 'Use the queen actively but avoid bringing her out too early without support.';
    }

    return 'Look for moves that improve piece activity and king safety.';
  }
}
