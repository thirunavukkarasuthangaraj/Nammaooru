import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../core/config/api_config.dart';

class VoiceSearchService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastWords = '';

  /// Check if speech recognition is available
  Future<bool> initialize() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('🎤 Speech status: $status');
        },
        onError: (error) {
          debugPrint('❌ Speech error: ${error.errorMsg}');
        },
      );
      debugPrint('🎤 Speech recognition available: $available');
      return available;
    } catch (e) {
      debugPrint('❌ Error initializing speech: $e');
      return false;
    }
  }

  /// Start listening for voice input
  Future<String?> listen() async {
    if (!await initialize()) {
      return null;
    }

    try {
      _lastWords = '';
      _isListening = true;

      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          debugPrint('🎤 Recognized: $_lastWords');
        },
        localeId: 'ta_IN', // Tamil (India) - primary language for recognition
        listenMode: stt.ListenMode.confirmation,
      );

      // Wait for speech to complete
      await Future.delayed(const Duration(seconds: 5));

      if (_speech.isListening) {
        await _speech.stop();
      }

      _isListening = false;
      debugPrint('🎤 Final text: $_lastWords');

      return _lastWords.isNotEmpty ? _lastWords : null;
    } catch (e) {
      debugPrint('❌ Error listening: $e');
      _isListening = false;
      return null;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    _isListening = false;
  }

  /// Call AI search API with voice query
  Future<List<dynamic>> searchProducts(int shopId, String query) async {
    try {
      debugPrint('🔍 AI Search: Shop $shopId, Query: "$query"');

      // Try AI search endpoint first
      final aiUrl = Uri.parse(
        '${ApiConfig.baseUrl}/shops/$shopId/products/ai-search?query=${Uri.encodeComponent(query)}',
      );

      final aiResponse = await http.get(
        aiUrl,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('📡 AI Search Response: ${aiResponse.statusCode}');

      if (aiResponse.statusCode == 200) {
        final data = json.decode(aiResponse.body);

        if (data['statusCode'] == '0000' && data['data'] != null) {
          final matchedProducts = data['data']['matchedProducts'] ?? [];
          debugPrint('✅ Found ${matchedProducts.length} products via AI');
          return matchedProducts;
        }
      }

      // Fallback to regular search if AI search fails
      debugPrint('⚠️ AI search not available, using regular search');
      final searchUrl = Uri.parse(
        '${ApiConfig.baseUrl}/shops/$shopId/products/search?query=${Uri.encodeComponent(query)}',
      );

      final searchResponse = await http.get(
        searchUrl,
        headers: {'Content-Type': 'application/json'},
      );

      if (searchResponse.statusCode == 200) {
        final data = json.decode(searchResponse.body);

        if (data['statusCode'] == '0000' && data['data'] != null) {
          final products = data['data'] is List ? data['data'] : [];
          debugPrint('✅ Found ${products.length} products via regular search');
          return products;
        }
      }

      debugPrint('⚠️ Both searches failed, returning empty list');
      return [];
    } catch (e) {
      debugPrint('❌ Error calling search: $e');
      return [];
    }
  }

  /// Voice search: listen + AI search
  Future<List<dynamic>> voiceSearch(int shopId) async {
    final query = await listen();

    if (query == null || query.trim().isEmpty) {
      debugPrint('⚠️ No voice input detected');
      return [];
    }

    return await searchProducts(shopId, query);
  }

  bool get isListening => _isListening;
  String get lastWords => _lastWords;
}
