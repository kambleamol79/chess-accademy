import 'package:flutter/material.dart';

import '../controllers/practice_controller.dart';
import '../models/chess_game.dart';
import 'chess_board_core.dart';
import 'chess_play_surface.dart';

class ChessBoardWidget extends StatelessWidget {
  const ChessBoardWidget({
    super.key,
    required this.controller,
    this.playerName = 'You',
    this.opponentName = 'Opponent',
  });

  final PracticeController controller;
  final String playerName;
  final String opponentName;

  @override
  Widget build(BuildContext context) {
    final humanIsWhite = !controller.isVsComputer || controller.playerColor == PlayerColor.white;

    final topLabel = controller.isVsComputer ? academyBotName : opponentName;
    final topSubtitle = controller.isVsComputer ? controller.level.label : 'Free play';

    final showLiveClock = controller.gameActive || controller.isGameOver;

    return ChessPlaySurface(
      topPlayer: ChessPlayerBar(
        name: topLabel,
        subtitle: topSubtitle,
        avatarLabel: controller.isVsComputer ? 'B' : 'O',
        timerText: showLiveClock ? controller.topTimerText : _idleTimerLabel(controller),
        isActive: controller.topTimerActive,
        isLowTime: controller.topTimerLow,
        alignTimerRight: true,
      ),
      bottomPlayer: ChessPlayerBar(
        name: playerName,
        subtitle: humanIsWhite ? 'White' : 'Black',
        avatarLabel: playerName,
        timerText: showLiveClock ? controller.bottomTimerText : _idleTimerLabel(controller),
        isActive: controller.bottomTimerActive,
        isLowTime: controller.bottomTimerLow,
        alignTimerRight: true,
      ),
      board: ChessBoardCore(
        fen: controller.displayFen,
        boardFlipped: controller.boardFlipped,
        selectedSquare: controller.selectedSquare,
        legalTargets: controller.legalTargets,
        hintHighlightFrom: controller.hintHighlightFrom,
        hintHighlightTo: controller.hintHighlightTo,
        interactionEnabled: !controller.boardInteractionDisabled,
        onSquareTap: controller.onSquareTap,
      ),
    );
  }

  static String _idleTimerLabel(PracticeController controller) {
    final minutes = controller.timeControl.seconds ~/ 60;
    return '$minutes:00';
  }
}
