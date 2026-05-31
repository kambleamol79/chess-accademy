import 'dart:async';
import 'dart:math';

import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/foundation.dart';

import '../models/chess_game.dart';
import '../models/chess_learning_hint.dart';
import '../models/practice_session.dart';
import '../services/api_service.dart';
import '../services/chess_learning_service.dart';
import '../services/stockfish_service.dart';

enum PracticeScreenTab { board, saved }

class PracticeController extends ChangeNotifier {
  PracticeController(this._stockfish, this._api) {
    resetBoard();
    _stockfish.ensureReady();
    loadSavedSessions();
  }

  final StockfishService _stockfish;
  final ApiService _api;

  late chess_lib.Chess _game;
  String _fen = '';
  String? _selectedSquare;
  List<String> _legalTargets = [];
  List<PracticeGameMoveRecord> _gameHistory = [];
  List<String> _positionFens = [];
  int? _replayIndex;
  List<PracticeSessionSummary> _savedSessions = [];
  bool _loadingSavedSessions = false;
  int? _viewingSavedSessionId;
  PracticeScreenTab _screenTab = PracticeScreenTab.board;
  int? _dbSessionId;
  final List<PracticeGameMoveRecord> _pendingDbMoves = [];
  String _statusMessage = 'Choose settings and tap Start Game.';

  PracticeMode _mode = PracticeMode.vsComputer;
  ComputerLevel _level = ComputerLevel.beginner;
  PlayerColor _playerColor = PlayerColor.white;
  GameTimeControl _timeControl = GameTimeControl.rapid10;
  bool _aiThinking = false;
  bool _learningHintsEnabled = true;
  bool _gameActive = false;
  ChessLearningHint? _lastHint;

  int _whiteMs = GameTimeControl.rapid10.initialMs;
  int _blackMs = GameTimeControl.rapid10.initialMs;
  chess_lib.Color? _clockSide;
  DateTime? _clockSince;
  Timer? _clockTicker;
  bool _flaggedOnTime = false;
  chess_lib.Color? _timeWinner;

  String get fen => _fen;
  String? get selectedSquare => _selectedSquare;
  List<String> get legalTargets => List.unmodifiable(_legalTargets);
  List<PracticeGameMoveRecord> get gameHistory => List.unmodifiable(_gameHistory);
  List<PracticeSessionSummary> get savedSessions => List.unmodifiable(_savedSessions);
  bool get loadingSavedSessions => _loadingSavedSessions;
  int? get viewingSavedSessionId => _viewingSavedSessionId;
  bool get isViewingSavedSession => _viewingSavedSessionId != null;
  PracticeScreenTab get screenTab => _screenTab;

  void setScreenTab(PracticeScreenTab tab) {
    if (_screenTab == tab) return;
    _screenTab = tab;
    notifyListeners();
  }
  bool get isReplayMode => _replayIndex != null;
  bool get canReplayPrevious => _replayIndex != null && _replayIndex! > 0;
  bool get canReplayNext =>
      _replayIndex != null && _replayIndex! < _positionFens.length - 1;
  String get replayCaption {
    if (_replayIndex == null) return '';
    if (_replayIndex == 0) return 'Start position';
    if (_replayIndex! <= _gameHistory.length) {
      final entry = _gameHistory[_replayIndex! - 1];
      return 'After ${_replayIndex}. ${entry.san}';
    }
    return 'Position $_replayIndex';
  }

  String get displayFen {
    if (_replayIndex == null) return _fen;
    if (_replayIndex! >= 0 && _replayIndex! < _positionFens.length) {
      return _positionFens[_replayIndex!];
    }
    return _fen;
  }

  bool get boardInteractionDisabled =>
      isViewingSavedSession || !_gameActive || isGameOver || _aiThinking || isReplayMode;

