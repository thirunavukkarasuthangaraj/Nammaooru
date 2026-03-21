import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart';
import '../core/api/api_client.dart';

/// Response from Gemini conversation — either text or a function call.
class ConversationResponse {
  final String? text;
  final String? functionName;
  final Map<String, dynamic>? args;
  final String? error;

  bool get isText => text != null && text!.isNotEmpty;
  bool get isFunctionCall => functionName != null;
  bool get isError => error != null;

  ConversationResponse._({this.text, this.functionName, this.args, this.error});

  factory ConversationResponse.text(String text) =>
      ConversationResponse._(text: text);
  factory ConversationResponse.functionCall(
          String name, Map<String, dynamic> args) =>
      ConversationResponse._(functionName: name, args: args);
  factory ConversationResponse.error(String error) =>
      ConversationResponse._(error: error);
}

/// Gemini conversation service with function calling.
///
/// Maintains conversation history, sends messages to Gemini API,
/// handles function call responses. Gemini becomes the "brain" of
/// the voice assistant — deciding when to search, confirm, add to cart.
class GeminiConversationService {
  final List<Map<String, dynamic>> _history = [];
  final _rand = Random();
  String _systemPrompt = '';
  List<Map<String, dynamic>> _toolDeclarations = [];

  static const int _maxHistoryEntries = 30;

  void configure({
    required String systemPrompt,
    required List<Map<String, dynamic>> tools,
  }) {
    _systemPrompt = systemPrompt;
    _toolDeclarations = tools;
  }

  void clearHistory() {
    _history.clear();
  }

  /// Ensure Gemini API keys are loaded from backend
  Future<void> ensureApiKeys() async {
    if (EnvConfig.geminiApiKeys.isNotEmpty) return;
    try {
      final response = await ApiClient.get('/mobile/ai-config');
      final data = response.data;
      if (data != null && data['statusCode'] == '0000') {
        final config = data['data'];
        final List<dynamic> keys = config?['apiKeys'] ?? [];
        EnvConfig.geminiApiKeys =
            keys.map((k) => k.toString()).where((k) => k.isNotEmpty).toList();
        debugPrint(
            'GeminiConversation: Loaded ${EnvConfig.geminiApiKeys.length} API keys');
      }
    } catch (e) {
      debugPrint('GeminiConversation: Failed to load API keys: $e');
    }
  }

  String? _getApiKey() {
    final keys = EnvConfig.geminiApiKeys;
    if (keys.isEmpty) return null;
    return keys[_rand.nextInt(keys.length)];
  }

  /// Transcribe audio using Gemini API directly (no backend needed, faster)
  Future<String?> transcribeAudio(String base64Audio) async {
    final apiKey = _getApiKey();
    if (apiKey == null) return null;

    final url =
        '${EnvConfig.geminiApiUrl}/${EnvConfig.geminiModel}:generateContent?key=$apiKey';

    final body = {
      'contents': [
        {
          'parts': [
            {'text': 'Transcribe this audio. Return ONLY the exact spoken words. If silence or no speech, return exactly: EMPTY'},
            {
              'inline_data': {
                'mime_type': 'audio/wav',
                'data': base64Audio,
              }
            }
          ],
        }
      ],
      'generationConfig': {
        'temperature': 0.0,
        'maxOutputTokens': 200,
      },
    };

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('GeminiConversation: Transcribe error ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']
              ?.toString()
              ?.trim() ??
          '';

      if (text.isEmpty || text.toUpperCase() == 'EMPTY') return null;
      debugPrint('GeminiConversation: Transcribed: "$text"');
      return text;
    } catch (e) {
      debugPrint('GeminiConversation: Transcribe error: $e');
      return null;
    }
  }

  /// Send user text message and get response
  Future<ConversationResponse> chat(String userMessage) async {
    _history.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ],
    });
    return await _callGemini();
  }

  /// Send function execution result back to Gemini and get next response
  Future<ConversationResponse> sendFunctionResult(
    String functionName,
    Map<String, dynamic> callArgs,
    Map<String, dynamic> result,
  ) async {
    // Add the model's function call to history
    _history.add({
      'role': 'model',
      'parts': [
        {
          'functionCall': {'name': functionName, 'args': callArgs}
        }
      ],
    });
    // Add function response
    _history.add({
      'role': 'user',
      'parts': [
        {
          'functionResponse': {
            'name': functionName,
            'response': {'content': result}
          }
        }
      ],
    });
    return await _callGemini();
  }

  Future<ConversationResponse> _callGemini() async {
    final apiKey = _getApiKey();
    if (apiKey == null) {
      return ConversationResponse.error('No Gemini API key');
    }

    // Trim history to prevent oversized payloads
    if (_history.length > _maxHistoryEntries) {
      _history.removeRange(0, _history.length - _maxHistoryEntries);
    }

    final url =
        '${EnvConfig.geminiApiUrl}/${EnvConfig.geminiModel}:generateContent?key=$apiKey';

    final body = {
      'contents': _history,
      'systemInstruction': {
        'parts': [
          {'text': _systemPrompt}
        ],
      },
      'tools': [
        {'functionDeclarations': _toolDeclarations}
      ],
      'toolConfig': {
        'functionCallingConfig': {'mode': 'AUTO'},
      },
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 300,
      },
    };

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint(
            'GeminiConversation: API error ${response.statusCode}: ${response.body}');
        return ConversationResponse.error('API error: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final candidate = data['candidates']?[0];
      final content = candidate?['content'];
      final parts = (content?['parts'] as List?) ?? [];

      if (parts.isEmpty) {
        return ConversationResponse.error('Empty response');
      }

      // Check for function call first
      for (final part in parts) {
        if (part['functionCall'] != null) {
          final fc = part['functionCall'];
          final name = fc['name']?.toString() ?? '';
          final args = Map<String, dynamic>.from(fc['args'] ?? {});
          debugPrint('GeminiConversation: Function call: $name($args)');
          return ConversationResponse.functionCall(name, args);
        }
      }

      // Text response
      final text =
          parts.map((p) => p['text']?.toString() ?? '').join('').trim();

      // Add model response to history
      _history.add({
        'role': 'model',
        'parts': content['parts'],
      });

      debugPrint('GeminiConversation: Response: "$text"');
      return ConversationResponse.text(text);
    } catch (e) {
      debugPrint('GeminiConversation: Error: $e');
      return ConversationResponse.error(e.toString());
    }
  }

  /// Inject a function call + result into history without calling Gemini.
  /// Used when we execute an action directly (e.g., user tapped a product card)
  /// so Gemini's conversation context stays in sync.
  void injectFunctionExecution(
    String name,
    Map<String, dynamic> args,
    Map<String, dynamic> result,
  ) {
    _history.add({
      'role': 'model',
      'parts': [
        {
          'functionCall': {'name': name, 'args': args}
        }
      ],
    });
    _history.add({
      'role': 'user',
      'parts': [
        {
          'functionResponse': {
            'name': name,
            'response': {'content': result}
          }
        }
      ],
    });
  }

  /// Add a model text message to history (for local confirmations)
  void injectModelMessage(String text) {
    _history.add({
      'role': 'model',
      'parts': [
        {'text': text}
      ],
    });
  }

  void dispose() {
    _history.clear();
  }
}
