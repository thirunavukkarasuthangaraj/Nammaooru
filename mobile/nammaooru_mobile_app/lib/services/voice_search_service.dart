import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../core/config/env_config.dart';

/// Voice search service — uses device STT for mic input,
/// then Gemini AI search on backend corrects Tamil/English recognition errors.
class VoiceSearchService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _initialized = false;
  String _lastWords = '';
  String? _lastError;

  /// Check if speech recognition is available.
  /// Initializes the engine once and reuses it — re-initializing on every
  /// tap adds ~1s latency and can re-trigger the system listening prompt.
  Future<bool> initialize() async {
    if (_initialized && _speech.isAvailable) return true;
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('VoiceSearch: Speech status: $status');
        },
        onError: (error) {
          _lastError = error.errorMsg;
          debugPrint('VoiceSearch: Speech error: ${error.errorMsg}');
        },
      );

      if (!available) {
        _lastError = 'Speech recognition not available on this device';
      }

      _initialized = available;
      return available;
    } catch (e) {
      _lastError = 'Error initializing speech: $e';
      debugPrint('VoiceSearch: $_lastError');
      return false;
    }
  }

  /// Last confidence score from STT (0.0–1.0)
  double _lastConfidence = 0;

  /// Start listening for voice input.
  /// Tries Tamil (ta-IN) first; if confidence is low OR result is empty,
  /// the caller can retry via [listenEnglish] for English-India fallback.
  Future<String?> listen({String? localeId, Duration? pauseFor, Duration? listenFor}) async {
    debugPrint('VoiceSearch: listen() called');
    if (!await initialize()) {
      debugPrint('VoiceSearch: initialize() failed');
      return null;
    }

    try {
      _lastWords = '';
      _lastConfidence = 0;
      _isListening = true;
      _lastError = null;
      bool gotFinalResult = false;

      final locale = localeId ?? 'ta-IN';
      debugPrint('VoiceSearch: Starting with $locale locale...');

      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          _lastConfidence = result.confidence;
          if (result.finalResult) gotFinalResult = true;
          debugPrint('VoiceSearch: Recognized: $_lastWords (confidence: ${result.confidence})');
        },
        localeId: locale,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: false,
          partialResults: true,
        ),
        // Short windows keep the mic snappy: stop ~2s after the user goes
        // quiet instead of hanging on for 5s / 30s like before.
        pauseFor: pauseFor ?? const Duration(seconds: 2),
        listenFor: listenFor ?? const Duration(seconds: 12),
      );

      // Wait for speech to complete naturally; exit as soon as the engine
      // delivers a final result instead of blindly waiting out the timer.
      int waited = 0;
      while (_speech.isListening && !gotFinalResult && waited < 75) {
        await Future.delayed(const Duration(milliseconds: 200));
        waited++;
      }

      if (_speech.isListening) {
        await _speech.stop();
      }

      _isListening = false;

      if (_lastWords.isEmpty) {
        _lastError = 'No speech detected. Please try again.';
        return null;
      }

      debugPrint('VoiceSearch: Final text: $_lastWords (conf: $_lastConfidence)');
      return _lastWords;
    } catch (e) {
      _lastError = 'Error during speech recognition: $e';
      debugPrint('VoiceSearch: $_lastError');
      _isListening = false;
      return null;
    }
  }

  /// Single Tamil (ta-IN) listening session.
  ///
  /// Previously this re-listened in en-IN whenever confidence was low, which
  /// made the mic "ask again" right after the user spoke — terrible UX. Any
  /// non-empty result is now accepted as-is: the backend Gemini AI search is
  /// specifically built to correct garbled Tamil/Tanglish STT text, so a
  /// low-confidence transcript is still useful. Empty result → the caller
  /// shows "try again"; the user decides when to speak, not the app.
  Future<String?> listenSmart({double minConfidence = 0.3}) async {
    final text = await listen(localeId: 'ta-IN');
    if (text == null || text.trim().isEmpty) {
      debugPrint('VoiceSearch: no speech captured');
      return null;
    }
    debugPrint('VoiceSearch: result accepted (conf: $_lastConfidence)');
    return text;
  }

  double get lastConfidence => _lastConfidence;

  /// Listen with Tamil locale specifically
  Future<String?> listenTamil() async {
    return listen(localeId: 'ta-IN');
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    _isListening = false;
  }

  /// Call AI search API with voice query
  /// Gemini AI on backend understands intent even with bad STT text
  Future<List<dynamic>> searchProducts(int shopId, String query) async {
    try {
      debugPrint('VoiceSearch: AI Search: Shop $shopId, Query: "$query"');

      // Gemini AI search - understands intent despite STT errors
      final aiUrl = Uri.parse(
        '${EnvConfig.fullApiUrl}/shops/$shopId/products/ai-search?query=${Uri.encodeComponent(query)}',
      );

      final aiResponse = await http.get(
        aiUrl,
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          return http.Response('{"error": "timeout"}', 408);
        },
      );

      if (aiResponse.statusCode == 200) {
        final data = json.decode(aiResponse.body);

        if (data['statusCode'] == '0000' && data['data'] != null) {
          final matchedProducts = data['data']['matchedProducts'] ?? [];
          debugPrint('VoiceSearch: Found ${matchedProducts.length} products via AI');
          return matchedProducts;
        }
      }

      // Fallback to regular search
      final searchUrl = Uri.parse(
        '${EnvConfig.fullApiUrl}/shops/$shopId/products/search?query=${Uri.encodeComponent(query)}',
      );

      final searchResponse = await http.get(
        searchUrl,
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          return http.Response('{"error": "timeout"}', 408);
        },
      );

      if (searchResponse.statusCode == 200) {
        final data = json.decode(searchResponse.body);

        if (data['statusCode'] == '0000' && data['data'] != null) {
          final products = data['data'] is List ? data['data'] : [];
          return products;
        }
      }

      return [];
    } catch (e) {
      debugPrint('VoiceSearch: Error: $e');
      _lastError = 'Network error: Unable to search products';
      return [];
    }
  }

  /// Voice search: listen (Tamil + English fallback) + AI search.
  /// Uses [listenSmart] so very low-confidence Tamil falls back to en-IN automatically.
  Future<List<dynamic>> voiceSearch(int shopId) async {
    final query = await listenSmart();

    if (query == null || query.trim().isEmpty) {
      _lastError = _lastError ?? 'No voice input detected';
      return [];
    }

    return await searchProducts(shopId, query);
  }

  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  String? get lastError => _lastError;
  bool get isAvailable => _speech.isAvailable;
}
