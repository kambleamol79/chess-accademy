import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// API and app configuration.
class AppConfig {
  AppConfig._();

  static const String appName = 'Brainstorm';
  static const int apiPort = 8080;
  static const String apiPath = '/api/v1';

  static const String accessTokenKey = 'ca_access_token';
  static const String refreshTokenKey = 'ca_refresh_token';
  static const String userKey = 'ca_user';
  static const String lastPuzzlePrefix = 'ca_last_puzzle_';

  /// WebSocket URL for live matches. Empty = use SSE stream from API.
  static String get liveWsUrl {
    const v = String.fromEnvironment('LIVE_WS_URL');
    if (v.isNotEmpty) return v;
    return '';
  }

  /// Full API base URL. Override with `--dart-define=API_URL=...` or
  /// `--dart-define=API_HOST=192.168.x.x` (physical device on same Wi‑Fi).
  static String get apiBaseUrl {
    const fullOverride = String.fromEnvironment('API_URL');
    if (fullOverride.isNotEmpty) return fullOverride;

    final host = _apiHost;
    return 'http://$host:$apiPort$apiPath';
  }

  static String get _apiHost {
    const hostOverride = String.fromEnvironment('API_HOST');
    if (hostOverride.isNotEmpty) return hostOverride;

    return 'https://alphasynctechnology.com/chess_backend/';
  }

  /// User-friendly hint when the API cannot be reached.
  static String get connectionHelp {
    if (kIsWeb) {
      return 'Start the API: cd api && php -S localhost:8080 -t public';
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'Start the API on your Mac:\n'
          '  cd api && php -S 0.0.0.0:8080 -t public\n\n'
          'Emulator: flutter run (uses 10.0.2.2 automatically)\n'
          'Physical phone (Wi‑Fi): flutter run --dart-define=API_HOST=YOUR_MAC_IP\n'
          'Physical phone (USB): adb reverse tcp:8080 tcp:8080 then '
          'flutter run --dart-define=API_HOST=127.0.0.1';
    }
    if (!kIsWeb && Platform.isIOS) {
      return 'Start the API on your Mac:\n'
          '  cd api && php -S 0.0.0.0:8080 -t public\n\n'
          'Simulator: flutter run (uses localhost)\n'
          'Physical iPhone: same Wi‑Fi, then\n'
          '  flutter run --dart-define=API_HOST=YOUR_MAC_IP';
    }
    return 'Start the API: cd api && php -S 0.0.0.0:8080 -t public';
  }
}
