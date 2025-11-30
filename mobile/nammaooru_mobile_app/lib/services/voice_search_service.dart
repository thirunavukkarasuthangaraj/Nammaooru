import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../core/config/api_config.dart';

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
          debugPrint('🎤 Speech status: $status');
        },
        onError: (error) {
          _lastError = error.errorMsg;
          debugPrint('❌ Speech error: ${error.errorMsg}');
        },
      );
      debugPrint('🎤 Speech recognition available: $available');

      if (!available) {
        _lastError = 'Speech recognition not available on this device';
      }

      return available;
    } catch (e) {
      _lastError = 'Error initializing speech: $e';
      debugPrint('❌ $_lastError');
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
    debugPrint('🎙️ listen() called');
    if (!await initialize()) {
      debugPrint('❌ initialize() failed, returning null');
      return null;
    }

    debugPrint('✅ initialize() succeeded, continuing...');
    try {
      _lastWords = '';
      _isListening = true;
      _lastError = null;

      debugPrint('🎙️ Starting speech recognition with Tamil locale...');

      // Use Tamil locale to get Tamil script (அரிசி) instead of transliteration (arasi)
      // ta-IN forces Tamil script output
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          debugPrint('🎤 Recognized: $_lastWords (confidence: ${result.confidence})');
        },
        localeId: 'ta-IN', // Force Tamil script for Tamil speech
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: false,
        partialResults: true,
      );

      // Wait for speech to complete
      await Future.delayed(const Duration(seconds: 5));

      if (_speech.isListening) {
        await _speech.stop();
      }

      _isListening = false;
      debugPrint('🎤 Final text: $_lastWords');

      if (_lastWords.isEmpty) {
        _lastError = 'No speech detected. Please try again.';
        return null;
      }

      return _lastWords;
    } catch (e) {
      _lastError = 'Error during speech recognition: $e';
      debugPrint('❌ $_lastError');
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
      debugPrint('🔍 AI Search: Shop $shopId, Query: "$query" (Original Tamil)');

      // Convert Tamil script to transliterated English for better search results
      String searchQuery = _transliterateTamilToEnglish(query);
      debugPrint('🔄 Converted to transliterated: "$searchQuery"');

      // Try AI search endpoint first
      final aiUrl = Uri.parse(
        '${ApiConfig.baseUrl}/shops/$shopId/products/ai-search?query=${Uri.encodeComponent(searchQuery)}',
      );

      final aiResponse = await http.get(
        aiUrl,
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ AI search timeout');
          return http.Response('{"error": "timeout"}', 408);
        },
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
        '${ApiConfig.baseUrl}/shops/$shopId/products/search?query=${Uri.encodeComponent(searchQuery)}',
      );

      final searchResponse = await http.get(
        searchUrl,
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ Regular search timeout');
          return http.Response('{"error": "timeout"}', 408);
        },
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
      _lastError = 'Network error: Unable to search products';
      return [];
    }
  }

  /// Voice search: listen + AI search
  Future<List<dynamic>> voiceSearch(int shopId) async {
    debugPrint('🔵 voiceSearch() started for shop $shopId');
    final query = await listen();
    debugPrint('🔵 voiceSearch() - listen() returned: "$query"');

    if (query == null || query.trim().isEmpty) {
      debugPrint('⚠️ No voice input detected');
      _lastError = _lastError ?? 'No voice input detected';
      return [];
    }

    debugPrint('🔵 voiceSearch() - calling searchProducts with query: "$query"');
    return await searchProducts(shopId, query);
  }

  /// Convert Tamil script to transliterated English
  /// Examples: தக்காளி -> takkaali, அரிசி -> arisi, வெங்காயம் -> vengayam
  String _transliterateTamilToEnglish(String tamilText) {
    // Tamil to English transliteration map
    final tamilToEnglishMap = {
      'அ': 'a',
      'ஆ': 'aa',
      'இ': 'i',
      'ஈ': 'ee',
      'உ': 'u',
      'ஊ': 'uu',
      'எ': 'e',
      'ஏ': 'ee',
      'ஐ': 'ai',
      'ஒ': 'o',
      'ஓ': 'o',
      'ஔ': 'au',
      'க': 'ka',
      'கா': 'ka',
      'கி': 'ki',
      'கீ': 'kee',
      'கு': 'ku',
      'கூ': 'koo',
      'கெ': 'ke',
      'கே': 'ke',
      'கை': 'kai',
      'கொ': 'ko',
      'கோ': 'ko',
      'கௌ': 'kau',
      'ங': 'ng',
      'ச': 'cha',
      'சா': 'cha',
      'சி': 'chi',
      'சீ': 'chee',
      'சு': 'chu',
      'சூ': 'choo',
      'செ': 'che',
      'சே': 'che',
      'சை': 'chai',
      'சொ': 'cho',
      'சோ': 'cho',
      'சௌ': 'chau',
      'ட': 'ta',
      'டா': 'ta',
      'டி': 'ti',
      'டீ': 'tee',
      'டு': 'tu',
      'டூ': 'too',
      'டெ': 'te',
      'டே': 'te',
      'டை': 'tai',
      'டொ': 'to',
      'டோ': 'to',
      'டௌ': 'tau',
      'ண': 'na',
      'ணா': 'na',
      'ணி': 'ni',
      'ணீ': 'nee',
      'ணு': 'nu',
      'ணூ': 'noo',
      'ணெ': 'ne',
      'ணே': 'ne',
      'ணை': 'nai',
      'ணொ': 'no',
      'ணோ': 'no',
      'ணௌ': 'nau',
      'த': 'tha',
      'தா': 'tha',
      'தி': 'thi',
      'தீ': 'thee',
      'து': 'thu',
      'தூ': 'thoo',
      'தெ': 'the',
      'தே': 'the',
      'தை': 'thai',
      'தொ': 'tho',
      'தோ': 'tho',
      'தௌ': 'thau',
      'ந': 'na',
      'நா': 'na',
      'நி': 'ni',
      'நீ': 'nee',
      'நு': 'nu',
      'நூ': 'noo',
      'நெ': 'ne',
      'நே': 'ne',
      'நை': 'nai',
      'நொ': 'no',
      'நோ': 'no',
      'நௌ': 'nau',
      'ப': 'pa',
      'பா': 'pa',
      'பி': 'pi',
      'பீ': 'pee',
      'பு': 'pu',
      'பூ': 'poo',
      'பெ': 'pe',
      'பே': 'pe',
      'பை': 'pai',
      'பொ': 'po',
      'போ': 'po',
      'பௌ': 'pau',
      'ம': 'ma',
      'மா': 'ma',
      'மி': 'mi',
      'மீ': 'mee',
      'மு': 'mu',
      'மூ': 'moo',
      'மெ': 'me',
      'மே': 'me',
      'மை': 'mai',
      'மொ': 'mo',
      'மோ': 'mo',
      'மௌ': 'mau',
      'ய': 'ya',
      'ர': 'ra',
      'ல': 'la',
      'ள': 'la',
      'ழ': 'zha',
      'வ': 'va',
      'வா': 'va',
      'வி': 'vi',
      'வீ': 'vee',
      'வு': 'vu',
      'வூ': 'voo',
      'வெ': 've',
      'வே': 've',
      'வை': 'vai',
      'வொ': 'vo',
      'வோ': 'vo',
      'வௌ': 'vau',
      'ஶ': 'sha',
      'ஷ': 'sha',
      'ஸ': 'sa',
      'ஸ்ரீ': 'shree',
      'ஹ': 'ha',
      '்': '', // Viraam (half consonant marker)
      '‌': '', // Zero-width non-joiner
      'ு': 'u',
      'ூ': 'oo',
      'ெ': 'e',
      'ே': 'e',
      'ै': 'ai',
      'ொ': 'o',
      'ோ': 'o',
      'ौ': 'au',
    };

    String result = '';
    for (int i = 0; i < tamilText.length; i++) {
      String char = tamilText[i];

      // Try 2-character combinations first
      if (i < tamilText.length - 1) {
        String twoChar = tamilText.substring(i, i + 2);
        if (tamilToEnglishMap.containsKey(twoChar)) {
          result += tamilToEnglishMap[twoChar]!;
          i++; // Skip next character
          continue;
        }
      }

      // Then try single character
      if (tamilToEnglishMap.containsKey(char)) {
        result += tamilToEnglishMap[char]!;
      } else if (char == ' ' || char == '-' || char.isEmpty) {
        result += ' '; // Keep spaces
      } else {
        result += char; // Keep unknown characters as-is
      }
    }

    // Clean up extra spaces
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  String? get lastError => _lastError;

  /// Check if speech recognition is supported on device
  bool get isAvailable => _speech.isAvailable;
}
