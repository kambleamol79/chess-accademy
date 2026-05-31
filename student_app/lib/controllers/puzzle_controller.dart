import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/foundation.dart';

import '../models/puzzle.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum PuzzleStatus { idle, loading, playing, wrong, solved, error }

class PuzzleController extends ChangeNotifier {
  PuzzleController(this._api, this._storage);

  final ApiService _api;
  final StorageService _storage;

  PuzzleDifficulty _level = PuzzleDifficulty.easy;
  PuzzleStatus _status = PuzzleStatus.idle;
  ChessPuzzle? _puzzle;
  String? _error;
  int _solvedCount = 0;

  late chess_lib.Chess _game;
  String _fen = '';
  List<String> _solution = [];
  int _solutionIndex = 0;
  late chess_lib.Color _playerColor;

  String? _selectedSquare;
  List<String> _legalTargets = [];
  String _message = 'Choose a level and tap Load puzzle.';

  PuzzleDifficulty get level => _level;
  PuzzleStatus get status => _status;
  ChessPuzzle? get puzzle => _puzzle;
  String? get error => _error;
  int get solvedCount => _solvedCount;
  String get fen => _fen;
  String? get selectedSquare => _selectedSquare;
  List<String> get legalTargets => List.unmodifiable(_legalTargets);
  String get message => _message;
  bool get boardFlipped => _playerColor == chess_lib.Color.BLACK;

  void setLevel(PuzzleDifficulty level) {
    if (_level == level) return;
    _level = level;
    notifyListeners();
  }

  Future<void> loadPuzzle({bool forceNew = false}) async {
    _status = PuzzleStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final storedExclude = _storage.lastPuzzleId(_level.apiValue);
      final excludeId = forceNew
          ? (_puzzle?.id ?? storedExclude)
          : storedExclude;
      final puzzle = await _api.fetchNextPuzzle(
        _level.apiValue,
        excludeId: excludeId,
      );
      if (puzzle.id == excludeId && excludeId != null) {
        final retry = await _api.fetchNextPuzzle(
          _level.apiValue,
          excludeId: puzzle.id,
        );
        _startPuzzle(retry);
        return;
      }
      _startPuzzle(puzzle);
    } catch (e) {
      _status = PuzzleStatus.error;
      _error = e.toString().replaceFirst('ApiException: ', '');
      notifyListeners();
    }
  }

  void _startPuzzle(ChessPuzzle puzzle) {
    _puzzle = puzzle;
    _storage.saveLastPuzzleId(_level.apiValue, puzzle.id);
    _solution = puzzle.solutionUci;
    _solutionIndex = 0;
    _game = chess_lib.Chess.fromFEN(puzzle.fen);
    _fen = _game.fen;
    _playerColor = _game.turn;
    _selectedSquare = null;
    _legalTargets = [];
    _status = PuzzleStatus.playing;
    _message = _playerColor == chess_lib.Color.WHITE
        ? 'White to move. Find the best continuation.'
        : 'Black to move. Find the best continuation.';
    notifyListeners();
  }

  void onSquareTap(String square) {
    if (_status != PuzzleStatus.playing) return;

    if (_selectedSquare == null) {
      _selectSquare(square);
      return;
    }

    if (square == _selectedSquare) {
      _clearSelection();
      notifyListeners();
      return;
    }

    if (_legalTargets.contains(square)) {
      _tryMove(_selectedSquare!, square);
      return;
    }

    _selectSquare(square);
  }

  void _selectSquare(String square) {
    final piece = _game.get(square);
    if (piece == null || piece.color != _game.turn) {
      _clearSelection();
      notifyListeners();
      return;
    }

    _selectedSquare = square;
    _legalTargets = _game
        .moves({'square': square, 'verbose': true})
        .map((m) => m['to'] as String)
        .toSet()
        .toList();
    notifyListeners();
  }

  void _tryMove(String from, String to) {
    final uci = _toUci(from, to);
    final expected = _solutionIndex < _solution.length ? _solution[_solutionIndex] : null;
    if (expected == null || !_uciMatches(expected, uci)) {
      _status = PuzzleStatus.wrong;
      _message = 'Not the best move. Reset and try again!';
      _clearSelection();
      notifyListeners();
      return;
    }

    _game.move({'from': from, 'to': to, 'promotion': 'q'});
    _fen = _game.fen;
    _solutionIndex++;
    _clearSelection();

    if (_solutionIndex >= _solution.length) {
      _onSolved();
      return;
    }

    _autoPlayOpponentReplies();
    _message = 'Good! Keep going…';
    notifyListeners();
  }

  void _autoPlayOpponentReplies() {
    while (_solutionIndex < _solution.length && _game.turn != _playerColor) {
      final uci = _solution[_solutionIndex];
      _applyUci(uci);
      _solutionIndex++;
      if (_solutionIndex >= _solution.length) {
        _onSolved();
        return;
      }
    }
  }

  void _applyUci(String uci) {
    if (uci.length < 4) return;
    final from = uci.substring(0, 2);
    final to = uci.substring(2, 4);
    final promo = uci.length > 4 ? uci[4] : 'q';
    _game.move({'from': from, 'to': to, 'promotion': promo});
    _fen = _game.fen;
  }

  Future<void> _onSolved() async {
    _status = PuzzleStatus.solved;
    _solvedCount++;
    _message = 'Excellent! Puzzle solved.';
    notifyListeners();

    if (_puzzle != null) {
      try {
        await _api.submitPuzzleAttempt(_puzzle!.id, true);
      } catch (_) {}
    }
  }

  void resetPuzzle() {
    if (_puzzle == null) return;
    _startPuzzle(_puzzle!);
  }

  String _toUci(String from, String to) {
    final moves = _game.moves({'verbose': true}).cast<Map<String, dynamic>>();
    for (final m in moves) {
      if (m['from'] == from && m['to'] == to) {
        final flags = m['flags'] as String? ?? '';
        if (flags.contains('p')) {
          return '${from}${to}q';
        }
        return '$from$to';
      }
    }
    return '$from$to';
  }

  bool _uciMatches(String expected, String played) {
    if (expected == played) return true;
    if (expected.length >= 4 && played.length >= 4) {
      return expected.substring(0, 4) == played.substring(0, 4);
    }
    return false;
  }

  void _clearSelection() {
    _selectedSquare = null;
    _legalTargets = [];
  }
}
