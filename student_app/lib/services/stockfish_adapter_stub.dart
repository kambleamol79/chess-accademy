class StockfishAdapter {
  static bool get isSupported => false;

  Stream<String> get stdout => const Stream.empty();

  Future<void> start() async {}

  set stdin(String command) {}

  void dispose() {}
}
