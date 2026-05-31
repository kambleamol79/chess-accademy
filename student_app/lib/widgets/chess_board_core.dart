import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/material.dart';

import 'chess_board_theme.dart';

typedef SquareTapCallback = void Function(String square);

/// Shared 8×8 chess grid with wood styling and coordinate labels.
class ChessBoardCore extends StatelessWidget {
  const ChessBoardCore({
    super.key,
    required this.fen,
    required this.onSquareTap,
    this.boardFlipped = false,
    this.selectedSquare,
    this.legalTargets = const [],
    this.hintHighlightFrom,
    this.hintHighlightTo,
    this.interactionEnabled = true,
    this.framePadding = 10,
  });

  final String fen;
  final SquareTapCallback onSquareTap;
  final bool boardFlipped;
  final String? selectedSquare;
  final List<String> legalTargets;
  final String? hintHighlightFrom;
  final String? hintHighlightTo;
  final bool interactionEnabled;
  final double framePadding;

  static const _files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

  @override
  Widget build(BuildContext context) {
    final game = chess_lib.Chess.fromFEN(fen);

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: EdgeInsets.all(framePadding),
        decoration: BoxDecoration(
          gradient: ChessBoardTheme.frameGradient,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: ChessBoardTheme.frameHighlight.withValues(alpha: 0.3),
              blurRadius: 2,
              offset: const Offset(-1, -1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Column(
            children: List.generate(8, (displayRowIndex) {
              final rowIndex = boardFlipped ? 7 - displayRowIndex : displayRowIndex;
              final rank = 8 - rowIndex;

              return Expanded(
                child: Row(
                  children: List.generate(8, (displayColIndex) {
                    final colIndex = boardFlipped ? 7 - displayColIndex : displayColIndex;
                    final file = _files[colIndex];
                    final square = '$file$rank';
                    final isLight = (rank + colIndex) % 2 == 1;
                    final piece = game.get(square);
                    final isSelected = selectedSquare == square;
                    final isTarget = legalTargets.contains(square);
                    final isHintFrom = hintHighlightFrom == square;
                    final isHintTo = hintHighlightTo == square;
                    final isHint = isHintFrom || isHintTo;
                    final showRank = displayColIndex == 0;
                    final showFile = displayRowIndex == 7;

                    return Expanded(
                      child: GestureDetector(
                        onTap: interactionEnabled ? () => onSquareTap(square) : null,
                        child: Container(
                          decoration: ChessBoardTheme.squareDecoration(
                            isLight: isLight,
                            isSelected: isSelected,
                            isTarget: isTarget,
                            isHint: isHint,
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              if (showRank)
                                Positioned(
                                  left: 4,
                                  top: 2,
                                  child: Text(
                                    '$rank',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isLight
                                          ? ChessBoardTheme.coordinateOnLight
                                          : ChessBoardTheme.coordinateOnDark,
                                    ),
                                  ),
                                ),
                              if (showFile)
                                Positioned(
                                  right: 4,
                                  bottom: 2,
                                  child: Text(
                                    file,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isLight
                                          ? ChessBoardTheme.coordinateOnLight
                                          : ChessBoardTheme.coordinateOnDark,
                                    ),
                                  ),
                                ),
                              Center(
                                child: piece != null
                                    ? ChessPieceGlyph(piece: piece)
                                    : isTarget
                                        ? _TargetDot(isLight: isLight)
                                        : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TargetDot extends StatelessWidget {
  const _TargetDot({required this.isLight});

  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: ChessBoardTheme.targetDot.withValues(alpha: isLight ? 0.55 : 0.7),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 3,
          ),
        ],
      ),
    );
  }
}

/// Standard Unicode chess piece with Chess.com-like contrast.
class ChessPieceGlyph extends StatelessWidget {
  const ChessPieceGlyph({super.key, required this.piece, this.fontSize = 42});

  final chess_lib.Piece piece;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final symbol = _symbol(piece);
    final isWhite = piece.color == chess_lib.Color.WHITE;

    if (isWhite) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Text(
            symbol,
            style: TextStyle(
              fontSize: fontSize,
              height: 1,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.8
                ..color = const Color(0xFF3D2B1F),
            ),
          ),
          Text(
            symbol,
            style: TextStyle(
              fontSize: fontSize,
              height: 1,
              color: const Color(0xFFFFF8EE),
              shadows: const [
                Shadow(offset: Offset(0, 1.5), blurRadius: 3, color: Color(0x55000000)),
              ],
            ),
          ),
        ],
      );
    }

    return Text(
      symbol,
      style: TextStyle(
        fontSize: fontSize,
        height: 1,
        color: const Color(0xFF1A120C),
        shadows: const [
          Shadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x44FFFFFF)),
        ],
      ),
    );
  }

  String _symbol(chess_lib.Piece piece) {
    const white = {
      'p': '♙', 'n': '♘', 'b': '♗', 'r': '♖', 'q': '♕', 'k': '♔',
    };
    const black = {
      'p': '♟', 'n': '♞', 'b': '♝', 'r': '♜', 'q': '♛', 'k': '♚',
    };
    final map = piece.color == chess_lib.Color.WHITE ? white : black;
    return map[piece.type.name] ?? '';
  }
}
