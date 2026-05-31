import 'package:chess/chess.dart' as chess_lib;

import '../models/chess_game.dart';
import 'chess_engine.dart';

/// Runs the built-in engine off the UI thread when Stockfish is unavailable.
Map<String, String>? computeBuiltinMove(Map<String, dynamic> args) {
  final fen = args['fen'] as String;
  final levelIndex = args['level'] as int;
  if (levelIndex < 0 || levelIndex >= ComputerLevel.values.length) {
    return null;
  }
  final game = chess_lib.Chess.fromFEN(fen);
  return ChessEngine.pickMove(game, ComputerLevel.values[levelIndex]);
}
