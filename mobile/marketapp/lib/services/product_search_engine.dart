import 'package:flutter/foundation.dart';

/// Offline intelligent product search engine — no internet needed.
///
/// Mimics Gemini AI search locally using:
///   - Inverted index (word → product IDs)
///   - Tamil ↔ Latin transliteration
///   - Phonetic normalization (th→t, kk→k, etc.)
///   - Fuzzy matching (Levenshtein distance)
///   - Category-based search
///   - Auto-built synonym pairs from Tamil+English names
///
/// Usage:
///   final engine = ProductSearchEngine();
///   engine.indexProducts(products); // call once after loading from API
///   final results = engine.search('arisi');  // instant, offline
class ProductSearchEngine {
  // ── Product store ──
  final List<Map<String, dynamic>> _products = [];
  final Map<String, Map<String, dynamic>> _idMap = {}; // id → product

  // ── Inverted indices (word → set of product IDs) ──
  final Map<String, Set<String>> _tagsIndex = {};      // Tags (HIGHEST priority, 100 pts)
  final Map<String, Set<String>> _nameIndex = {};      // English name words
  final Map<String, Set<String>> _tamilIndex = {};     // Tamil script words
  final Map<String, Set<String>> _translitIndex = {};  // Latin transliteration
  final Map<String, Set<String>> _phoneticIndex = {};  // Phonetic keys
  final Map<String, Set<String>> _categoryIndex = {};  // Category → products
  final Map<String, Set<String>> _synonymIndex = {};   // Synonym → products

  // ── Auto-built synonym pairs (Tamil name ↔ English name) ──
  final Map<String, String> _synonymPairs = {};

  bool _indexed = false;
  bool get isIndexed => _indexed;
  int get productCount => _products.length;

  /// Index all products — call once after loading from API.
  /// Builds all search indices for instant offline search.
  void indexProducts(List<Map<String, dynamic>> products) {
    _products.clear();
    _idMap.clear();
    _tagsIndex.clear();
    _nameIndex.clear();
    _tamilIndex.clear();
    _translitIndex.clear();
    _phoneticIndex.clear();
    _categoryIndex.clear();
    _synonymIndex.clear();
    _synonymPairs.clear();

    for (final p in products) {
      final id = p['id']?.toString() ?? '';
      if (id.isEmpty) continue;

      final name = (p['name'] ?? '').toString();
      final nameTamil = (p['nameTamil'] ?? '').toString();
      final category = (p['category'] ?? p['categoryName'] ?? '').toString();
      final tags = (p['tags'] ?? '').toString(); // "Rice, அரிசி, Groceries, Aashirvaad"

      // Store product
      _products.add(p);
      _idMap[id] = p;

      // 1. INDEX TAGS — HIGHEST PRIORITY (same as backend: 100 points)
      //    Tags contain: English name, Tamil name, category, brand, SKU
      //    Format: comma-separated "Rice, அரிசி, Groceries, Aashirvaad"
      if (tags.isNotEmpty) {
        // Split by comma and index each tag
        final tagParts = tags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty);
        for (final tag in tagParts) {
          final tagLower = tag.toLowerCase();
          _tagsIndex.putIfAbsent(tagLower, () => {}).add(id);
          // Also index individual words within each tag
          for (final word in _tokenize(tag)) {
            _tagsIndex.putIfAbsent(word, () => {}).add(id);
          }
          // If tag is Tamil script, also index its transliteration
          if (_containsTamil(tag)) {
            final translit = tamilToLatin(tag).toLowerCase();
            if (translit.isNotEmpty) {
              _tagsIndex.putIfAbsent(translit, () => {}).add(id);
              for (final word in _tokenize(translit)) {
                _tagsIndex.putIfAbsent(word, () => {}).add(id);
                // Phonetic key for tag transliterations
                final phonetic = _phoneticKey(word);
                if (phonetic.isNotEmpty) {
                  _phoneticIndex.putIfAbsent(phonetic, () => {}).add(id);
                }
              }
            }
          }
        }
      }

      // 2. Index English name words
      for (final word in _tokenize(name)) {
        _nameIndex.putIfAbsent(word, () => {}).add(id);
      }

      // 3. Index Tamil script words
      if (nameTamil.isNotEmpty) {
        for (final word in _tokenize(nameTamil)) {
          _tamilIndex.putIfAbsent(word, () => {}).add(id);
        }

        // 4. Convert Tamil → Latin transliteration and index
        final translit = tamilToLatin(nameTamil).toLowerCase();
        if (translit.isNotEmpty) {
          for (final word in _tokenize(translit)) {
            _translitIndex.putIfAbsent(word, () => {}).add(id);
            // Also index phonetic key
            final phonetic = _phoneticKey(word);
            if (phonetic.isNotEmpty) {
              _phoneticIndex.putIfAbsent(phonetic, () => {}).add(id);
            }
          }
        }

        // 5. Build synonym pair: Tamil transliteration ↔ English name
        if (name.isNotEmpty && translit.isNotEmpty) {
          final enLower = name.toLowerCase().trim();
          final trLower = translit.trim();
          _synonymPairs[trLower] = enLower;
          _synonymPairs[enLower] = trLower;
          // Index English name phonetically too
          for (final word in _tokenize(name)) {
            final phonetic = _phoneticKey(word);
            if (phonetic.isNotEmpty) {
              _phoneticIndex.putIfAbsent(phonetic, () => {}).add(id);
            }
          }
        }
      }

      // 6. Index category
      if (category.isNotEmpty) {
        final catLower = category.toLowerCase().trim();
        _categoryIndex.putIfAbsent(catLower, () => {}).add(id);
        for (final word in _tokenize(category)) {
          _categoryIndex.putIfAbsent(word, () => {}).add(id);
        }
      }
    }