  String get statusMessage => _statusMessage;
  bool get isGameOver => _game.game_over || _flaggedOnTime;
  bool get gameActive => _gameActive;
  PracticeMode get mode => _mode;
  ComputerLevel get level => _level;
  PlayerColor get playerColor => _playerColor;
  GameTimeControl get timeControl => _timeControl;
  bool get aiThinking => _aiThinking;
  bool get isVsComputer => _mode == PracticeMode.vsComputer;
  bool get boardFlipped => isVsComputer && _playerColor == PlayerColor.black;
  bool get learningHintsEnabled => _learningHintsEnabled;
  ChessLearningHint? get lastHint => _lastHint;
  String? get hintHighlightFrom => _lastHint?.highlightFrom;
  String? get hintHighlightTo => _lastHint?.highlightTo;
  bool get canStartGame => isVsComputer && !_gameActive && !_aiThinking;
  bool get canEndGame => _gameActive;
  bool get canUndo =>
      _gameActive &&
      !_aiThinking &&
      !isReplayMode &&
      _gameHistory.isNotEmpty &&
      (!isGameOver || isVsComputer);
  String get engineLabel => _stockfish.engineLabel;

  /// Bottom bar clock (human side of the screen).
  String get bottomTimerText => _formatMs(_displayMsForBar(bottom: true));

  /// Top bar clock (opponent side of the screen).
  String get topTimerText => _formatMs(_displayMsForBar(bottom: false));

  bool get bottomTimerActive => _isBarClockActive(bottom: true);

  bool get topTimerActive => _isBarClockActive(bottom: false);

  bool get bottomTimerLow => _displayMsForBar(bottom: true) <= 20000;

  bool get topTimerLow => _displayMsForBar(bottom: false) <= 20000;

  chess_lib.Color get _humanColor =>
      _playerColor == PlayerColor.white ? chess_lib.Color.WHITE : chess_lib.Color.BLACK;

  chess_lib.Color get _computerColor =>
      _humanColor == chess_lib.Color.WHITE ? chess_lib.Color.BLACK : chess_lib.Color.WHITE;

  @override
  void dispose() {
    _finalizeCurrentSession('ended');
    _stopClock();
    _clockTicker?.cancel();
    super.dispose();
  }

  Future<void> loadSavedSessions() async {
    _loadingSavedSessions = true;
    notifyListeners();
    try {
      _savedSessions = await _api.fetchPracticeSessions();
    } catch (_) {
      _savedSessions = [];
    }
    _loadingSavedSessions = false;
    notifyListeners();
  }

  Future<void> openSavedSession(int id) async {
    try {
      final detail = await _api.fetchPracticeSession(id);
      _viewingSavedSessionId = id;
      _gameActive = false;
      _gameHistory = List.from(detail.moves);
      _positionFens = [detail.session.startFen, ...detail.moves.map((m) => m.fenAfter)];
      _replayIndex = detail.moves.length;
      _fen = _positionFens.last;
      _statusMessage = 'Saved game · ${detail.session.label}';
      _screenTab = PracticeScreenTab.board;
      notifyListeners();
    } catch (_) {}
  }

  void exitSavedSessionView() {
    _viewingSavedSessionId = null;
    _screenTab = PracticeScreenTab.board;
    resetBoard();
  }

  void goToReplayIndex(int index) {
    final max = _positionFens.length - 1;
    _replayIndex = index.clamp(0, max);
    _clearSelection();
    notifyListeners();
  }

  void returnToLive() {
    _replayIndex = null;
    _clearSelection();
    notifyListeners();
  }

  void replayPrevious() {
    if (_replayIndex == null) {
      goToReplayIndex(_positionFens.length - 1);
      return;
    }
    if (_replayIndex! > 0) goToReplayIndex(_replayIndex! - 1);
  }

  void replayNext() {
    if (_replayIndex != null && _replayIndex! < _positionFens.length - 1) {
      goToReplayIndex(_replayIndex! + 1);
    }
  }

