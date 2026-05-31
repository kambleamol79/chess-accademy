import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/material.dart';

import '../controllers/puzzle_controller.dart';
import 'chess_board_core.dart';
import 'chess_play_surface.dart';

class PuzzleBoardWidget extends StatelessWidget {
  const PuzzleBoardWidget({
    super.key,
    required this.controller,
    this.playerName = 'You',
  });

  final PuzzleController controller;
  final String playerName;

  @override
  Widget build(BuildContext context) {
    final game = chess_lib.Chess.fromFEN(controller.fen);
    final sideToMove = game.turn == chess_lib.Color.WHITE ? 'White' : 'Black';

    return ChessPlaySurface(
      topPlayer: ChessPlayerBar(
        name: 'Puzzle',
        subtitle: 'Find the best move',
        avatarLabel: '?',
        timerText: '—',
        alignTimerRight: true,
      ),
      bottomPlayer: ChessPlayerBar(
        name: playerName,
        subtitle: '$sideToMove to move',
        avatarLabel: playerName,
        isActive: true,
        alignTimerRight: true,
      ),
      board: ChessBoardCore(
        fen: controller.fen,
        boardFlipped: controller.boardFlipped,
        selectedSquare: controller.selectedSquare,
        legalTargets: controller.legalTargets,
        onSquareTap: controller.onSquareTap,
      ),
    );
  }
}
