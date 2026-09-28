import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String _currentLanguage = 'ta-IN';

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage(_currentLanguage);
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      // Make speak() wait until speech is fully complete before returning
      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() => _isSpeaking = true);
      _tts.setCompletionHandler(() => _isSpeaking = false);
      _tts.setCancelHandler(() => _isSpeaking = false);
      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS error: $msg');
      });

      _isInitialized = true;
      debugPrint('TTS initialized with ta-IN');
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  /// [language] switches the TTS voice itself (e.g. 'en-IN' vs 'ta-IN') -
  /// without this, text was always read in the ta-IN voice regardless of
  /// which language the sentence was actually written in.
  Future<void> speak(String text, {String? language}) async {
    if (!_isInitialized) await initialize();
    if (text.isEmpty) return;
    if (language != null && language != _currentLanguage) {
      _currentLanguage = language;
      await _tts.setLanguage(_currentLanguage);
    }
    await _tts.stop();
    _isSpeaking = true;
    await _tts.speak(text); // Now waits for speech to complete
    _isSpeaking = false;
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  void dispose() {
    _tts.stop();
  }
}
