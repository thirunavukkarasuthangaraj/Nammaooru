import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage('ta-IN');
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

  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    if (text.isEmpty) return;
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
