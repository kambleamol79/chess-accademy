import 'dart:math';

import 'package:chess/chess.dart' as chess_lib;

import '../models/chess_game.dart';

/// Minimax chess bot with piece-square tables, opening book, and quiescence search.
class ChessEngine {
  ChessEngine._();

  static final _random = Random();

  static const _pieceValues = {
    'p': 100,
    'n': 320,
    'b': 330,
    'r': 500,
    'q': 900,
    'k': 20000,
  };

  static const _files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

  /// Pawn PST (white; rank 0 = rank 8 on board).
  static const _pawnTable = [
    [0, 0, 0, 0, 0, 0, 0, 0],
    [50, 50, 50, 50, 50, 50, 50, 50],
    [10, 10, 20, 30, 30, 20, 10, 10],
    [5, 5, 10, 25, 25, 10, 5, 5],
    [0, 0, 0, 20, 20, 0, 0, 0],
    [5, -5, -10, 0, 0, -10, -5, 5],
    [5, 10, 10, -20, -20, 10, 10, 5],
    [0, 0, 0, 0, 0, 0, 0, 0],
  ];

  static const _knightTable = [
    [-50, -40, -30, -30, -30, -30, -40, -50],
    [-40, -20, 0, 0, 0, 0, -20, -40],
    [-30, 0, 10, 15, 15, 10, 0, -30],
    [-30, 5, 15, 20, 20, 15, 5, -30],
    [-30, 0, 15, 20, 20, 15, 0, -30],
    [-30, 5, 10, 15, 15, 10, 5, -30],
    [-40, -20, 0, 5, 5, 0, -20, -40],
    [-50, -40, -30, -30, -30, -30, -40, -50],
  ];

  static const _bishopTable = [
    [-20, -10, -10, -10, -10, -10, -10, -20],
    [-10, 0, 0, 0, 0, 0, 0, -10],
    [-10, 0, 5, 10, 10, 5, 0, -10],
    [-10, 5, 5, 10, 10, 5, 5, -10],
    [-10, 0, 10, 10, 10, 10, 0, -10],
    [-10, 10, 10, 10, 10, 10, 10, -10],
    [-10, 5, 0, 0, 0, 0, 5, -10],
    [-20, -10, -10, -10, -10, -10, -10, -20],
  ];

  /// Opening replies keyed by piece placement + side to move.
  static const _openingBook = <String, List<Map<String, String>>>{
    'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b': [
      {'from': 'e7', 'to': 'e5'},
      {'from': 'c7', 'to': 'c5'},
      {'from': 'e7', 'to': 'e6'},
      {'from': 'g8', 'to': 'f6'},
    ],
    'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w': [
      {'from': 'g1', 'to': 'f3'},
      {'from': 'f1', 'to': 'c4'},
      {'from': 'g1', 'to': 'e2'},
    ],
    'rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b': [
      {'from': 'b8', 'to': 'c6'},
      {'from': 'g8', 'to': 'f6'},
      {'from': 'd7', 'to': 'd6'},
    ],
    'rnbqkb1r/pppp1ppp/5n2/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w': [
      {'from': 'f3', 'to': 'e5'},
      {'from': 'd2', 'to': 'd4'},
    ],
    'rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b': [
      {'from': 'd7', 'to': 'd5'},
      {'from': 'g8', 'to': 'f6'},
    ],
    'rnbqkbnr/pppppppp/8/8/8/5N2/PPPPPPPP/RNBQKB1R b': [
      {'from': 'd7', 'to': 'd5'},
      {'from': 'g8', 'to': 'f6'},
    ],
  };

  static Map<String, String>? pickMove(chess_lib.Chess game, ComputerLevel level) {
    final moves = _legalMoves(game);
    if (moves.isEmpty) return null;

    final bookMove = _bookMove(game);
    if (bookMove != null && _isLegal(bookMove, moves)) {
      if (level == ComputerLevel.beginner && _random.nextDouble() < 0.35) {
        return _beginnerMove(moves);
      }
      return bookMove;
    }

    return switch (level) {
      ComputerLevel.beginner => _beginnerMove(moves, game: game),
      ComputerLevel.intermediate => _bestMove(game, level.searchDepth, level.quiescenceDepth),
      ComputerLevel.advanced => _bestMove(game, level.searchDepth, level.quiescenceDepth),
    };
  }

  static Map<String, String>? bestMoveForHint(chess_lib.Chess game) {
    return _bestMove(game, ComputerLevel.intermediate.searchDepth, 0);
  }

  static List<Map<String, dynamic>> _legalMoves(chess_lib.Chess game) {
    return game.moves({'verbose': true}).cast<Map<String, dynamic>>();
  }

  static bool _isLegal(Map<String, String> move, List<Map<String, dynamic>> moves) {
    return moves.any((m) => m['from'] == move['from'] && m['to'] == move['to']);
  }

  static Map<String, String>? _bookMove(chess_lib.Chess game) {
    final parts = game.fen.split(' ');
    if (parts.length < 2) return null;
    final key = '${parts[0]} ${parts[1]}';
    final options = _openingBook[key];
    if (options == null || options.isEmpty) return null;
    return options[_random.nextInt(options.length)];
  }

