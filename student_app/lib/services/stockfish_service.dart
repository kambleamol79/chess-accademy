import 'dart:async';

import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/foundation.dart';

import '../models/chess_game.dart';
import 'chess_bot_worker.dart';
import 'chess_engine.dart';
import 'stockfish_adapter.dart';

/// On-device Stockfish (UCI) with fast fallback to the built-in engine.
class StockfishService extends ChangeNotifier {
  StockfishAdapter? _engine;
  StreamSubscription<String>? _stdoutSub;
  Completer<String>? _bestMoveCompleter;
  Completer<void>? _readyOkCompleter;

  bool _ready = false;
  bool _initAbandoned = false;
  bool _initializing = false;
  Future<void>? _initFuture;
  bool _disposed = false;

  Future<void>? _searchChain = Future.value();

  bool get isNativeSupported {
    if (kIsWeb) return false;
    return StockfishAdapter.isSupported;
  }

  bool get isStockfishActive => _ready && isNativeSupported && !_initAbandoned;

  String get engineLabel => isStockfishActive ? 'Stockfish' : 'Built-in engine';

  Future<void> ensureReady() {
    if (_ready || _initAbandoned || _disposed || !isNativeSupported) {
      return Future.value();
    }
    if (_initializing) return _initFuture!;
    _initializing = true;
    _initFuture = _initialize();
    return _initFuture!;
  }

  Future<void> _initialize() async {
    if (!isNativeSupported) {
      _initAbandoned = true;
      _initializing = false;
      notifyListeners();
      return;
    }

    try {
      final uciOk = Completer<void>();
      final readyOk = Completer<void>();

      final engine = StockfishAdapter();
      await engine.start().timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw TimeoutException('Stockfish start'),
          );
      _engine = engine;

      _stdoutSub = _engine!.stdout.listen((line) {
        final trimmed = line.trim();
        if (trimmed == 'uciok' && !uciOk.isCompleted) uciOk.complete();
        if (trimmed == 'readyok') {
          if (!readyOk.isCompleted) readyOk.complete();
          if (_readyOkCompleter != null && !_readyOkCompleter!.isCompleted) {
            _readyOkCompleter!.complete();
            _readyOkCompleter = null;
          }
        }
        if (trimmed.startsWith('bestmove ') &&
            _bestMoveCompleter != null &&
            !_bestMoveCompleter!.isCompleted) {
          _bestMoveCompleter!.complete(trimmed);
          _bestMoveCompleter = null;
        }
      });

      _engine!.stdin = 'uci';
      await uciOk.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw TimeoutException('Stockfish uciok'),
      );

      _engine!.stdin = 'isready';
      await readyOk.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Stockfish readyok'),
      );

      _ready = true;
    } catch (_) {
      _initAbandoned = true;
      await _tearDownEngine();
      _ready = false;
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  void _send(String command) {
    final engine = _engine;
    if (engine == null || !_ready) return;
    try {
      engine.stdin = command;
    } catch (_) {
      _initAbandoned = true;
      _ready = false;
    }
  }

  Future<void> _waitReadyOk({Duration timeout = const Duration(seconds: 3)}) async {
    _readyOkCompleter = Completer<void>();
    _send('isready');
    try {
      await _readyOkCompleter!.future.timeout(timeout);
    } catch (_) {
      _readyOkCompleter = null;
    }
  }

  void _configureLevel(ComputerLevel level) {
    if (level == ComputerLevel.advanced) {
      _send('setoption name UCI_LimitStrength value false');
    } else {
      _send('setoption name UCI_LimitStrength value true');
      _send('setoption name UCI_Elo value ${level.stockfishElo}');
    }
    _send('setoption name Skill Level value ${level.stockfishSkill}');
  }

  Future<Map<String, String>?> pickMove(String fen, ComputerLevel level) {
    return _enqueueSearch(() => _pickMoveWithFallback(fen, level));
  }

  Future<Map<String, String>?> _pickMoveWithFallback(String fen, ComputerLevel level) async {
    if (_initAbandoned || !isNativeSupported) {
      return _builtinMove(fen, level);
    }

    try {
      await ensureReady().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          _initAbandoned = true;
        },
      );
    } catch (_) {
      _initAbandoned = true;
    }

    if (!_ready || _engine == null) {
      return _builtinMove(fen, level);
    }

    final ms = level.stockfishMovetimeMs;
    try {
      final move = await _pickMoveStockfish(fen, level).timeout(
        Duration(milliseconds: ms + 6000),
        onTimeout: () => null,
      );
      if (move != null) return move;
    } catch (_) {
      // fall through to built-in engine
    }

    return _builtinMove(fen, level);
  }

  Future<Map<String, String>?> _pickMoveStockfish(String fen, ComputerLevel level) async {
    _configureLevel(level);
    _send('position fen $fen');
    await _waitReadyOk();

    _bestMoveCompleter = Completer<String>();
    _send('go movetime ${level.stockfishMovetimeMs}');

    final line = await _bestMoveCompleter!.future.timeout(
      Duration(milliseconds: level.stockfishMovetimeMs + 4000),
      onTimeout: () {
        _send('stop');
        if (_bestMoveCompleter != null && !_bestMoveCompleter!.isCompleted) {
          _bestMoveCompleter!.complete('bestmove (none)');
        }
        return 'bestmove (none)';
      },
    );

    return _parseBestMove(line);
  }

  Future<Map<String, String>?> _builtinMove(String fen, ComputerLevel level) async {
    try {
      return await compute(computeBuiltinMove, {
        'fen': fen,
        'level': level.index,
      });
    } catch (_) {
      return ChessEngine.pickMove(chess_lib.Chess.fromFEN(fen), level);
    }
  }

  Future<Map<String, String>?> _enqueueSearch(
    Future<Map<String, String>?> Function() search,
  ) {
    final run = _searchChain!.then((_) => search());
    _searchChain = run.then((_) {}, onError: (_) {});
    return run;
  }

  static Map<String, String>? _parseBestMove(String line) {
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length < 2 || parts[1] == '(none)') return null;

    final uci = parts[1];
    if (uci.length < 4) return null;

    return {
      'from': uci.substring(0, 2),
      'to': uci.substring(2, 4),
      'promotion': uci.length > 4 ? uci.substring(4) : 'q',
    };
  }

  Future<void> _tearDownEngine() async {
    _bestMoveCompleter = null;
    _readyOkCompleter = null;
    await _stdoutSub?.cancel();
    _stdoutSub = null;
    try {
      _engine?.dispose();
    } catch (_) {}
    _engine = null;
    _ready = false;
  }

  @override
  void dispose() {
    _disposed = true;
    _tearDownEngine();
    super.dispose();
  }
}

extension StockfishLevel on ComputerLevel {
  int get stockfishElo => switch (this) {
        ComputerLevel.beginner => 1000,
        ComputerLevel.intermediate => 1600,
        ComputerLevel.advanced => 2200,
      };

  int get stockfishSkill => switch (this) {
        ComputerLevel.beginner => 3,
        ComputerLevel.intermediate => 10,
        ComputerLevel.advanced => 20,
      };

  int get stockfishMovetimeMs => switch (this) {
        ComputerLevel.beginner => 300,
        ComputerLevel.intermediate => 600,
        ComputerLevel.advanced => 1200,
      };
}
