import 'dart:io' show Platform;

import 'package:stockfish/stockfish.dart';

class StockfishAdapter {
  Stockfish? _engine;

  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  Stream<String> get stdout => _engine?.stdout ?? const Stream.empty();

  Future<void> start() async {
    if (!isSupported) {
      return;
    }
    _engine = await stockfishAsync();
  }

  set stdin(String command) {
    _engine?.stdin = command;
  }

  void dispose() {
    _engine?.dispose();
    _engine = null;
  }
}
