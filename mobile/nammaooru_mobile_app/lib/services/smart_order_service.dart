import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import 'voice_search_service.dart';
import 'tts_service.dart';

/// Represents a single parsed item from the user's order
class ParsedItem {
  final String name;
  List<Map<String, dynamic>> matches;
  Map<String, dynamic>? selectedMatch;
  bool isAdded;

  ParsedItem({
    required this.name,
    this.matches = const [],
    this.selectedMatch,
    this.isAdded = false,
  });
}

/// Result of processing an order (voice/photo/text)
class SmartOrderResult {
  final String rawInput;
  final List<ParsedItem> items;
  final String mode; // 'voice', 'photo', 'text'

  SmartOrderResult({
    required this.rawInput,
    required this.items,
    required this.mode,
  });

  int get matchedCount => items.where((i) => i.matches.isNotEmpty).length;
  int get unmatchedCount => items.where((i) => i.matches.isEmpty).length;
}

/// Orchestrates AI Smart Ordering — voice, photo, and text input modes
class SmartOrderService {
  final VoiceSearchService _voiceService = VoiceSearchService();
  final TtsService _ttsService = TtsService();

  TtsService get ttsService => _ttsService;
  VoiceSearchService get voiceService => _voiceService;

  /// MODE 1: Voice → listen Tamil → search products
  Future<SmartOrderResult?> processVoiceOrder() async {
    debugPrint('SmartOrder: Starting voice order...');
    final text = await _voiceService.listen();
    if (text == null || text.trim().isEmpty) return null;

    debugPrint('SmartOrder: Voice captured: "$text"');
    final items = await _searchGrouped(text);

    await _speakResult(items);
    return SmartOrderResult(rawInput: text, items: items, mode: 'voice');
  }

  /// MODE 2: Photo → Gemini Vision parse → search products
  Future<SmartOrderResult?> processPhotoOrder(File imageFile) async {
    debugPrint('SmartOrder: Processing photo order...');
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await ApiClient.post(
        '/v1/products/search/parse-image',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = response.data;
      if (data == null || data['statusCode'] != '0000') {
        debugPrint('SmartOrder: Image parse failed: ${data?['message']}');
        return null;
      }

      final List<dynamic> parsedItems = data['data']?['items'] ?? [];
      debugPrint('SmartOrder: Parsed ${parsedItems.length} items from image');

      if (parsedItems.isEmpty) return null;

      // Search for each parsed item
      List<ParsedItem> items = [];
      for (final itemName in parsedItems) {
        final name = itemName.toString().trim();
        if (name.isEmpty) continue;
        final matches = await _searchProducts(name);
        items.add(ParsedItem(name: name, matches: matches));
      }

      final rawText = parsedItems.join(', ');
      await _speakResult(items);
      return SmartOrderResult(rawInput: rawText, items: items, mode: 'photo');
    } catch (e) {
      debugPrint('SmartOrder: Photo order error: $e');
      return null;
    }
  }

  /// MODE 3: Text → search products
  Future<SmartOrderResult?> processTextOrder(String text) async {
    if (text.trim().isEmpty) return null;
    debugPrint('SmartOrder: Processing text order: "$text"');

    final items = await _searchGrouped(text);
    await _speakResult(items);
    return SmartOrderResult(rawInput: text, items: items, mode: 'text');
  }

  /// Search using the grouped voice search endpoint
  Future<List<ParsedItem>> _searchGrouped(String query) async {
    try {
      final response = await ApiClient.post(
        '/v1/products/search/voice/grouped',
        queryParameters: {'q': query},
      );

      final data = response.data;
      if (data == null || data['statusCode'] != '0000') {
        // Fallback: treat entire query as single search
        final matches = await _searchProducts(query);
        return [ParsedItem(name: query, matches: matches)];
      }

      final List<dynamic> groups = data['data'] ?? [];
      List<ParsedItem> items = [];

      for (final group in groups) {
        final keyword = group['keyword']?.toString() ?? '';
        final List<dynamic> products = group['products'] ?? [];

        final matches = products.map<Map<String, dynamic>>((p) => {
              'id': p['id']?.toString() ?? '',
              'name': p['name']?.toString() ?? '',
              'nameTamil': p['nameTamil']?.toString() ?? '',
              'price': p['minPrice']?.toString() ?? p['maxPrice']?.toString() ?? '0',
              'image': p['primaryImageUrl']?.toString() ?? '',
              'shopId': '',
              'shopName': '',
              'shopCount': p['shopCount'] ?? 0,
            }).toList();

        items.add(ParsedItem(name: keyword, matches: matches));
      }

      return items;
    } catch (e) {
      debugPrint('SmartOrder: Grouped search error: $e');
      final matches = await _searchProducts(query);
      return [ParsedItem(name: query, matches: matches)];
    }
  }

  /// Simple product search fallback
  Future<List<Map<String, dynamic>>> _searchProducts(String query) async {
    try {
      final response = await ApiClient.post(
        '/v1/products/search/voice',
        queryParameters: {'q': query},
      );

      final data = response.data;
      if (data == null || data['statusCode'] != '0000') return [];

      final List<dynamic> products = data['data'] ?? [];
      return products.map<Map<String, dynamic>>((p) => {
            'id': p['id']?.toString() ?? '',
            'name': p['name']?.toString() ?? '',
            'nameTamil': p['nameTamil']?.toString() ?? '',
            'price': p['minPrice']?.toString() ?? p['maxPrice']?.toString() ?? '0',
            'image': p['primaryImageUrl']?.toString() ?? '',
            'shopId': '',
            'shopName': '',
          }).toList();
    } catch (e) {
      debugPrint('SmartOrder: Product search error: $e');
      return [];
    }
  }

  /// Speak result summary in Tamil
  Future<void> _speakResult(List<ParsedItem> items) async {
    final matched = items.where((i) => i.matches.isNotEmpty).length;
    final total = items.length;

    String message;
    if (matched == 0) {
      message = 'பொருட்கள் கிடைக்கவில்லை. மீண்டும் முயற்சிக்கவும்.';
    } else if (matched == total) {
      message = '$matched பொருட்கள் கிடைத்தன. கார்ட்டில் சேர்க்கவா?';
    } else {
      message = '$total இல் $matched பொருட்கள் கிடைத்தன.';
    }

    await _ttsService.speak(message);
  }

  /// Speak custom message
  Future<void> speak(String text) => _ttsService.speak(text);

  /// Stop speaking
  Future<void> stopSpeaking() => _ttsService.stop();

  void dispose() {
    _ttsService.dispose();
  }
}
