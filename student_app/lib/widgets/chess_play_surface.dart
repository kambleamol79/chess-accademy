import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'chess_board_theme.dart';

/// Opponent / player strip above or below the board (Chess.com style).
class ChessPlayerBar extends StatelessWidget {
  const ChessPlayerBar({
    super.key,
    required this.name,
    this.subtitle,
    this.avatarLabel,
    this.timerText = '10:00',
    this.isActive = false,
    this.isLowTime = false,
    this.alignTimerRight = true,
  });

  final String name;
  final String? subtitle;
  final String? avatarLabel;
  final String timerText;
  final bool isActive;
  final bool isLowTime;
  final bool alignTimerRight;

  @override
  Widget build(BuildContext context) {
    final initial = (avatarLabel ?? name).isNotEmpty ? (avatarLabel ?? name)[0].toUpperCase() : '?';

    final avatar = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF4A3828),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF6B5344), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: ChessBoardTheme.playerName,
        ),
      ),
    );

    final info = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ChessBoardTheme.playerName,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: ChessBoardTheme.playerMuted,
              ),
            ),
        ],
      ),
    );

    final timer = _ChessTimerDisplay(text: timerText, isActive: isActive, isLowTime: isLowTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ChessBoardTheme.playerBarBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: alignTimerRight
            ? [avatar, const SizedBox(width: 10), info, const SizedBox(width: 8), timer]
            : [timer, const SizedBox(width: 8), avatar, const SizedBox(width: 10), info],
      ),
    );
  }
}

class _ChessTimerDisplay extends StatelessWidget {
  const _ChessTimerDisplay({
    required this.text,
    required this.isActive,
    required this.isLowTime,
  });

  final String text;
  final bool isActive;
  final bool isLowTime;

  @override
  Widget build(BuildContext context) {
    final borderColor = isLowTime
        ? const Color(0xFFEF4444)
        : isActive
            ? const Color(0xFF6EE7B7)
            : ChessBoardTheme.timerBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLowTime ? const Color(0xFF3D1F1F) : ChessBoardTheme.timerBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: borderColor,
          width: isActive || isLowTime ? 1.5 : 1,
        ),
        boxShadow: isActive && !isLowTime
            ? [
                BoxShadow(
                  color: const Color(0xFF34D399).withValues(alpha: 0.25),
                  blurRadius: 8,
                ),
              ]
            : isLowTime
                ? [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ]
                : null,
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isLowTime ? const Color(0xFFFECACA) : ChessBoardTheme.playerName,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Dark wood play area wrapping player bars and the board.
class ChessPlaySurface extends StatelessWidget {
  const ChessPlaySurface({
    super.key,
    required this.board,
    required this.topPlayer,
    required this.bottomPlayer,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget board;
  final ChessPlayerBar topPlayer;
  final ChessPlayerBar bottomPlayer;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ChessBoardTheme.playAreaGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              topPlayer,
              const SizedBox(height: 10),
              board,
              const SizedBox(height: 10),
              bottomPlayer,
            ],
          ),
        ),
      ),
    );
  }
}