  bool isHistoryMoveActive(int ply) => _replayIndex == ply;

  void setMode(PracticeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    resetBoard();
  }

  void setLevel(ComputerLevel level) {
    if (_level == level) return;
    _level = level;
    notifyListeners();
  }

  void setTimeControl(GameTimeControl control) {
    if (_timeControl == control || _gameActive) return;
    _timeControl = control;
    _resetClocks();
    notifyListeners();
  }

  void setPlayerColor(PlayerColor color) {
    if (_playerColor == color) return;
    _playerColor = color;
    resetBoard();
  }

  void setLearningHintsEnabled(bool enabled) {
    if (_learningHintsEnabled == enabled) return;
    _learningHintsEnabled = enabled;
    if (!enabled) _lastHint = null;
    notifyListeners();
  }

  void resetBoard() {
    _finalizeCurrentSession('ended');
    _viewingSavedSessionId = null;
    _stopClock();
    _game = chess_lib.Chess();
    _fen = _game.fen;
    _selectedSquare = null;
    _legalTargets = [];
    _initPositionTrail();
    _aiThinking = false;
    _lastHint = null;
    _flaggedOnTime = false;
    _timeWinner = null;
    _gameActive = _mode == PracticeMode.freePlay;
    _resetClocks();
    _updateStatus();
    notifyListeners();

    if (_gameActive) {
      _startDbSession(() {
        _syncClockToTurn();
        if (isVsComputer && _game.turn == _computerColor) {
          _scheduleComputerMove();
        } else {
          _refreshOpeningHint();
        }
      });
    }
  }

  void endGame() {
    if (!canEndGame) return;
    _finalizeCurrentSession('ended');
    _stopClock();
    _gameActive = false;
    _aiThinking = false;
    _clearSelection();
    _statusMessage = isVsComputer
        ? 'Game ended. Tap Start game to play again.'
        : 'Game ended. Tap New game to play again.';
    notifyListeners();
  }

  void startGame() {
    if (!isVsComputer || _gameActive || _aiThinking) return;

    _finalizeCurrentSession('ended');
    _viewingSavedSessionId = null;
    _game = chess_lib.Chess();
    _fen = _game.fen;
    _selectedSquare = null;
    _legalTargets = [];
    _initPositionTrail();
    _lastHint = null;
    _flaggedOnTime = false;
    _timeWinner = null;
    _gameActive = true;
    _resetClocks();
    _updateStatus();
    notifyListeners();

    _startDbSession(() {
      _syncClockToTurn();
      notifyListeners();
      if (_game.turn == _computerColor) {
        _scheduleComputerMove();
      } else {
        _refreshOpeningHint();
      }
    });
  }

  void undoMove() {
    if (!_gameActive || _aiThinking || isReplayMode) return;

    _stopClock();

    if (isVsComputer) {
      if (_gameHistory.isEmpty) return;
      _game.undo();
      _popLastRecordedMove();
      if (_gameHistory.isNotEmpty && _game.turn == _computerColor) {
        _game.undo();
        _popLastRecordedMove();
      }
    } else {
      if (_game.undo() == null) return;
      if (_gameHistory.isNotEmpty) _popLastRecordedMove();
    }

    _fen = _game.fen;
    _replayIndex = null;
    _clearSelection();
    _lastHint = null;
    _flaggedOnTime = false;
    _timeWinner = null;
    _updateStatus();
    if (!isGameOver) _syncClockToTurn();
    _refreshOpeningHint();
    notifyListeners();
  }

  void onSquareTap(String square) {
    if (boardInteractionDisabled) return;
    if (isVsComputer && _game.turn == _computerColor) return;

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
      _makeMove(_selectedSquare!, square);
      return;
    }

