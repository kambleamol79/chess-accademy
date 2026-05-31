import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/live_match.dart';
import '../services/api_service.dart';

class ArenaController extends ChangeNotifier {
  ArenaController(this._api);

  final ApiService _api;

  bool loading = true;
  String? error;
  String message = '';
  List<ChessTournament> tournaments = [];
  List<LiveMatchSummary> matches = [];
  bool finding = false;
  int? matchedMatchId;

  void clearPendingMatch() {
    matchedMatchId = null;
  }

  Timer? _queuePoll;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final all = await _api.fetchChessTournaments();
      tournaments = all
          .where((t) => t.status != 'finished' && t.status != 'cancelled')
          .toList();
      final mine = await _api.fetchMyLiveMatches();
      matches = mine.matches;
      loading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  Future<void> register(ChessTournament t) async {
    try {
      await _api.registerChessTournament(t.id);
      message = 'Registered for ${t.title}';
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<int?> findOpponent({int? tournamentId, int timeControl = 10}) async {
    finding = true;
    error = null;
    message = 'Looking for an opponent…';
    notifyListeners();
    try {
      final res = await _api.joinLiveQueue(
        tournamentId: tournamentId,
        timeControlMinutes: timeControl,
      );
      if (res.status == 'matched' && res.matchId != null) {
        _stopQueuePoll();
        finding = false;
        notifyListeners();
        return res.matchId;
      }
      _startQueuePoll(tournamentId, timeControl);
      return null;
    } catch (e) {
      finding = false;
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void cancelFind() {
    _stopQueuePoll();
    finding = false;
    message = '';
    _api.leaveLiveQueue();
    notifyListeners();
  }

  void _startQueuePoll(int? tournamentId, int timeControl) {
    _stopQueuePoll();
    _queuePoll = Timer.periodic(const Duration(milliseconds: 2500), (_) async {
      try {
        final res = await _api.joinLiveQueue(
          tournamentId: tournamentId,
          timeControlMinutes: timeControl,
        );
        if (res.status == 'matched' && res.matchId != null) {
          _stopQueuePoll();
          finding = false;
          matchedMatchId = res.matchId;
          message = 'Opponent found!';
          notifyListeners();
        }
      } catch (_) {}
    });
  }

  void _stopQueuePoll() {
    _queuePoll?.cancel();
    _queuePoll = null;
  }

  @override
  void dispose() {
    _stopQueuePoll();
    super.dispose();
  }
}
