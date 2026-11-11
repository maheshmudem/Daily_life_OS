import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'tts_service_interface.dart';

class IoTtsService implements AppTtsService {
  FlutterTts? _flutterTts;
  bool _isSpeaking = false;
  bool _isPaused = false;
  String _lastText = '';
  double _lastRate = 1.0;
  void Function()? _onStart;
  void Function()? _onComplete;
  void Function(String msg)? _onError;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  bool get isPaused => _isPaused;

  IoTtsService() {
    _init();
  }

  Future<void> _init() async {
    try {
      final tts = FlutterTts();
      _flutterTts = tts;

      tts.setStartHandler(() {
        _isSpeaking = true;
        _isPaused = false;
        _onStart?.call();
      });

      tts.setCompletionHandler(() {
        _isSpeaking = false;
        _isPaused = false;
        _onComplete?.call();
      });

      tts.setCancelHandler(() {
        _isSpeaking = false;
        _isPaused = false;
        _onComplete?.call();
      });

      tts.setPauseHandler(() {
        _isSpeaking = false;
        _isPaused = true;
      });

      tts.setContinueHandler(() {
        _isSpeaking = true;
        _isPaused = false;
        _onStart?.call();
      });

      tts.setErrorHandler((msg) {
        _isSpeaking = false;
        _isPaused = false;
        _onError?.call(msg.toString());
      });

      await tts.setLanguage('en-IN');
      // Shreya Ghoshal melodic sweet soprano pitch & gentle cadence
      await tts.setPitch(1.18);
      await tts.setSpeechRate(0.46);
      await tts.setVolume(1.0);

      // Try selecting female Indian voice if available
      try {
        final voices = await tts.getVoices;
        if (voices is List) {
          for (final voice in voices) {
            if (voice is Map) {
              final name = voice['name']?.toString().toLowerCase() ?? '';
              final locale = voice['locale']?.toString().toLowerCase() ?? '';
              if ((locale.contains('en-in') || locale.contains('hi-in')) &&
                  (name.contains('female') ||
                      name.contains('neerja') ||
                      name.contains('heera') ||
                      name.contains('google'))) {
                await tts.setVoice({
                  'name': voice['name'].toString(),
                  'locale': voice['locale'].toString(),
                });
                break;
              }
            }
          }
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('IoTtsService init error: $e');
    }
  }

  @override
  void setCallbacks({
    void Function()? onStart,
    void Function()? onComplete,
    void Function(String msg)? onError,
  }) {
    _onStart = onStart;
    _onComplete = onComplete;
    _onError = onError;
  }

  @override
  Future<void> speak(String text, {double rate = 1.0}) async {
    _lastText = text;
    _lastRate = rate;
    try {
      if (_flutterTts != null) {
        await _flutterTts!.setPitch(1.18);
        await _flutterTts!.setSpeechRate(0.46 * rate);
        await _flutterTts!.speak(text);
        _isSpeaking = true;
        _isPaused = false;
        _onStart?.call();
      }
    } catch (e) {
      debugPrint('TTS speak error: $e');
      _onError?.call(e.toString());
    }
  }

  @override
  Future<void> pause() async {
    try {
      if (_flutterTts != null) {
        await _flutterTts!.pause();
      }
    } catch (e) {
      debugPrint('TTS pause error: $e');
    }
    _isSpeaking = false;
    _isPaused = true;
  }

  @override
  Future<void> resume() async {
    try {
      if (_flutterTts != null) {
        await _flutterTts!.setSpeechRate(0.46 * _lastRate);
        await _flutterTts!.speak(_lastText);
      }
    } catch (e) {
      debugPrint('TTS resume error: $e');
    }
    _isSpeaking = true;
    _isPaused = false;
    _onStart?.call();
  }

  @override
  Future<void> stop() async {
    try {
      if (_flutterTts != null) {
        await _flutterTts!.stop();
      }
    } catch (_) {}
    _isSpeaking = false;
    _isPaused = false;
    _onComplete?.call();
  }

  @override
  Future<void> setRate(double rate) async {
    _lastRate = rate;
    try {
      if (_flutterTts != null) {
        await _flutterTts!.setSpeechRate(0.46 * rate);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    stop();
  }
}

AppTtsService createTtsService() => IoTtsService();
