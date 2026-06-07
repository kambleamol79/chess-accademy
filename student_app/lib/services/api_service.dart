import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/batch.dart';
import '../models/practice_session.dart';
import '../models/puzzle.dart';
import '../models/chess_game.dart';
import '../models/payment.dart';
import '../models/reminder.dart';
import '../models/support_ticket.dart';
import '../models/batch_message.dart';
import '../models/user.dart';
import '../models/live_match.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
  ApiService(this._storage);

  final StorageService _storage;

  Map<String, String> get _headers {
    final token = _storage.accessToken;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<http.Response> _get(String path) async {
    try {
      return await http.get(_uri(path), headers: _headers);
    } on SocketException {
      throw ApiException(_connectionMessage());
    } on http.ClientException catch (e) {
      throw ApiException(_clientErrorMessage(e));
    }
  }

  Future<http.Response> _patch(String path, {Map<String, dynamic>? body}) async {
    try {
      return await http.patch(
        _uri(path),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
    } on SocketException {
      throw ApiException(_connectionMessage());
    } on http.ClientException catch (e) {
      throw ApiException(_clientErrorMessage(e));
    }
  }

  Future<http.Response> _delete(String path, {Map<String, dynamic>? body}) async {
    try {
      return await http.delete(
        _uri(path),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
    } on SocketException {
      throw ApiException(_connectionMessage());
    } on http.ClientException catch (e) {
      throw ApiException(_clientErrorMessage(e));
    }
  }

  Future<http.Response> _post(String path, {Map<String, dynamic>? body}) async {
    try {
      return await http.post(
        _uri(path),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
    } on SocketException {
      throw ApiException(_connectionMessage());
    } on http.ClientException catch (e) {
      throw ApiException(_clientErrorMessage(e));
    }
  }

  String _clientErrorMessage(http.ClientException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('connection refused') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection failed')) {
      return _connectionMessage();
    }
    return e.message;
  }

  String _connectionMessage() =>
      'Cannot reach API at ${AppConfig.apiBaseUrl}.\n${AppConfig.connectionHelp}';

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Invalid server response', statusCode: response.statusCode);
    }

    if (response.statusCode >= 400 || body['success'] != true) {
      throw ApiException(
        body['message'] as String? ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }

    return body;
  }

  Future<AuthTokens> login(String email, String password) async {
    final response = await _post('/auth/login', body: {'email': email, 'password': password});
    final body = await _decode(response);
    return AuthTokens.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<User> fetchMe() async {
    final response = await _get('/auth/me');
    final body = await _decode(response);
    return User.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<StudentBatch?> fetchMyBatch() async {
    final response = await _get('/students/me/batch');
    final body = await _decode(response);
    final data = body['data'] as Map<String, dynamic>;
    final batch = data['batch'];
    if (batch == null) return null;
    return StudentBatch.fromJson(batch as Map<String, dynamic>);
  }

  Future<PaymentHistory> fetchPayments() async {
    final response = await _get('/students/me/payments');
    final body = await _decode(response);
    return PaymentHistory.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<Reminder>> fetchReminders() async {
    final response = await _get('/students/me/reminders');
    final body = await _decode(response);
    final data = body['data'] as Map<String, dynamic>;
    return (data['reminders'] as List<dynamic>? ?? [])
        .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SupportTicket>> fetchMySupportTickets() async {
    final response = await _get('/students/me/support-tickets');
    final body = await _decode(response);
    final data = body['data'] as Map<String, dynamic>;
    return (data['tickets'] as List<dynamic>? ?? [])
        .map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SupportTicketDetail> fetchSupportTicket(int id) async {
    final response = await _get('/students/me/support-tickets/$id');
    final body = await _decode(response);
    final data = body['data'] as Map<String, dynamic>;
    return SupportTicketDetail(
      ticket: SupportTicket.fromJson(data['ticket'] as Map<String, dynamic>),
      messages: (data['messages'] as List<dynamic>? ?? [])
          .map((e) => SupportTicketMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> createSupportTicket({required String subject, required String body}) async {
    final response = await _post('/students/me/support-tickets', body: {
      'subject': subject,
      'body': body,
    });
    await _decode(response);
  }

  Future<void> replySupportTicket(int ticketId, String body) async {
    final response = await _post('/students/me/support-tickets/$ticketId/messages', body: {
      'body': body,
    });
    await _decode(response);
  }

  Future<BatchMessagesResult> fetchMyBatchMessages() async {
    final response = await _get('/students/me/batch-messages');
    final body = await _decode(response);
    final data = body['data'] as Map<String, dynamic>;
    return BatchMessagesResult(
      formId: data['form_id'] as int?,
      messages: (data['messages'] as List<dynamic>? ?? [])
          .map((e) => BatchMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> registerDeviceToken({required String token, required String platform}) async {
    final response = await _post('/students/me/device-token', body: {
      'token': token,
      'platform': platform,
    });
    await _decode(response);
  }

  Future<void> unregisterDeviceToken(String token) async {
    final response = await http.delete(
      _uri('/students/me/device-token'),
      headers: _headers,
      body: jsonEncode({'token': token}),
    );
    await _decode(response);
  }

  Future<ChessPuzzle> fetchNextPuzzle(String difficulty, {int? excludeId}) async {
    final query = StringBuffer('/puzzles/next?difficulty=$difficulty');
    if (excludeId != null && excludeId > 0) {
      query.write('&exclude=$excludeId');
    }
    query.write('&_=${DateTime.now().millisecondsSinceEpoch}');
    final response = await _get(query.toString());
    final body = await _decode(response);
    final data = body['data'] as Map<String, dynamic>;
    return ChessPuzzle.fromJson(data['puzzle'] as Map<String, dynamic>);
  }

  Future<void> submitPuzzleAttempt(int puzzleId, bool isCorrect) async {
    final response = await _post(
      '/puzzles/$puzzleId/attempt',
      body: {'is_correct': isCorrect},
    );
    await _decode(response);
  }

  Future<List<PracticeSessionSummary>> fetchPracticeSessions({int limit = 40}) async {
    final response = await _get('/practice-sessions?limit=$limit');
    final body = await _decode(response);
    final data = body['data'] as Map<String, dynamic>;
    return (data['sessions'] as List<dynamic>? ?? [])
        .map((e) => PracticeSessionSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PracticeSessionDetail> fetchPracticeSession(int id) async {
    final response = await _get('/practice-sessions/$id');
    final body = await _decode(response);
    return PracticeSessionDetail.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<PracticeSessionSummary> createPracticeSession({
    required PracticeMode mode,
    ComputerLevel? level,
    required PlayerColor playerColor,
    required int timeControlMinutes,
    required String startFen,
  }) async {
    final response = await _post('/practice-sessions', body: {
      'mode': mode == PracticeMode.vsComputer ? 'vs_computer' : 'free_play',
      'level': level?.name,
      'player_color': playerColor == PlayerColor.white ? 'white' : 'black',
      'time_control_minutes': timeControlMinutes,
      'start_fen': startFen,
    });
    final body = await _decode(response);
    final data = body['data'] as Map<String, dynamic>;
    return PracticeSessionSummary.fromJson(data['session'] as Map<String, dynamic>);
  }

  Future<void> addPracticeMove(int sessionId, PracticeGameMoveRecord move) async {
    final response = await _post('/practice-sessions/$sessionId/moves', body: move.toJson());
    await _decode(response);
  }

  Future<void> deleteLastPracticeMove(int sessionId) async {
    final response = await _delete('/practice-sessions/$sessionId/moves/last');
    await _decode(response);
  }

  Future<void> finalizePracticeSession(int sessionId, String result) async {
    final response = await _patch('/practice-sessions/$sessionId', body: {'result': result});
    await _decode(response);
  }

  Future<List<ChessTournament>> fetchChessTournaments() async {
    final response = await _get('/chess-tournaments');
    final body = await _decode(response);
    final data = body['data'] as Map<String, dynamic>;
    return (data['tournaments'] as List<dynamic>? ?? [])
        .map((e) => ChessTournament.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> registerChessTournament(int id) async {
    final response = await _post('/chess-tournaments/$id/register', body: {});
    await _decode(response);
  }

  Future<MyMatchesResult> fetchMyLiveMatches() async {
    final response = await _get('/live-matches/mine');
    final body = await _decode(response);
    final data = body['data'] as Map<String, dynamic>;
    return MyMatchesResult(
      matches: (data['matches'] as List<dynamic>? ?? [])
          .map((e) => LiveMatchSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeMatchId: data['active_match_id'] as int?,
    );
  }

  Future<LiveMatchState> fetchLiveMatch(int id) async {
    final response = await _get('/live-matches/$id');
    final body = await _decode(response);
    return LiveMatchState.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<LiveMatchRevision> fetchLiveMatchRevision(int id, {int sinceSeq = 0}) async {
    final response = await _get('/live-matches/$id/revision?since=$sinceSeq');
    final body = await _decode(response);
    return LiveMatchRevision.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<LiveMatchState> playLiveMove(
    int matchId, {
    required String uci,
    required String san,
    required String fenAfter,
  }) async {
    final response = await _post('/live-matches/$matchId/moves', body: {
      'uci': uci,
      'san': san,
      'fen_after': fenAfter,
    });
    final body = await _decode(response);
    return LiveMatchState.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<LiveMatchState> resignLiveMatch(int id) async {
    final response = await _post('/live-matches/$id/resign', body: {});
    final body = await _decode(response);
    return LiveMatchState.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<QueueJoinResult> joinLiveQueue({int? tournamentId, int timeControlMinutes = 10}) async {
    final body = <String, dynamic>{'time_control_minutes': timeControlMinutes};
    if (tournamentId != null) body['tournament_id'] = tournamentId;
    final response = await _post('/live-matches/queue', body: body);
    final decoded = await _decode(response);
    final data = decoded['data'] as Map<String, dynamic>;
    return QueueJoinResult(
      status: data['status'] as String? ?? 'waiting',
      matchId: data['match_id'] as int? ?? (data['match'] as Map<String, dynamic>?)?['id'] as int?,
    );
  }

  Future<void> leaveLiveQueue({int? tournamentId}) async {
    final body = tournamentId != null ? {'tournament_id': tournamentId} : null;
    final response = await _delete('/live-matches/queue', body: body);
    await _decode(response);
  }

  Future<void> logout() async {
    final refresh = _storage.refreshToken;
    if (refresh != null) {
      try {
        await _post('/auth/logout', body: {'refresh_token': refresh});
      } catch (_) {}
    }
    await _storage.clearSession();
  }
}

class SupportTicketDetail {
  SupportTicketDetail({required this.ticket, required this.messages});

  final SupportTicket ticket;
  final List<SupportTicketMessage> messages;
}

class BatchMessagesResult {
  BatchMessagesResult({required this.formId, required this.messages});

  final int? formId;
  final List<BatchMessage> messages;
}
