import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import 'storage_service.dart';

/// SSE or WebSocket updates for live matches.
class LiveMatchRealtime {
  LiveMatchRealtime(this._storage);

  final StorageService _storage;
  StreamSubscription<dynamic>? _wsSub;
  http.Client? _sseClient;
  Timer? _pollTimer;
  final _events = StreamController<int>.broadcast();
  int _lastSeq = 0;
  int _matchId = 0;

  Stream<int> watch(int matchId, {int sinceSeq = 0}) {
    stop();
    _matchId = matchId;
    _lastSeq = sinceSeq;

    final wsUrl = AppConfig.liveWsUrl;
    if (wsUrl.isNotEmpty) {
      _connectWs(matchId, wsUrl);
    } else {
      _connectSse(matchId, sinceSeq);
    }
    return _events.stream;
  }

  void stop() {
    _wsSub?.cancel();
    _wsSub = null;
    _sseClient?.close();
    _sseClient = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _matchId = 0;
  }

  void dispose() {
    stop();
    _events.close();
  }

  void _connectWs(int matchId, String baseUrl) {
    final token = _storage.accessToken;
    if (token == null || token.isEmpty) return;

    final uri = Uri.parse('$baseUrl?match_id=$matchId&token=${Uri.encodeComponent(token)}');
    final channel = WebSocketChannel.connect(uri);
    _wsSub = channel.stream.listen((raw) {
      try {
        final data = jsonDecode(raw as String) as Map<String, dynamic>;
        final seq = data['event_seq'] as int?;
        if (seq != null && seq > _lastSeq) {
          _lastSeq = seq;
          _events.add(seq);
        }
      } catch (_) {}
    }, onDone: () {
      if (_matchId == matchId) {
        Future.delayed(const Duration(seconds: 2), () => _connectWs(matchId, baseUrl));
      }
    });
  }

  void _connectSse(int matchId, int sinceSeq) {
    final token = _storage.accessToken;
    if (token == null) {
      _pollFallback(matchId);
      return;
    }

    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/live-matches/$matchId/stream?since=$sinceSeq&access_token=${Uri.encodeComponent(token)}',
    );
    _sseClient = http.Client();
    _sseClient!
        .send(http.Request('GET', url))
        .then((streamed) {
      streamed.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (line.startsWith('data:')) {
          try {
            final data = jsonDecode(line.substring(5).trim()) as Map<String, dynamic>;
            final seq = data['event_seq'] as int?;
            if (seq != null && seq > _lastSeq) {
              _lastSeq = seq;
              _events.add(seq);
            }
          } catch (_) {}
        }
      }, onDone: () {
        if (_matchId == matchId) {
          Future.delayed(const Duration(seconds: 2), () => _connectSse(matchId, _lastSeq));
        }
      });
    })
        .catchError((_) {
      _pollFallback(matchId);
    });
  }

  void _pollFallback(int matchId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_matchId == matchId) {
        _events.add(_lastSeq);
      }
    });
  }
}
