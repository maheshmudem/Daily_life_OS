import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'tts_service_interface.dart';

class WebTtsService implements AppTtsService {
  bool _isSpeaking = false;
  bool _isPaused = false;
  void Function()? _onStart;
  void Function()? _onComplete;
  void Function(String msg)? _onError;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  bool get isPaused => _isPaused;

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

  web.SpeechSynthesisVoice? _findMelodicIndianVoice(web.SpeechSynthesis synth) {
    try {
      final voices = synth.getVoices();
      final len = voices.length;
      if (len == 0) return null;

      // 1. First priority: Indian English / Hindi Female voices (Neerja, Heera, Swara, Google en-IN)
      for (var i = 0; i < len; i++) {
        final v = voices[i];
        final lang = v.lang.toLowerCase();
        final name = v.name.toLowerCase();

        final isIndianLang = lang.contains('en-in') ||
            lang.contains('hi-in') ||
            lang.contains('in');
        final isFemale = name.contains('female') ||
            name.contains('neerja') ||
            name.contains('heera') ||
            name.contains('swara') ||
            name.contains('google');

        if (isIndianLang && isFemale) {
          return v;
        }
      }

      // 2. Second priority: Any Indian locale voice
      for (var i = 0; i < len; i++) {
        final v = voices[i];
        final lang = v.lang.toLowerCase();
        if (lang.contains('en-in') || lang.contains('hi-in')) {
          return v;
        }
      }

      // 3. Third priority: Any gentle female voice (Zira, Samantha, Victoria)
      for (var i = 0; i < len; i++) {
        final v = voices[i];
        final name = v.name.toLowerCase();
        if (name.contains('female') ||
            name.contains('zira') ||
            name.contains('samantha')) {
          return v;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> speak(String text, {double rate = 1.0}) async {
    try {
      final synth = web.window.speechSynthesis;
      synth.cancel();

      final utterance = web.SpeechSynthesisUtterance(text);

      // Shreya Ghoshal melodic tuning:
      // - Gentle musical cadence (0.94x base rate)
      // - Sweet soprano pitch (1.18x pitch)
      utterance.rate = rate * 0.94;
      utterance.pitch = 1.18;
      utterance.lang = 'en-IN';

      final voice = _findMelodicIndianVoice(synth);
      if (voice != null) {
        utterance.voice = voice;
      }

      utterance.onstart = ((web.Event _) {
        _isSpeaking = true;
        _isPaused = false;
        _onStart?.call();
      }).toJS;

      utterance.onend = ((web.Event _) {
        _isSpeaking = false;
        _isPaused = false;
        _onComplete?.call();
      }).toJS;

      utterance.onerror = ((web.SpeechSynthesisErrorEvent e) {
        _isSpeaking = false;
        _isPaused = false;
        _onError?.call(e.error);
      }).toJS;

      utterance.onpause = ((web.Event _) {
        _isSpeaking = false;
        _isPaused = true;
      }).toJS;

      utterance.onresume = ((web.Event _) {
        _isSpeaking = true;
        _isPaused = false;
        _onStart?.call();
      }).toJS;

      synth.speak(utterance);
      _isSpeaking = true;
      _isPaused = false;
      _onStart?.call();
    } catch (e) {
      _onError?.call(e.toString());
    }
  }

  @override
  Future<void> pause() async {
    try {
      final synth = web.window.speechSynthesis;
      if (synth.speaking && !_isPaused) {
        synth.pause();
        _isSpeaking = false;
        _isPaused = true;
      }
    } catch (e) {
      _onError?.call(e.toString());
    }
  }

  @override
  Future<void> resume() async {
    try {
      final synth = web.window.speechSynthesis;
      if (_isPaused) {
        synth.resume();
        _isSpeaking = true;
        _isPaused = false;
        _onStart?.call();
      }
    } catch (e) {
      _onError?.call(e.toString());
    }
  }

  @override
  Future<void> stop() async {
    try {
      final synth = web.window.speechSynthesis;
      synth.cancel();
    } catch (_) {}
    _isSpeaking = false;
    _isPaused = false;
    _onComplete?.call();
  }

  @override
  Future<void> setRate(double rate) async {}

  @override
  void dispose() {
    stop();
  }
}

AppTtsService createTtsService() => WebTtsService();
