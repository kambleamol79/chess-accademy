import 'dart:async';

import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/foundation.dart';

import '../models/live_match.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class LiveMatchController extends ChangeNotifier {
  LiveMatchController(this._api, this.matchId);

  final ApiService _api;
  final int matchId;

  bool loading = true;
  String? error;
  bool submitting = false;
  LiveMatchState? state;
  String displayFen = '';
  String? selectedSquare;
  List<String> legalTargets = [];

  chess_lib.Chess _game = chess_lib.Chess();
  Timer? _pollTimer;
  int _lastPly = 0;
  int _lastEventSeq = 0;

  bool get boardFlipped => state?.yourColor == 'black';
  bool get boardDisabled =>
      state == null || state!.match.status != 'active' || !state!.isYourTurn || submitting;

  String get statusLine {
    final s = state;
    if (s == null) return '';
    if (s.match.status == 'completed') return 'Game over — ${s.match.result}';
    return s.isYourTurn ? 'Your turn' : "Opponent's turn";
  }

  String formatMs(int ms) {
    final total = (ms / 1000).floor().clamp(0, 99999);
    final m = total ~/ 60;
    final sec = total % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  String get topTimerText {
    final s = state!;
    final ms = boardFlipped ? s.whiteMsRemaining : s.blackMsRemaining;
    return formatMs(ms);
  }

  String get bottomTimerText {
    final s = state!;
    final ms = boardFlipped ? s.blackMsRemaining : s.whiteMsRemaining;
    return formatMs(ms);
  }

  bool get topTimerActive => state!.match.status == 'active' && !state!.isYourTurn;
  bool get bottomTimerActive => state!.match.status == 'active' && state!.isYourTurn;

  String get topName => boardFlipped ? state!.match.whiteName : state!.match.blackName;
  String get bottomName => boardFlipped ? state!.match.blackName : state!.match.whiteName;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final st = await _api.fetchLiveMatch(matchId);
      _applyState(st);
      loading = false;
      notifyListeners();
      _rtSub?.cancel();
      await _syncIfChanged();
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
        if (!submitting) _syncIfChanged();
      });
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _refresh() async {
    try {
      final st = await _api.fetchLiveMatch(matchId);
      _applyState(st);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _syncIfChanged() async {
    try {
      final rev = await _api.fetchLiveMatchRevision(matchId, sinceSeq: _lastEventSeq);
      if (!rev.changed) return;
      if (rev.state != null) {
        _applyState(rev.state!);
        notifyListeners();
        return;
      }
      await _refresh();
    } catch (_) {}
  }

  void _applyState(LiveMatchState st) {
    if (st.eventSeq != null) {
      _lastEventSeq = st.eventSeq!;
    }
    state = st;
    final ply = st.moves.length;
    if (ply != _lastPly || st.match.currentFen != displayFen) {
      _lastPly = ply;
      try {
        _game = chess_lib.Chess.fromFEN(st.match.currentFen);
      } catch (_) {
        _game = chess_lib.Chess();
      }
      displayFen = st.match.currentFen;
    }
    selectedSquare = null;
    legalTargets = [];
  }

  void onSquareTap(String square) {
    if (boardDisabled) return;
    final yourColor = state!.yourColor == 'white' ? 'w' : 'b';

    if (selectedSquare == null) {
      final piece = _game.get(square);
      if (piece == null) return;
      final isWhite = piece.color == chess_lib.Color.WHITE;
      if ((yourColor == 'w' && !isWhite) || (yourColor == 'b' && isWhite)) return;
      if ((yourColor == 'w' && _game.turn != chess_lib.Color.WHITE) ||
          (yourColor == 'b' && _game.turn != chess_lib.Color.BLACK)) {
        return;
      }
      selectedSquare = square;
      legalTargets = _game
          .moves({'square': square, 'verbose': true})
          .map((m) => m['to'] as String)
          .toSet()
          .toList();
      notifyListeners();
      return;
    }

    if (selectedSquare == square) {
      selectedSquare = null;
      legalTargets = [];
      notifyListeners();
      return;
    }

    if (legalTargets.contains(square)) {
      _playMove(selectedSquare!, square);
      return;
    }

    selectedSquare = null;
    legalTargets = [];
    onSquareTap(square);
  }

  Future<void> _playMove(String from, String to) async {
    submitting = true;
    selectedSquare = null;
    legalTargets = [];
    notifyListeners();

    final ok = _game.move({'from': from, 'to': to, 'promotion': 'q'});
    if (!ok) {
      submitting = false;
      notifyListeners();
      return;
    }

    final uci = '$from$to';
    final history = _game.history;
    final last = history.isNotEmpty ? history.last : null;
    final san = last is String ? last : (last is Map ? (last['san'] as String? ?? uci) : uci);

    try {
      final st = await _api.playLiveMove(
        matchId,
        uci: uci,
        san: san,
        fenAfter: _game.fen,
      );
      _applyState(st);
      error = null;
    } catch (e) {
      error = 'Move rejected';
      await _refresh();
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  Future<void> resign() async {
    try {
      final st = await _api.resignLiveMatch(matchId);
      _applyState(st);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
