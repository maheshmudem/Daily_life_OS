abstract class AppTtsService {
  bool get isSpeaking;
  bool get isPaused;

  void setCallbacks({
    void Function()? onStart,
    void Function()? onComplete,
    void Function(String msg)? onError,
  });

  Future<void> speak(String text, {double rate = 1.0});
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> setRate(double rate);
  void dispose();
}