    _indexed = true;
    debugPrint('SearchEngine: Indexed ${_products.length} products, '
        '${_tagsIndex.length} tag terms, '
        '${_nameIndex.length} name terms, '
        '${_translitIndex.length} translit terms, '
        '${_phoneticIndex.length} phonetic keys, '
        '${_categoryIndex.length} categories');
  }

  /// Check if text contains Tamil Unicode characters
  static bool _containsTamil(String text) {
    return RegExp(r'[\u0B80-\u0BFF]').hasMatch(text);
  }

  /// Main search — returns ranked products (offline, instant)
  ///
  /// Handles: English, Tamil script, Tamil transliteration, typos,
  /// category names, synonyms, partial words
  List<Map<String, dynamic>> search(String query, {int limit = 8}) {
    if (!_indexed || query.trim().isEmpty) return [];
    final q = query.trim().toLowerCase();
    if (q.length < 2) return [];

    // Score each product — same priority as backend:
    //   Tags: 100, Tamil name: 75, English name: 50, Fuzzy: 25
    final scores = <String, int>{}; // productId → score

    // Strategy 1: TAGS — HIGHEST PRIORITY (100 pts)
    //   Tags contain: English name, Tamil name, transliteration, category, brand
    //   Backend gives tags 100 points — same here
    _scoreFromIndex(_tagsIndex, _tokenize(q), scores, baseScore: 100);
    // Also search tags with full query as one phrase
    if (_tagsIndex.containsKey(q)) {
      for (final id in _tagsIndex[q]!) {
        scores[id] = (scores[id] ?? 0) + 100;
      }
    }

    // Strategy 2: Tamil name match (75 pts — same as backend)
    _scoreFromIndex(_tamilIndex, _tokenize(q), scores, baseScore: 75);

    // Strategy 3: English name match (50 pts — same as backend)
    _scoreFromIndex(_nameIndex, _tokenize(q), scores, baseScore: 50);

    // Strategy 4: Transliteration match (90 pts)
    //   User types "arisi" → matches transliteration index "arisi" → finds "Rice"
    _scoreFromIndex(_translitIndex, _tokenize(q), scores, baseScore: 90);

    // Strategy 5: Phonetic match (80 pts — handles th/t, kk/k variations)
    //   "takkali" → phonetic "takali" → matches "thakkali" → "Tomato"
    final phoneticTokens = _tokenize(q).map(_phoneticKey).where((p) => p.length >= 3).toList();
    _scoreFromIndex(_phoneticIndex, phoneticTokens, scores, baseScore: 80);

    // Strategy 6: Synonym lookup
    //   User types "thakkali" → synonym map → "tomato" → search in name/tags
    final synonymQuery = _synonymPairs[q];
    if (synonymQuery != null) {
      _scoreFromIndex(_tagsIndex, _tokenize(synonymQuery), scores, baseScore: 90);
      _scoreFromIndex(_nameIndex, _tokenize(synonymQuery), scores, baseScore: 50);
    }
    for (final word in _tokenize(q)) {
      final syn = _synonymPairs[word];
      if (syn != null) {
        _scoreFromIndex(_tagsIndex, _tokenize(syn), scores, baseScore: 85);
        _scoreFromIndex(_nameIndex, _tokenize(syn), scores, baseScore: 50);
      }
    }

    // Strategy 7: Category match (50 pts)
    _scoreFromIndex(_categoryIndex, _tokenize(q), scores, baseScore: 50);

    // Strategy 8: Fuzzy matching for typos (25 pts — same as backend)
    if (scores.length < 3 && q.length >= 4) {
      _fuzzySearch(q, scores);
    }

    // Strategy 9: Substring matching (catch-all, 30 pts)
    if (scores.isEmpty && q.length >= 3) {
      _substringSearch(q, scores);
    }

    // Sort by score descending, return top results
    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ranked
        .take(limit)
        .map((e) => _idMap[e.key])
        .where((p) => p != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  /// STT Correction Search — handles speech-to-text misrecognition for ANY product
  ///
  /// Problem: STT breaks/mishears product names:
  ///   "onion" → "only on", "tomato" → "to motto", "sugar" → "should gar"
  ///   "potato" → "pot auto", "coconut" → "coco not", "dal" → "doll"
  ///
  /// Solution: Generate candidate strings from STT text, then compare
  /// EVERY candidate against EVERY product using Levenshtein distance.
  /// Works for ALL products — no hardcoding needed.
  List<Map<String, dynamic>> sttCorrectionSearch(String sttText, {int limit = 5}) {
    if (!_indexed || sttText.trim().isEmpty) return [];
    final words = sttText.trim().toLowerCase().split(RegExp(r'\s+'));
    if (words.isEmpty) return [];

    // Generate candidate strings from STT output
    final candidates = <String>{};

    // 1. Join ALL words: "only on" → "onlyon"
    final joined = words.join('');
    if (joined.length >= 3) candidates.add(joined);

    // 2. Join adjacent pairs: ["to","motto"] → "tomotto"
    for (int i = 0; i < words.length - 1; i++) {
      final pair = '${words[i]}${words[i + 1]}';
      if (pair.length >= 3) candidates.add(pair);
    }

    // 3. Join triplets for longer names
    for (int i = 0; i < words.length - 2; i++) {
      final trip = '${words[i]}${words[i + 1]}${words[i + 2]}';
      if (trip.length >= 4) candidates.add(trip);
    }

    // 4. Drop short (1-char) words and rejoin
    final filtered = words.where((w) => w.length > 1).toList();
    if (filtered.isNotEmpty && filtered.join('') != joined) {
      candidates.add(filtered.join(''));
    }

    // 5. Each word individually (3+ chars)
    for (final w in words) {
      if (w.length >= 3) candidates.add(w);
    }

    // 6. Phonetic keys of all candidates
    final phoneticCandidates = <String>{};
    for (final c in candidates) {
      final pk = _phoneticKey(c);
      if (pk.length >= 3) phoneticCandidates.add(pk);
    }

    // Now compare candidates against EVERY product (brute-force, but fast for ~2000 products)
    final scores = <String, double>{}; // productId → best similarity

    for (final p in _products) {
      final id = p['id']?.toString() ?? '';
      if (id.isEmpty) continue;

      // Collect all searchable strings for this product
      final productStrings = <String>[];
      final name = (p['name'] ?? '').toString().toLowerCase();
      final tamil = (p['nameTamil'] ?? '').toString().toLowerCase();
      final tags = (p['tags'] ?? '').toString().toLowerCase();

      if (name.isNotEmpty) {
        productStrings.add(name);
        // Also add individual words from name
        for (final w in name.split(RegExp(r'\s+'))) {
          if (w.length >= 3) productStrings.add(w);
        }
      }

      // Add tag values
      if (tags.isNotEmpty) {
        for (final tag in tags.split(',')) {
          final t = tag.trim();
          if (t.length >= 2) {
            productStrings.add(t);
            for (final w in t.split(RegExp(r'\s+'))) {
              if (w.length >= 3) productStrings.add(w);
            }
          }
        }
      }

      // Add Tamil transliteration
      if (tamil.isNotEmpty && _containsTamil(tamil)) {
        final translit = tamilToLatin(tamil).toLowerCase();
        if (translit.isNotEmpty) {
          productStrings.add(translit);
          for (final w in translit.split(RegExp(r'\s+'))) {
            if (w.length >= 3) productStrings.add(w);
          }
        }
      }

      // Phonetic keys of product strings
      final productPhonetics = productStrings
          .map(_phoneticKey)
          .where((pk) => pk.length >= 3)
          .toSet();

      double bestSim = 0;

      // Compare each candidate against each product string
      for (final candidate in candidates) {
        for (final ps in productStrings) {
          final sim = _similarity(candidate, ps);
          if (sim > bestSim) bestSim = sim;
          if (bestSim >= 0.9) break; // Good enough
        }
        if (bestSim >= 0.9) break;
      }

      // Also compare phonetic candidates against product phonetics
      if (bestSim < 0.9) {
        for (final pc in phoneticCandidates) {
          for (final pp in productPhonetics) {
            final sim = _similarity(pc, pp);
            // Phonetic matches get slight boost
            final boosted = sim * 1.1;
            if (boosted > bestSim) bestSim = boosted > 1.0 ? 1.0 : boosted;
            if (bestSim >= 0.9) break;
          }
          if (bestSim >= 0.9) break;
        }
      }

      // Only include if similarity >= 55% (relaxed threshold for STT errors)
      if (bestSim >= 0.55) {
        scores[id] = bestSim;
      }
    }

    if (scores.isEmpty) return [];

    // Sort by similarity descending
    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ranked
        .take(limit)
        .map((e) => _idMap[e.key])
        .where((p) => p != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  /// Compute similarity between two strings (0.0 to 1.0)
  static double _similarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final maxLen = a.length > b.length ? a.length : b.length;
    if ((a.length - b.length).abs() > maxLen * 0.5) return 0.0; // Quick reject
    final dist = _levenshtein(a, b);
    return 1.0 - (dist / maxLen);
  }

  // ── Scoring helpers ──

  void _scoreFromIndex(
    Map<String, Set<String>> index,
    List<String> queryTokens,
    Map<String, int> scores, {
    required int baseScore,
  }) {
    for (final token in queryTokens) {
      if (token.length < 2) continue;

      // Exact token match
      final exact = index[token];
      if (exact != null) {
        for (final id in exact) {
          scores[id] = (scores[id] ?? 0) + baseScore;
        }
      }

      // Prefix match: "tom" matches "tomato"
      if (token.length >= 3) {
        for (final entry in index.entries) {
          if (entry.key.startsWith(token) && entry.key != token) {
            for (final id in entry.value) {
              scores[id] = (scores[id] ?? 0) + (baseScore * 0.7).round();
            }
          }
        }
      }
    }
  }

  /// Fuzzy search — find words within edit distance 2
  void _fuzzySearch(String query, Map<String, int> scores) {
    final qTokens = _tokenize(query);
    for (final qt in qTokens) {
      if (qt.length < 4) continue;
      // Check against tags index (highest priority fuzzy)
      for (final entry in _tagsIndex.entries) {
        if (entry.key.length >= 4 && _isFuzzyMatch(qt, entry.key)) {
          for (final id in entry.value) {
            scores[id] = (scores[id] ?? 0) + 50;
          }
        }
      }
      // Check against name index
      for (final entry in _nameIndex.entries) {
        if (_isFuzzyMatch(qt, entry.key)) {
          for (final id in entry.value) {
            scores[id] = (scores[id] ?? 0) + 25;
          }
        }
      }
      // Check against transliteration index
      for (final entry in _translitIndex.entries) {
        if (_isFuzzyMatch(qt, entry.key)) {
          for (final id in entry.value) {
            scores[id] = (scores[id] ?? 0) + 40;
          }
        }
      }
    }
  }

  /// Substring search — "bas" finds "basmati rice"
  void _substringSearch(String query, Map<String, int> scores) {
    for (final p in _products) {
      final name = (p['_searchName'] ?? p['name']?.toString().toLowerCase() ?? '');
      final tamil = (p['_searchTamil'] ?? p['nameTamil']?.toString().toLowerCase() ?? '');
      final tags = (p['tags'] ?? '').toString().toLowerCase();
      final id = p['id']?.toString() ?? '';
      // Search in tags first (highest priority), then name/Tamil
      if (tags.contains(query)) {
        scores[id] = (scores[id] ?? 0) + 50;
      } else if (name.contains(query) || tamil.contains(query)) {
        scores[id] = (scores[id] ?? 0) + 30;
      }
    }
  }

  // ── Tokenization ──

  /// Split text into searchable tokens (lowercase, filter short words)
  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0B80-\u0BFF]'), ' ') // keep Tamil chars
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)
        .toList();
  }

  // ── Phonetic normalization ──
  // "thakkali" / "takkali" / "takali" all → "takali"

  static String _phoneticKey(String text) {
    if (text.isEmpty) return '';
    var s = text.toLowerCase().trim();
    // Remove 'h' after consonants
    s = s.replaceAll('th', 't').replaceAll('dh', 'd').replaceAll('bh', 'b')
         .replaceAll('kh', 'k').replaceAll('ph', 'p').replaceAll('gh', 'g')
         .replaceAll('sh', 's').replaceAll('zh', 'z').replaceAll('ch', 'c');
    // Collapse double consonants
    s = s.replaceAll(RegExp(r'([bcdfghjklmnpqrstvwxyz])\1+'), r'$1');
    // Normalize vowel variations
    s = s.replaceAll('aa', 'a').replaceAll('ee', 'e').replaceAll('ii', 'i')
         .replaceAll('oo', 'o').replaceAll('uu', 'u').replaceAll('ai', 'a');
    return s;
  }

  // ── Fuzzy matching (Levenshtein) ──

  bool _isFuzzyMatch(String a, String b) {
    if (a == b) return true;
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen == 0) return true;
    if ((a.length - b.length).abs() > 3) return false; // Quick reject
    final dist = _levenshtein(a, b);
    return (1 - dist / maxLen) >= 0.70; // 70% similarity threshold
  }

  static int _levenshtein(String s, String t) {
    final n = s.length, m = t.length;
    if (n == 0) return m;
    if (m == 0) return n;
    var prev = List.generate(m + 1, (i) => i);
    var curr = List.filled(m + 1, 0);
    for (var i = 1; i <= n; i++) {
      curr[0] = i;
      for (var j = 1; j <= m; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        curr[j] = [curr[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost]
            .reduce((a, b) => a < b ? a : b);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[m];
  }

  // ══════════════════════════════════════════════════════
  // ── Tamil to Latin Transliteration (pure Dart, no API)
  // ══════════════════════════════════════════════════════
  // "தக்காளி" → "thakkali", "அரிசி" → "arisi"

  static final Map<String, String> _tamilConsonants = {
    'க': 'ka', 'ங': 'nga', 'ச': 'sa', 'ஞ': 'nya', 'ட': 'da',
    'ண': 'na', 'த': 'tha', 'ந': 'na', 'ப': 'pa', 'ம': 'ma',
    'ய': 'ya', 'ர': 'ra', 'ல': 'la', 'வ': 'va', 'ழ': 'zha',
    'ள': 'la', 'ற': 'ra', 'ன': 'na',
  };

  static final Map<String, String> _tamilVowels = {
    'அ': 'a', 'ஆ': 'aa', 'இ': 'i', 'ஈ': 'ii', 'உ': 'u', 'ஊ': 'uu',
    'எ': 'e', 'ஏ': 'ee', 'ஐ': 'ai', 'ஒ': 'o', 'ஓ': 'oo', 'ஔ': 'au',
  };

  static final Map<String, String> _tamilVowelSigns = {
    'ா': 'aa', 'ி': 'i', 'ீ': 'ii', 'ு': 'u', 'ூ': 'uu',
    'ெ': 'e', 'ே': 'ee', 'ை': 'ai', 'ொ': 'o', 'ோ': 'oo', 'ௌ': 'au',
  };

  static const String _pulli = '்'; // Virama

  /// Convert Tamil script to Latin transliteration
  static String tamilToLatin(String tamil) {
    if (tamil.isEmpty) return '';
    final buf = StringBuffer();
    final chars = tamil.runes.toList();

    for (int i = 0; i < chars.length; i++) {
      final ch = String.fromCharCode(chars[i]);

      if (_tamilVowels.containsKey(ch)) {
        buf.write(_tamilVowels[ch]);
        continue;
      }

      if (_tamilConsonants.containsKey(ch)) {
        final base = _tamilConsonants[ch]!;
        final consonant = base.substring(0, base.length - 1);

        if (i + 1 < chars.length) {
          final next = String.fromCharCode(chars[i + 1]);
          if (next == _pulli) {
            buf.write(consonant);
            i++;
          } else if (_tamilVowelSigns.containsKey(next)) {
            buf.write(consonant);
            buf.write(_tamilVowelSigns[next]);
            i++;
          } else {
            buf.write(base);
          }
        } else {
          buf.write(base);
        }
        continue;
      }

      // Pass through English chars, numbers, spaces
      if (ch == ' ' || ch == '-' || RegExp(r'[a-zA-Z0-9]').hasMatch(ch)) {
        buf.write(ch.toLowerCase());
      }
    }
    return buf.toString();
  }
}
