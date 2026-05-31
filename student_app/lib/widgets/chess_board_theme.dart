import 'package:flutter/material.dart';

/// Chess.com-inspired wood board palette and decorations.
class ChessBoardTheme {
  ChessBoardTheme._();

  static const Color lightSquareA = Color(0xFFF0DEBB);
  static const Color lightSquareB = Color(0xFFE8D4A8);
  static const Color darkSquareA = Color(0xFFB58863);
  static const Color darkSquareB = Color(0xFF9B7653);

  static const Color frameOuter = Color(0xFF2A1810);
  static const Color frameInner = Color(0xFF4A3224);
  static const Color frameHighlight = Color(0xFF6B4E3A);

  static const Color coordinateOnLight = Color(0xFF8B6914);
  static const Color coordinateOnDark = Color(0xFFF0DEBB);

  static const Color playerBarBg = Color(0xCC1A120C);
  static const Color timerBg = Color(0xFF2D2118);
  static const Color timerBorder = Color(0xFF4A3828);
  static const Color playerName = Color(0xFFF5F0E8);
  static const Color playerMuted = Color(0xFFB8A898);

  static const Color selectedOverlay = Color(0xFFE9944F);
  static const Color targetDot = Color(0xFF3D7C47);
  static const Color hintOverlay = Color(0xFF7EC850);

  static LinearGradient get lightSquareGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lightSquareA, lightSquareB],
      );

  static LinearGradient get darkSquareGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [darkSquareA, darkSquareB],
      );

  static LinearGradient get frameGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [frameHighlight, frameInner, frameOuter],
      );

  static LinearGradient get playAreaGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3D2818), Color(0xFF1F140C), Color(0xFF2A1810)],
      );

  static BoxDecoration squareDecoration({
    required bool isLight,
    required bool isSelected,
    required bool isTarget,
    required bool isHint,
  }) {
    if (isSelected) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            selectedOverlay.withValues(alpha: 0.92),
            selectedOverlay.withValues(alpha: 0.75),
          ],
        ),
      );
    }
    if (isHint) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            hintOverlay.withValues(alpha: 0.55),
            hintOverlay.withValues(alpha: 0.35),
          ],
        ),
        border: Border.all(color: const Color(0xFF4ADE80), width: 2),
      );
    }
    if (isTarget) {
      return BoxDecoration(
        gradient: isLight ? lightSquareGradient : darkSquareGradient,
      );
    }
    return BoxDecoration(
      gradient: isLight ? lightSquareGradient : darkSquareGradient,
    );
  }
}
