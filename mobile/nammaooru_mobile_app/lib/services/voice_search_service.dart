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
  String _lastWords = '';
  String? _lastError;

  /// Check if speech recognition is available
  Future<bool> initialize() async {
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

      final locale = localeId ?? 'ta-IN';
      debugPrint('VoiceSearch: Starting with $locale locale...');

      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          _lastConfidence = result.confidence;
          debugPrint('VoiceSearch: Recognized: $_lastWords (confidence: ${result.confidence})');
        },
        localeId: locale,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: false,
          partialResults: true,
        ),
        pauseFor: pauseFor ?? const Duration(seconds: 5),
        listenFor: listenFor ?? const Duration(seconds: 30),
      );

      // Wait for speech to complete naturally
      int waited = 0;
      while (_speech.isListening && waited < 60) {
        await Future.delayed(const Duration(milliseconds: 500));
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

  /// Listen in Tamil, then fall back to English-India if:
  ///   - the result is empty, OR
  ///   - confidence is below [minConfidence] (default 0.3)
  /// This handles villagers who actually speak English/Tanglish naturally —
  /// ta-IN locale would otherwise produce garbled output.
  Future<String?> listenSmart({double minConfidence = 0.3}) async {
    final tamil = await listen(localeId: 'ta-IN');
    if (tamil != null && tamil.trim().isNotEmpty && _lastConfidence >= minConfidence) {
      debugPrint('VoiceSearch: ta-IN result accepted (conf: $_lastConfidence)');
      return tamil;
    }
    debugPrint('VoiceSearch: ta-IN result rejected (text: "$tamil", conf: $_lastConfidence), '
        'trying en-IN...');
    final english = await listen(localeId: 'en-IN');
    if (english != null && english.trim().isNotEmpty) {
      return english;
    }
    // Last resort: return whatever Tamil gave us (even if low confidence)
    return tamil;
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
