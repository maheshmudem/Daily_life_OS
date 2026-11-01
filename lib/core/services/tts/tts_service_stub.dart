import 'tts_service_interface.dart';

class StubTtsService implements AppTtsService {
  @override
  bool get isSpeaking => false;

  @override
  bool get isPaused => false;

  @override
  void setCallbacks({
    void Function()? onStart,
    void Function()? onComplete,
    void Function(String msg)? onError,
  }) {}

  @override
  Future<void> speak(String text, {double rate = 1.0}) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setRate(double rate) async {}

  @override
  void dispose() {}
}

AppTtsService createTtsService() => StubTtsService();

