import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import 'voice_search_service.dart';
import 'tts_service.dart';
import 'product_search_engine.dart';

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

/// Result of processing an order (voice/text)
class SmartOrderResult {
  final String rawInput;
  final List<ParsedItem> items;
  final String mode; // 'voice', 'text'

  SmartOrderResult({
    required this.rawInput,
    required this.items,
    required this.mode,
  });

  int get matchedCount => items.where((i) => i.matches.isNotEmpty).length;
  int get unmatchedCount => items.where((i) => i.matches.isEmpty).length;
}

/// Orchestrates AI Smart Ordering — voice and text input modes
class SmartOrderService {
  final VoiceSearchService _voiceService = VoiceSearchService();
  final TtsService _ttsService = TtsService();

  /// Shop context — when set, searches within this shop only
  int? shopId;
  String? shopName;

  TtsService get ttsService => _ttsService;
  VoiceSearchService get voiceService => _voiceService;

  /// MODE 1: Voice → listen Tamil → search products
  Future<SmartOrderResult?> processVoiceOrder() async {
    debugPrint('SmartOrder: Starting voice order...');
    final text = await _voiceService.listen();
    if (text == null || text.trim().isEmpty) return null;

    debugPrint('SmartOrder: Voice captured: "$text"');
    final items = await _searchItems(text);

    await _speakResult(items);
    return SmartOrderResult(rawInput: text, items: items, mode: 'voice');
  }

  /// MODE 2: Text → search products
  Future<SmartOrderResult?> processTextOrder(String text) async {
    if (text.trim().isEmpty) return null;
    debugPrint('SmartOrder: Processing text order: "$text"');

    final items = await _searchItems(text);
    await _speakResult(items);
    return SmartOrderResult(rawInput: text, items: items, mode: 'text');
  }

  /// Search items — uses shop-specific endpoint if shopId is set
  Future<List<ParsedItem>> _searchItems(String query) async {
    if (shopId != null) {
      final terms = _splitIntoTerms(query);
      debugPrint('SmartOrder: Split "$query" → $terms');

      List<ParsedItem> items = [];
      for (final term in terms) {
        final matches = await _searchShopProducts(term);
        items.add(ParsedItem(name: term, matches: matches));
      }
      return items;
    } else {
      return _searchGrouped(query);
    }
  }

  /// Tamil/English quantity & unit words to filter out before searching
  static final Set<String> _quantityWords = {
    'ஒரு', 'இரண்டு', 'மூன்று', 'நான்கு', 'ஐந்து',
    'ஆறு', 'ஏழு', 'எட்டு', 'ஒன்பது', 'பத்து',
    'அரை', 'ஒன்றரை', 'இரண்டரை',
    'கிலோ', 'கிராம்', 'லிட்டர்', 'மில்லி', 'பாக்கெட்', 'டஜன்',
    'கேஜி', 'லிட்', 'பாக்',
    'kg', 'kilo', 'gram', 'grams', 'liter', 'litre', 'ml',
    'packet', 'pack', 'dozen', 'half', 'quarter',
    'one', 'two', 'three', 'four', 'five',
  };