    _selectSquare(square);
  }

  void _selectSquare(String square) {
    final piece = _game.get(square);
    if (piece == null) {
      _clearSelection();
      notifyListeners();
      return;
    }

    if (isVsComputer) {
      if (piece.color != _humanColor || _game.turn != _humanColor) {
        _clearSelection();
        notifyListeners();
        return;
      }
    } else {
      final isWhiteTurn = _game.turn == chess_lib.Color.WHITE;
      final isWhitePiece = piece.color == chess_lib.Color.WHITE;
      if (isWhiteTurn != isWhitePiece) {
        _clearSelection();
        notifyListeners();
        return;
      }
    }

    _selectedSquare = square;
    _legalTargets = _game
        .moves({'square': square, 'verbose': true})
        .map((move) => move['to'] as String)
        .toSet()
        .toList();
    notifyListeners();
  }

  void _makeMove(String from, String to) {
    final before = chess_lib.Chess.fromFEN(_game.fen);
    final mover = _game.turn;
    final isHumanMove = !isVsComputer || mover == _humanColor;

    final ok = _game.move({'from': from, 'to': to, 'promotion': 'q'});
    if (!ok) {
      _statusMessage = 'Illegal move.';
      _clearSelection();
      notifyListeners();
      return;
    }

    _fen = _game.fen;
    _recordMove('$from$to', player: 'human');
    _clearSelection();

    if (_learningHintsEnabled && isHumanMove) {
      _lastHint = ChessLearningService.feedbackOnMove(before, from, to);
    }

    _afterMovePlayed();
    notifyListeners();

    if (isVsComputer && !_game.game_over && !_flaggedOnTime && _game.turn == _computerColor) {
      _scheduleComputerMove();
    }
  }

  Future<void> _scheduleComputerMove() async {
    _aiThinking = true;
    _statusMessage = "$academyBotName's turn…";
    notifyListeners();

    final fenSnapshot = _game.fen;

    try {
      final move = await _stockfish.pickMove(fenSnapshot, _level);

      if (!_gameActive || _fen != fenSnapshot) return;

      if (move != null && !_game.game_over && !_flaggedOnTime) {
        final promo = move['promotion'] ?? 'q';
        final ok = _game.move({
          'from': move['from'],
          'to': move['to'],
          'promotion': promo,
        });
        if (ok) {
          _fen = _game.fen;
          _recordMove('${move['from']}${move['to']}', player: 'opponent');
          _afterMovePlayed();
        }
      }

      if (_learningHintsEnabled && !_game.game_over && !_flaggedOnTime && _game.turn == _humanColor) {
        _lastHint = ChessLearningService.suggestForPosition(_game);
      }
    } finally {
      _aiThinking = false;
      _updateStatus();
      notifyListeners();
    }
  }

  void _afterMovePlayed() {
    if (_flaggedOnTime || _game.game_over) {
      _stopClock();
      _finalizeCurrentSession(_inferSessionResult());
      _updateStatus();
      return;
    }
    _syncClockToTurn();
    _updateStatus();
  }

  void _refreshOpeningHint() {
    if (!_learningHintsEnabled || _game.game_over || !_gameActive || _flaggedOnTime) return;
    if (isVsComputer && _game.turn != _humanColor) return;
    _lastHint = ChessLearningService.suggestForPosition(_game);
    notifyListeners();
  }

  void _resetClocks() {
    _whiteMs = _timeControl.initialMs;
    _blackMs = _timeControl.initialMs;
    _clockSide = null;
    _clockSince = null;
  }

  void _syncClockToTurn() {
    if (!_gameActive || isGameOver) {
      _stopClock();
      return;
    }
    _startClockFor(_game.turn);
  }

  void _startClockFor(chess_lib.Color side) {
    _stopClock();
    _clockSide = side;
    _clockSince = DateTime.now();
    _clockTicker ??= Timer.periodic(const Duration(milliseconds: 200), (_) => _onClockTick());
  }

  void _stopClock() {
    if (_clockSide == null || _clockSince == null) return;

    final elapsed = DateTime.now().difference(_clockSince!).inMilliseconds;
    if (_clockSide == chess_lib.Color.WHITE) {
      _whiteMs = max(0, _whiteMs - elapsed);
    } else {
      _blackMs = max(0, _blackMs - elapsed);
    }
    _clockSide = null;
    _clockSince = null;
    _checkTimeForfeit();
  }

  void _onClockTick() {
    if (!_gameActive || isGameOver || _clockSide == null) return;

    final remaining = _remainingMs(_clockSide!);
    if (remaining <= 0) {
      _onTimeForfeit(_clockSide == chess_lib.Color.WHITE ? chess_lib.Color.BLACK : chess_lib.Color.WHITE);
      return;
    }
    notifyListeners();
  }

  void _checkTimeForfeit() {
    if (_whiteMs <= 0) {
      _onTimeForfeit(chess_lib.Color.BLACK);
    } else if (_blackMs <= 0) {
      _onTimeForfeit(chess_lib.Color.WHITE);
    }
  }

  void _onTimeForfeit(chess_lib.Color winner) {
    _stopClock();
    _clockTicker?.cancel();
    _clockTicker = null;
    _flaggedOnTime = true;
    _timeWinner = winner;
    _finalizeCurrentSession(_inferSessionResult());
    _updateStatus();
    notifyListeners();
  }

  int _remainingMs(chess_lib.Color side) {
    final base = side == chess_lib.Color.WHITE ? _whiteMs : _blackMs;
    if (_clockSide != side || _clockSince == null) return base;
    final elapsed = DateTime.now().difference(_clockSince!).inMilliseconds;
    return max(0, base - elapsed);
  }

  /// [bottom] = human side of the screen (not necessarily White).
  int _displayMsForBar({required bool bottom}) {
    final bottomIsWhite = !boardFlipped;
    final side = (bottom == bottomIsWhite) ? chess_lib.Color.WHITE : chess_lib.Color.BLACK;
    return _remainingMs(side);
  }

  bool _isBarClockActive({required bool bottom}) {
    if (isReplayMode || !_gameActive || isGameOver || _clockSide == null) return false;
    final bottomIsWhite = !boardFlipped;
    final side = (bottom == bottomIsWhite) ? chess_lib.Color.WHITE : chess_lib.Color.BLACK;
    return _clockSide == side;
  }

  static String _formatMs(int ms) {
    final totalSec = max(0, (ms + 999) ~/ 1000);
    final minutes = totalSec ~/ 60;
    final seconds = totalSec % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _updateStatus() {
    if (_aiThinking) return;

    if (_flaggedOnTime && _timeWinner != null) {
      if (isVsComputer) {
        final youWin = _timeWinner == _humanColor;
        _statusMessage = youWin
            ? 'Time! You win on the clock.'
            : 'Time! $academyBotName wins on the clock.';
      } else {
        final winner = _timeWinner == chess_lib.Color.WHITE ? 'White' : 'Black';
        _statusMessage = 'Time! $winner wins on the clock.';
      }
      return;
    }

    if (!_gameActive) {
      final engine = _stockfish.isStockfishActive ? 'Stockfish' : _stockfish.engineLabel;
      _statusMessage = isVsComputer
          ? 'Tap Start Game — $engine (${_level.label}, ${_timeControl.label}).'
          : 'Free play (${_timeControl.label}).';
      return;
    }

    if (_game.in_checkmate) {
      if (isVsComputer) {
        final youWin = (_game.turn == chess_lib.Color.WHITE && _playerColor == PlayerColor.black) ||
            (_game.turn == chess_lib.Color.BLACK && _playerColor == PlayerColor.white);
        _statusMessage = youWin ? 'Checkmate! You beat $academyBotName!' : 'Checkmate! $academyBotName wins.';
      } else {
        final winner = _game.turn == chess_lib.Color.WHITE ? 'Black' : 'White';
        _statusMessage = 'Checkmate! $winner wins.';
      }
    } else if (_game.in_draw || _game.in_stalemate) {
      _statusMessage = 'Draw.';
    } else if (_game.in_check) {
      _statusMessage = isVsComputer && _game.turn == _humanColor
          ? 'Check! Your move.'
          : 'Check!';
    } else if (isVsComputer) {
      _statusMessage = _game.turn == _humanColor
          ? 'Your move (${_playerColor.label}).'
          : '$academyBotName (${_level.label}) to move…';
    } else {
      _statusMessage =
          _game.turn == chess_lib.Color.WHITE ? 'White to move.' : 'Black to move.';
    }
  }

  void _clearSelection() {
    _selectedSquare = null;
    _legalTargets = [];
  }

  void _initPositionTrail() {
    _positionFens = [_game.fen];
    _gameHistory = [];
    _replayIndex = null;
  }

  void _recordMove(String uci, {required String player}) {
    final san = _game.history.isNotEmpty ? _game.history.last.toString() : uci;
    final moverColor = _game.turn == chess_lib.Color.WHITE ? 'b' : 'w';
    final entry = PracticeGameMoveRecord(
      ply: _gameHistory.length + 1,
      san: san,
      uci: uci,
      color: moverColor,
      player: player,
      fenAfter: _game.fen,
    );
    _gameHistory.add(entry);
    _positionFens.add(_game.fen);
    _replayIndex = null;
    _persistMove(entry);
  }

  void _popLastRecordedMove() {
    if (_gameHistory.isNotEmpty) _gameHistory.removeLast();
    if (_positionFens.length > 1) _positionFens.removeLast();
    _persistUndo();
  }

  void _startDbSession(void Function() onReady) {
    _pendingDbMoves.clear();
    _api
        .createPracticeSession(
          mode: _mode,
          level: isVsComputer ? _level : null,
          playerColor: _playerColor,
          timeControlMinutes: _timeControl.seconds ~/ 60,
          startFen: _game.fen,
        )
        .then((session) {
      _dbSessionId = session.id;
      for (final move in List<PracticeGameMoveRecord>.from(_pendingDbMoves)) {
        _persistMove(move);
      }
      _pendingDbMoves.clear();
      onReady();
    }).catchError((_) {
      _dbSessionId = null;
      _pendingDbMoves.clear();
      onReady();
    });
  }

  void _finalizeCurrentSession(String result) {
    final id = _dbSessionId;
    if (id == null) return;
    _dbSessionId = null;
    _api.finalizePracticeSession(id, result).then((_) => loadSavedSessions()).catchError((_) {});
  }

  void _persistMove(PracticeGameMoveRecord entry) {
    final id = _dbSessionId;
    if (id == null) {
      _pendingDbMoves.add(entry);
      return;
    }
    _api.addPracticeMove(id, entry).catchError((_) {});
  }

  void _persistUndo() {
    final id = _dbSessionId;
    if (id == null) return;
    _api.deleteLastPracticeMove(id).catchError((_) {});
  }

  String _inferSessionResult() {
    if (_flaggedOnTime && _timeWinner != null) {
      return _timeWinner == _humanColor ? 'timeout_win' : 'timeout_loss';
    }
    if (_game.in_draw || _game.in_stalemate) return 'draw';
    if (_game.in_checkmate && isVsComputer) {
      final youWin = (_game.turn == chess_lib.Color.WHITE && _playerColor == PlayerColor.black) ||
          (_game.turn == chess_lib.Color.BLACK && _playerColor == PlayerColor.white);
      return youWin ? 'win' : 'loss';
    }
    return 'ended';
  }

  int practiceMoveNumber(PracticeGameMoveRecord entry) {
    return entry.color == 'w' ? ((entry.ply + 1) ~/ 2) : (entry.ply ~/ 2);
  }
}
