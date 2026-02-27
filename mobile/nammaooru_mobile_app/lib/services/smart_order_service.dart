import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/config/env_config.dart';
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
  bool _aiConfigLoaded = false;

  /// Shop context — when set, searches within this shop only
  int? shopId;
  String? shopName;

  TtsService get ttsService => _ttsService;
  VoiceSearchService get voiceService => _voiceService;

  /// Fetch Gemini AI config (keys) from backend — call once on init
  Future<void> loadAiConfig() async {
    if (_aiConfigLoaded && EnvConfig.geminiApiKeys.isNotEmpty) return;
    try {
      final response = await ApiClient.get('/mobile/ai-config');
      final data = response.data;
      if (data != null && data['statusCode'] == '0000') {
        final config = data['data'];
        final List<dynamic> keys = config?['apiKeys'] ?? [];
        EnvConfig.geminiApiKeys = keys.map((k) => k.toString()).where((k) => k.isNotEmpty).toList();
        debugPrint('SmartOrder: Loaded ${EnvConfig.geminiApiKeys.length} Gemini API keys from backend');
        _aiConfigLoaded = true;
      }
    } catch (e) {
      debugPrint('SmartOrder: Failed to load AI config from backend: $e');
    }
    // Fallback: use built-in keys if backend not available
    if (EnvConfig.geminiApiKeys.isEmpty) {
      EnvConfig.geminiApiKeys = const [
        'AIzaSyAZDAB-axvYDirGQLL4XmxrLVbyiI2BLOI',
        'AIzaSyC3rhnK0i2-nr9jMZ3AS2i7ABvjZgjkno0',
        'AIzaSyDIdOFfZPsubX1jytyeubSSPS5bGOqX-UU',
        'AIzaSyCpAnofkz9oGJjGEiWKTzt8I4AQKniZLqo',
      ];
      debugPrint('SmartOrder: Using fallback Gemini API keys');
    }
  }

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

  /// Last error message for UI display
  String? lastError;

  /// MODE 2: Photo → Gemini Vision (direct call) → parse → search products
  Future<SmartOrderResult?> processPhotoOrder(File imageFile) async {
    debugPrint('SmartOrder: Processing photo order...');
    lastError = null;
    try {
      // Read image and convert to base64
      final bytes = await imageFile.readAsBytes();
      debugPrint('SmartOrder: Image size: ${bytes.length} bytes');
      final base64Image = base64Encode(bytes);
      final ext = imageFile.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      debugPrint('SmartOrder: Calling Gemini Vision (mime: $mimeType, base64 len: ${base64Image.length})');

      // Call Gemini Vision API directly (no backend needed)
      final parsedItems = await _callGeminiVision(base64Image, mimeType);
      debugPrint('SmartOrder: Parsed ${parsedItems.length} items from image: $parsedItems');

      if (parsedItems.isEmpty) {
        lastError = lastError ?? 'Gemini could not read items from the image';
        return null;
      }

      // Filter out quantity words and search each item
      List<ParsedItem> items = [];
      for (final itemName in parsedItems) {
        final name = itemName.toString().trim();
        if (name.isEmpty) continue;
        // Split each parsed item into product terms (removes quantity words)
        final terms = _splitIntoTerms(name);
        for (final term in terms) {
          final matches = await _searchShopProducts(term);
          items.add(ParsedItem(name: term, matches: matches));
        }
      }

      final rawText = parsedItems.join(', ');
      await _speakResult(items);
      return SmartOrderResult(rawInput: rawText, items: items, mode: 'photo');
    } catch (e) {
      debugPrint('SmartOrder: Photo order error: $e');
      lastError = e.toString();
      return null;
    }
  }

  /// Call Gemini Vision API directly from the mobile app
  Future<List<String>> _callGeminiVision(String base64Image, String mimeType) async {
    // Round-robin key selection
    final keys = EnvConfig.geminiApiKeys;
    if (keys.isEmpty) {
      debugPrint('SmartOrder: No Gemini API keys configured');
      return [];
    }
    final apiKey = keys[Random().nextInt(keys.length)];
    final url =
        '${EnvConfig.geminiApiUrl}/${EnvConfig.geminiModel}:generateContent?key=$apiKey';

    final prompt =
        'This image is a handwritten grocery/shopping list in Tamil or English. '
        'Rules: '
        '1. Each LINE = ONE item. Do NOT split words. '
        '2. Use SINGULAR form: "tomatoes"→"tomato", "onions"→"onion", "eggs"→"egg". '
        '3. NO DUPLICATES — if same item appears multiple times, include it ONLY ONCE. '
        '4. Fix handwriting misreads: "toma to"→"tomato", "onli on"→"onion". '
        '5. Ignore quantities/numbers — only return the product name. '
        'Return ONLY a JSON array. Example: ["onion", "tomato", "அரிசி", "sugar"]. '
        'If not a shopping list, return [].';

    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              }
            }
          ]
        }
      ]
    };

    try {
      final dio = Dio();
      final response = await dio.post(
        url,
        data: body,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final data = response.data;
      final text = data?['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
      debugPrint('SmartOrder: Gemini Vision response: $text');

      // Extract JSON array from response (may be wrapped in markdown)
      var jsonStr = text.trim();
      if (jsonStr.contains('[')) {
        jsonStr = jsonStr.substring(jsonStr.indexOf('['), jsonStr.lastIndexOf(']') + 1);
      }

      final List<dynamic> parsed = jsonDecode(jsonStr);
      // Deduplicate (case-insensitive) and clean up
      final seen = <String>{};
      final results = <String>[];
      for (final item in parsed) {
        final name = item.toString().trim().toLowerCase();
        if (name.isNotEmpty && seen.add(name)) {
          results.add(item.toString().trim());
        }
      }
      return results;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final errorBody = e.response?.data;
      debugPrint('SmartOrder: Gemini Vision API error: $statusCode - $errorBody');
      lastError = 'Gemini API: ${statusCode ?? "network error"} - ${e.message}';
      return [];
    } catch (e) {
      debugPrint('SmartOrder: Gemini Vision parse error: $e');
      lastError = 'Parse error: $e';
      return [];
    }
  }

  /// MODE 3: Text → search products
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
      // Shop-specific: split text into individual product terms,
      // then search each term within the shop using AI search.
      final terms = _splitIntoTerms(query);
      debugPrint('SmartOrder: Split "$query" → $terms');

      List<ParsedItem> items = [];
      for (final term in terms) {
        final matches = await _searchShopProducts(term);
        items.add(ParsedItem(name: term, matches: matches));
      }
      return items;
    } else {
      // Global: use grouped voice search
      return _searchGrouped(query);
    }
  }

  /// Tamil/English quantity & unit words to filter out before searching
  static final Set<String> _quantityWords = {
    // Tamil numbers
    'ஒரு', 'இரண்டு', 'மூன்று', 'நான்கு', 'ஐந்து',
    'ஆறு', 'ஏழு', 'எட்டு', 'ஒன்பது', 'பத்து',
    'அரை', 'ஒன்றரை', 'இரண்டரை',
    // Tamil units
    'கிலோ', 'கிராம்', 'லிட்டர்', 'மில்லி', 'பாக்கெட்', 'டஜன்',
    'கேஜி', 'லிட்', 'பாக்',
    // English numbers & units
    'kg', 'kilo', 'gram', 'grams', 'liter', 'litre', 'ml',
    'packet', 'pack', 'dozen', 'half', 'quarter',
    'one', 'two', 'three', 'four', 'five',
  };

  /// Split voice/text input into individual product terms
  /// Filters out quantity words (ஒரு, கிலோ, kg, etc.)
  List<String> _splitIntoTerms(String text) {
    // Replace Tamil "and" (மற்றும்) and English "and" with comma
    var normalized = text
        .replaceAll('மற்றும்', ',')
        .replaceAll(' and ', ',')
        .replaceAll('  ', ' ');

    // Split by commas/newlines first
    var parts = normalized
        .split(RegExp(r'[,\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    List<String> productTerms = [];
    for (final part in parts) {
      // Remove quantity/unit words and bare numbers from each part
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

  /// Remove English plural suffix: tomatos→tomato, tomatoes→tomato, onions→onion
  String _removePlural(String word) {
    // Only for English words (Tamil words don't use 's' plurals)
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(word) || word.length <= 3) {
      return word;
    }
    final lower = word.toLowerCase();
    if (lower.endsWith('oes')) {
      // tomatoes → tomato, potatoes → potato
      return word.substring(0, word.length - 2);
    } else if (lower.endsWith('s') && !lower.endsWith('ss')) {
      // tomatos → tomato, onions → onion, eggs → egg
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
            'shopDatabaseId': shopId, // numeric DB ID needed for order creation
            'shopName': shopName ?? '',
            'stockQuantity': p['stockQuantity'] ?? 999,
          }).toList();
    } catch (e) {
      debugPrint('SmartOrder: Shop search error: $e');
      return _searchGlobalProducts(query);
    }
  }

  /// Extract first image from product response
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

  // ══════════════════════════════════════════════════════════════
  // ── OFFLINE INTELLIGENT SEARCH ENGINE (no internet needed) ──
  // ══════════════════════════════════════════════════════════════

  final ProductSearchEngine _searchEngine = ProductSearchEngine();
  List<Map<String, dynamic>> _cachedProducts = [];
  bool _cacheLoaded = false;

  /// Load all shop products once → index locally for instant search
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
          final tags = (p['tags'] ?? '').toString(); // "Rice, அரிசி, Groceries, Aashirvaad"
          final baseWeight = p['baseWeight'];
          final baseUnit = (p['baseUnit'] ?? '').toString();
          // Build weight display: "500g", "1kg", "2litre"
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

        // Build search indices (inverted index, transliteration, phonetic, etc.)
        _searchEngine.indexProducts(_cachedProducts);
        _cacheLoaded = true;
        debugPrint('SmartOrder: Cached & indexed ${_cachedProducts.length} products');
      }
    } catch (e) {
      debugPrint('SmartOrder: Cache load error: $e');
    }
  }

  // ── PUBLIC SUGGESTION API ──

  /// Get real-time suggestions — fully OFFLINE, no API calls
  /// Uses ProductSearchEngine: inverted index, Tamil transliteration,
  /// phonetic matching, fuzzy matching, synonyms, category search
  /// + STT correction for misrecognized voice input
  Future<List<Map<String, dynamic>>> getSuggestions(String query) async {
    if (query.trim().length < 2) return [];
    await _ensureCache();
    if (!_searchEngine.isIndexed) return [];

    // Normal search first
    var results = _searchEngine.search(query.trim(), limit: 8);
    if (results.isNotEmpty) return results;

    // STT correction — handles voice misrecognition
    // e.g., "only on" → "onlyon" → fuzzy → "onion"
    results = _searchEngine.sttCorrectionSearch(query.trim(), limit: 8);
    return results;
  }

  /// Gemini AI search via backend — understands intent despite wrong STT words
  /// Call this when offline suggestions fail (e.g., after voice final result)
  Future<List<Map<String, dynamic>>> aiSearchProducts(String query) async {
    if (query.trim().length < 2 || shopId == null) return [];
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