  /// Split voice/text input into individual product terms
  List<String> _splitIntoTerms(String text) {
    var normalized = text
        .replaceAll('மற்றும்', ',')
        .replaceAll(' and ', ',')
        .replaceAll('  ', ' ');

    var parts = normalized
        .split(RegExp(r'[,\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    List<String> productTerms = [];
    for (final part in parts) {
      final words = part
          .split(' ')
          .map((w) => w.trim())
          .where((w) => w.isNotEmpty)
          .where((w) =>
              !_quantityWords.contains(w.toLowerCase()) &&
              !RegExp(r'^\d+\.?\d*$').hasMatch(w))
          .where((w) => w.length > 1)
          .toList();

      if (words.isEmpty) continue;
      productTerms.addAll(words.map(_removePlural));
    }

    debugPrint('SmartOrder: splitIntoTerms "$text" → $productTerms');
    return productTerms.isEmpty ? [text.trim()] : productTerms;
  }

  /// Remove English plural suffix
  String _removePlural(String word) {
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(word) || word.length <= 3) {
      return word;
    }
    final lower = word.toLowerCase();
    if (lower.endsWith('oes')) {
      return word.substring(0, word.length - 2);
    } else if (lower.endsWith('s') && !lower.endsWith('ss')) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  /// Search within a specific shop using AI search
  Future<List<Map<String, dynamic>>> _searchShopProducts(String query) async {
    if (shopId == null) return _searchGlobalProducts(query);

    try {
      debugPrint('SmartOrder: Shop search shopId=$shopId query="$query"');
      final response = await ApiClient.get(
        '/shops/$shopId/products/ai-search',
        queryParameters: {'query': query},
      );

      final data = response.data;
      if (data == null || data['statusCode'] != '0000') {
        debugPrint('SmartOrder: Shop AI search failed, trying global');
        return _searchGlobalProducts(query);
      }

      final List<dynamic> products = data['data']?['matchedProducts'] ?? [];
      debugPrint('SmartOrder: Found ${products.length} products in shop');

      return products.take(5).map<Map<String, dynamic>>((p) => {
            'id': p['id']?.toString() ?? '',
            'name': p['displayName'] ?? p['name']?.toString() ?? '',
            'nameTamil': p['nameTamil']?.toString() ?? '',
            'price': p['price']?.toString() ?? '0',
            'image': _extractImage(p),
            'shopId': p['shopId']?.toString() ?? shopId.toString(),
            'shopDatabaseId': shopId,
            'shopName': shopName ?? '',
            'stockQuantity': p['stockQuantity'] ?? 999,
          }).toList();
    } catch (e) {
      debugPrint('SmartOrder: Shop search error: $e');
      return _searchGlobalProducts(query);
    }
  }

  String _extractImage(dynamic p) {
    if (p['primaryImageUrl'] != null) return p['primaryImageUrl'].toString();
    if (p['images'] != null && p['images'] is List && (p['images'] as List).isNotEmpty) {
      final img = (p['images'] as List).first;
      if (img is String) return img;
      if (img is Map) return img['imageUrl']?.toString() ?? '';
    }
    return '';
  }

  /// Global product search (grouped by keyword)
  Future<List<ParsedItem>> _searchGrouped(String query) async {
    try {
      final response = await ApiClient.post(
        '/v1/products/search/voice/grouped',
        queryParameters: {'q': query},
      );

      final data = response.data;
      if (data == null || data['statusCode'] != '0000') {
        final matches = await _searchGlobalProducts(query);
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
      final matches = await _searchGlobalProducts(query);
      return [ParsedItem(name: query, matches: matches)];
    }
  }

  /// Global product search (flat list)
  Future<List<Map<String, dynamic>>> _searchGlobalProducts(String query) async {
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
      debugPrint('SmartOrder: Global search error: $e');
      return [];
    }
  }

  /// Speak result summary in Tamil
  Future<void> _speakResult(List<ParsedItem> items) async {
    final totalMatches = items.fold<int>(0, (sum, i) => sum + i.matches.length);

    String message;
    if (totalMatches == 0) {
      message = 'பொருட்கள் கிடைக்கவில்லை. மீண்டும் முயற்சிக்கவும்.';
    } else {
      message = '$totalMatches பொருட்கள் கிடைத்தன. கார்ட்டில் சேர்க்கவா?';
    }

    await _ttsService.speak(message);
  }

  /// Speak custom message
  Future<void> speak(String text) => _ttsService.speak(text);

  /// Stop speaking
  Future<void> stopSpeaking() => _ttsService.stop();

  // ── OFFLINE INTELLIGENT SEARCH ENGINE ──

  final ProductSearchEngine _searchEngine = ProductSearchEngine();
  List<Map<String, dynamic>> _cachedProducts = [];
  bool _cacheLoaded = false;

  Future<void> _ensureCache() async {
    if (_cacheLoaded || shopId == null) return;
    try {
      final response = await ApiClient.get(
        '/customer/shops/$shopId/products',
        queryParameters: {'page': '0', 'size': '2000', 'sortBy': 'name', 'sortDir': 'asc'},
      );
      final data = response.data;
      if (data != null && data['statusCode'] == '0000') {
        final List<dynamic> products = data['data']?['content'] ?? [];
        _cachedProducts = products.map<Map<String, dynamic>>((p) {
          final name = (p['displayName'] ?? p['customName'] ?? '').toString();
          final nameTamil = (p['nameTamil'] ?? '').toString();
          final category = (p['categoryName'] ?? p['category'] ?? '').toString();
          final tags = (p['tags'] ?? '').toString();
          final baseWeight = p['baseWeight'];
          final baseUnit = (p['baseUnit'] ?? '').toString();
          String weightDisplay = '';
          if (baseWeight != null && baseUnit.isNotEmpty) {
            final w = double.tryParse(baseWeight.toString()) ?? 0;
            if (w > 0) {
              weightDisplay = w == w.roundToDouble()
                  ? '${w.toInt()}$baseUnit'
                  : '${w.toString()}$baseUnit';
            }
          }
          return {
            'id': p['id']?.toString() ?? '',
            'name': name,
            'nameTamil': nameTamil,
            'category': category,
            'tags': tags,
            'price': p['price']?.toString() ?? '0',
            'image': _extractImage(p),
            'shopId': p['shopId']?.toString() ?? shopId.toString(),
            'shopDatabaseId': shopId,
            'shopName': shopName ?? '',
            'baseWeight': baseWeight?.toString() ?? '',
            'baseUnit': baseUnit,
            'weightDisplay': weightDisplay,
          };
        }).toList();

        _searchEngine.indexProducts(_cachedProducts);
        _cacheLoaded = true;
        debugPrint('SmartOrder: Cached & indexed ${_cachedProducts.length} products');
      }
    } catch (e) {
      debugPrint('SmartOrder: Cache load error: $e');
    }
  }

  /// Get real-time suggestions — fully OFFLINE, no API calls
  Future<List<Map<String, dynamic>>> getSuggestions(String query) async {
    if (query.trim().length < 2) return [];
    await _ensureCache();
    if (!_searchEngine.isIndexed) return [];

    var results = _searchEngine.search(query.trim(), limit: 8);
    if (results.isNotEmpty) return results;

    results = _searchEngine.sttCorrectionSearch(query.trim(), limit: 8);
    return results;
  }

  /// Gemini AI search via backend — understands intent despite wrong STT words
  Future<List<Map<String, dynamic>>> aiSearchProducts(String query) async {
    if (query.trim().length < 2) return [];
    if (shopId == null) return _searchGlobalProducts(query);
    try {
      debugPrint('SmartOrder: AI search query="$query"');
      final response = await ApiClient.get(
        '/shops/$shopId/products/ai-search',
        queryParameters: {'query': query},
      );
      final data = response.data;
      if (data == null || data['statusCode'] != '0000') return [];

      final List<dynamic> products = data['data']?['matchedProducts'] ?? [];
      debugPrint('SmartOrder: AI found ${products.length} products');

      return products.take(8).map<Map<String, dynamic>>((p) {
        final baseWeight = p['baseWeight'];
        final baseUnit = (p['baseUnit'] ?? '').toString();
        String weightDisplay = '';
        if (baseWeight != null && baseUnit.isNotEmpty) {
          final w = double.tryParse(baseWeight.toString()) ?? 0;
          if (w > 0) {
            weightDisplay = w == w.roundToDouble()
                ? '${w.toInt()}$baseUnit'
                : '${w.toString()}$baseUnit';
          }
        }
        return {
          'id': p['id']?.toString() ?? '',
          'name': p['displayName'] ?? p['name']?.toString() ?? '',
          'nameTamil': p['nameTamil']?.toString() ?? '',
          'price': p['price']?.toString() ?? '0',
          'image': _extractImage(p),
          'shopId': p['shopId']?.toString() ?? shopId.toString(),
          'shopDatabaseId': shopId,
          'shopName': shopName ?? '',
          'baseWeight': baseWeight?.toString() ?? '',
          'baseUnit': baseUnit,
          'weightDisplay': weightDisplay,
        };
      }).toList();
    } catch (e) {
      debugPrint('SmartOrder: AI search error: $e');
      return [];
    }
  }

  void dispose() {
    _ttsService.dispose();
  }
}
