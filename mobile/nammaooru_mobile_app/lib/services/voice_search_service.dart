import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart';
import 'gemini_voice_service.dart';

/// Voice search service — uses GeminiVoiceService for recording + transcription.
/// GeminiVoiceService is proven to work in Voice Assistant.
class VoiceSearchService {
  final GeminiVoiceService _gemini = GeminiVoiceService();
  bool _isListening = false;
  String _lastWords = '';
  String? _lastError;

  /// Check if microphone permission is available
  Future<bool> initialize() async {
    try {
      final hasPerms = await _gemini.hasPermission();
      if (!hasPerms) {
        _lastError = 'Microphone permission not granted';
      }
      return hasPerms;
    } catch (e) {
      _lastError = 'Error initializing microphone: $e';
      debugPrint('VoiceSearch: $_lastError');
      return false;
    }
  }

  /// Start recording audio (for tap-to-talk UI)
  Future<bool> startRecording() async {
    _lastError = null;
    final started = await _gemini.startRecording();
    if (started) {
      _isListening = true;
    } else {
      _lastError = 'Failed to start recording';
    }
    return started;
  }

  /// Stop recording and transcribe via Gemini backend
  Future<String?> stopAndTranscribe() async {
    _isListening = false;
    final text = await _gemini.stopAndTranscribe();
    if (text != null && text.isNotEmpty) {
      _lastWords = text;
      return text;
    }
    _lastError = 'No speech detected. Please try again.';
    return null;
  }

  /// listen() — starts recording, waits 5 seconds, then transcribes via Gemini.
  /// Used by screens that call listen() and wait for a result.
  Future<String?> listen({String? localeId}) async {
    debugPrint('VoiceSearch: listen() called');
    _lastWords = '';
    _lastError = null;

    final started = await _gemini.startRecording();
    if (!started) {
      _lastError = 'Failed to start recording. Check microphone permission.';
      debugPrint('VoiceSearch: $_lastError');
      return null;
    }

    _isListening = true;
    debugPrint('VoiceSearch: Recording started, waiting 5 seconds...');

    // Record for 5 seconds (enough for short grocery queries)
    await Future.delayed(const Duration(seconds: 5));

    _isListening = false;
    final text = await _gemini.stopAndTranscribe();

    if (text != null && text.isNotEmpty) {
      _lastWords = text;
      debugPrint('VoiceSearch: Transcription = "$_lastWords"');
      return _lastWords;
    }

    _lastError = 'No speech detected. Please try again.';
    debugPrint('VoiceSearch: $_lastError');
    return null;
  }

  /// Listen with Tamil locale (same as listen — Gemini handles all languages)
  Future<String?> listenTamil() async {
    return listen();
  }

  /// Stop listening/recording
  Future<void> stopListening() async {
    if (_gemini.isRecording) {
      await _gemini.stopRecording();
    }
    _isListening = false;
  }

  /// Call AI search API with voice query
  Future<List<dynamic>> searchProducts(int shopId, String query) async {
    try {
      debugPrint('VoiceSearch: AI Search: Shop $shopId, Query: "$query"');

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

  /// Voice search: listen + AI search
  Future<List<dynamic>> voiceSearch(int shopId) async {
    final query = await listen();
    if (query == null || query.trim().isEmpty) {
      _lastError = _lastError ?? 'No voice input detected';
      return [];
    }
    return await searchProducts(shopId, query);
  }

  bool get isListening => _isListening;
  bool get isRecording => _gemini.isRecording;
  String get lastWords => _lastWords;
  String? get lastError => _lastError;
  bool get isAvailable => true;

  void dispose() {
    _gemini.dispose();
  }
}
