class ShrutiAudio {
  Future<void> start(Map<double, double> voices, double volume) async {
    throw UnsupportedError('Shruti audio is currently available on web only.');
  }

  void update(Map<double, double> voices, double volume) {}

  void stop() {}

  Future<void> dispose() async {}
}
