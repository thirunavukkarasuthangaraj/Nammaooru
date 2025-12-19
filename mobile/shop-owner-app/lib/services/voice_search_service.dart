import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../utils/app_config.dart';

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
          debugPrint('Speech status: $status');
        },
        onError: (error) {
          _lastError = error.errorMsg;
          debugPrint('Speech error: ${error.errorMsg}');
        },
      );
      debugPrint('Speech recognition available: $available');

      if (!available) {
        _lastError = 'Speech recognition not available on this device';
      }

      return available;
    } catch (e) {
      _lastError = 'Error initializing speech: $e';
      debugPrint('$_lastError');
      return false;
    }
  }

  /// Get available locales
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!await initialize()) {
      return [];
    }
    return _speech.locales();
  }

  /// Start listening for voice input with automatic language fallback
  Future<String?> listen() async {
    debugPrint('listen() called');
    if (!await initialize()) {
      debugPrint('initialize() failed, returning null');
      return null;
    }

    debugPrint('initialize() succeeded, continuing...');
    try {
      _lastWords = '';
      _isListening = true;
      _lastError = null;

      debugPrint('Starting speech recognition with Tamil locale...');

      // Use Tamil locale to get Tamil script
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          debugPrint('Recognized: $_lastWords (confidence: ${result.confidence})');
        },
        localeId: 'ta-IN', // Force Tamil script for Tamil speech
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: false,
        partialResults: true,
        pauseFor: const Duration(seconds: 5),
        listenFor: const Duration(seconds: 45),
      );

      // Wait for speech to complete naturally
      int maxWaitSeconds = 45;
      int waitedSeconds = 0;
      while (_speech.isListening && waitedSeconds < maxWaitSeconds) {
        await Future.delayed(const Duration(milliseconds: 500));
        waitedSeconds++;
      }

      if (_speech.isListening) {
        await _speech.stop();
      }

      _isListening = false;
      debugPrint('Final text: $_lastWords');

      if (_lastWords.isEmpty) {
        _lastError = 'No speech detected. Please try again.';
        return null;
      }

      return _lastWords;
    } catch (e) {
      _lastError = 'Error during speech recognition: $e';
      debugPrint('$_lastError');
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

  /// Search products in shop's inventory
  Future<List<dynamic>> searchProducts(String query, String token) async {
    try {
      debugPrint('Search: Query: "$query"');

      // Search in shop's own products
      final url = Uri.parse(
        '${AppConfig.apiBaseUrl}/shops/my-shop/products/search?query=${Uri.encodeComponent(query)}',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Search timeout');
          return http.Response('{"error": "timeout"}', 408);
        },
      );

      debugPrint('Search Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['statusCode'] == '0000' && data['data'] != null) {
          final products = data['data'] is List ? data['data'] : [];
          debugPrint('Found ${products.length} products');
          return products;
        }
      }

      debugPrint('Search failed, returning empty list');
      return [];
    } catch (e) {
      debugPrint('Error calling search: $e');
      _lastError = 'Network error: Unable to search products';
      return [];
    }
  }

  /// Voice search: listen + search
  Future<List<dynamic>> voiceSearch(String token) async {
    debugPrint('voiceSearch() started');
    final query = await listen();
    debugPrint('voiceSearch() - listen() returned: "$query"');

    if (query == null || query.trim().isEmpty) {
      debugPrint('No voice input detected');
      _lastError = _lastError ?? 'No voice input detected';
      return [];
    }

    debugPrint('voiceSearch() - calling searchProducts with query: "$query"');
    return await searchProducts(query, token);
  }

  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  String? get lastError => _lastError;

  /// Check if speech recognition is supported on device
  bool get isAvailable => _speech.isAvailable;
}