  static Map<String, String> _beginnerMove(
    List<Map<String, dynamic>> moves, {
    chess_lib.Chess? game,
  }) {
    if (_random.nextDouble() < 0.4) {
      final captures = moves.where((m) => m['captured'] != null).toList();
      if (captures.isNotEmpty) {
        return _moveFromVerbose(captures[_random.nextInt(captures.length)]);
      }
    }

    if (game != null && _random.nextDouble() < 0.5) {
      final ranked = _rankMoves(game, moves, depth: 1);
      if (ranked.length >= 2) {
        final pool = ranked.take(min(4, ranked.length)).toList();
        return _moveFromVerbose(pool[_random.nextInt(pool.length)]);
      }
    }

    return _moveFromVerbose(moves[_random.nextInt(moves.length)]);
  }

  static List<Map<String, dynamic>> _rankMoves(
    chess_lib.Chess game,
    List<Map<String, dynamic>> moves, {
    required int depth,
  }) {
    final scored = <(Map<String, dynamic>, int)>[];
    for (final move in moves) {
      final clone = chess_lib.Chess.fromFEN(game.fen);
      clone.move({'from': move['from'], 'to': move['to'], 'promotion': 'q'});
      scored.add((move, -_negamax(clone, depth - 1, -999999, 999999, 0)));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.map((e) => e.$1).toList();
  }

  static Map<String, String>? _bestMove(chess_lib.Chess game, int depth, int quiescenceDepth) {
    final moves = _legalMoves(game);
    if (moves.isEmpty) return null;

    Map<String, dynamic>? best;
    var bestScore = -999999;

    for (final move in moves) {
      final clone = chess_lib.Chess.fromFEN(game.fen);
      clone.move({'from': move['from'], 'to': move['to'], 'promotion': 'q'});
      final score = -_negamax(clone, depth - 1, -999999, 999999, quiescenceDepth);
      if (score > bestScore) {
        bestScore = score;
        best = move;
      }
    }

    if (best == null) return null;
    return _moveFromVerbose(best);
  }

  static Map<String, String> _moveFromVerbose(Map<String, dynamic> move) {
    return {'from': move['from'] as String, 'to': move['to'] as String};
  }

  static int _negamax(
    chess_lib.Chess game,
    int depth,
    int alpha,
    int beta,
    int quiescenceDepth,
  ) {
    if (depth == 0) {
      if (quiescenceDepth > 0) {
        return _quiescence(game, alpha, beta, quiescenceDepth);
      }
      return _evaluate(game);
    }

    final moves = _legalMoves(game);
    if (moves.isEmpty) {
      if (game.in_checkmate) {
        return -99999 + (10 - depth);
      }
      return 0;
    }

    moves.sort((a, b) => _moveOrdering(b).compareTo(_moveOrdering(a)));

    var best = -999999;
    for (final move in moves) {
      game.move({'from': move['from'], 'to': move['to'], 'promotion': 'q'});
      final score = -_negamax(game, depth - 1, -beta, -alpha, quiescenceDepth);
      game.undo();
      if (score > best) best = score;
      if (score > alpha) alpha = score;
      if (alpha >= beta) break;
    }
    return best;
  }

  static int _quiescence(chess_lib.Chess game, int alpha, int beta, int depth) {
    final standPat = _evaluate(game);
    if (standPat >= beta) return beta;
    if (standPat > alpha) alpha = standPat;

    final captures = _legalMoves(game).where((m) => m['captured'] != null).toList();
    if (captures.isEmpty || depth <= 0) return alpha;

    for (final move in captures) {
      game.move({'from': move['from'], 'to': move['to'], 'promotion': 'q'});
      final score = -_quiescence(game, -beta, -alpha, depth - 1);
      game.undo();
      if (score >= beta) return beta;
      if (score > alpha) alpha = score;
    }
    return alpha;
  }

  static int _moveOrdering(Map<String, dynamic> move) {
    final captured = move['captured'];
    if (captured == null) return 0;
    final capType = captured is chess_lib.PieceType
        ? captured.name
        : captured.toString().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    return 10000 + (_pieceValues[capType] ?? 0);
  }

  static int _evaluate(chess_lib.Chess game) {
    if (game.in_checkmate) {
      return game.turn == chess_lib.Color.WHITE ? -99999 : 99999;
    }
    if (game.in_draw || game.in_stalemate) {
      return 0;
    }

    var score = 0;

    for (var rank = 1; rank <= 8; rank++) {
      for (var fileIndex = 0; fileIndex < 8; fileIndex++) {
        final square = '${_files[fileIndex]}$rank';
        final piece = game.get(square);
        if (piece == null) continue;

        final type = piece.type.name;
        final value = _pieceValues[type] ?? 0;
        final pst = _pstValue(type, fileIndex, rank, piece.color == chess_lib.Color.WHITE);
        final sign = piece.color == chess_lib.Color.WHITE ? 1 : -1;
        score += sign * (value + pst);

        if (game.in_check && piece.type.name == 'k') {
          score += sign * -30;
        }
      }
    }

    score += game.moves().length * 4;

    return game.turn == chess_lib.Color.WHITE ? score : -score;
  }

  static int _pstValue(String type, int file, int rank, bool isWhite) {
    final tableRank = isWhite ? 8 - rank : rank - 1;
    final tableFile = file;

    return switch (type) {
      'p' => _pawnTable[tableRank][tableFile],
      'n' => _knightTable[tableRank][tableFile],
      'b' => _bishopTable[tableRank][tableFile],
      _ => 0,
    };
  }
}
