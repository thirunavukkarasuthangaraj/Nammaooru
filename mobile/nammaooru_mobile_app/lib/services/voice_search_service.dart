import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import '../core/config/env_config.dart';

/// Voice search service — records audio and sends to Gemini backend for transcription.
/// Replaces device STT (speech_to_text) which has poor Tamil recognition.
class VoiceSearchService {
  final Record _recorder = Record();
  bool _isListening = false;
  bool _isRecording = false;
  String _lastWords = '';
  String? _lastError;
  String? _audioPath;

  /// Check if microphone permission is available
  Future<bool> initialize() async {
    try {
      final hasPerms = await _recorder.hasPermission();
      debugPrint('VoiceSearch: Mic permission: $hasPerms');
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
    try {
      if (_isRecording) await stopListening();

      final hasPerms = await _recorder.hasPermission();
      if (!hasPerms) {
        _lastError = 'Microphone permission not granted';
        return false;
      }

      _audioPath = '${Directory.systemTemp.path}/voice_search_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        path: _audioPath!,
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        samplingRate: 16000,
      );

      _isRecording = true;
      _isListening = true;
      _lastError = null;
      debugPrint('VoiceSearch: Recording started');
      return true;
    } catch (e) {
      _lastError = 'Failed to start recording: $e';
      debugPrint('VoiceSearch: $_lastError');
      _isRecording = false;
      _isListening = false;
      return false;
    }
  }

  /// Stop recording and transcribe via Gemini backend
  Future<String?> stopAndTranscribe() async {
    try {
      if (!_isRecording) return null;

      final path = await _recorder.stop();
      _isRecording = false;
      _isListening = false;
      final audioPath = path ?? _audioPath;

      if (audioPath == null) {
        _lastError = 'No audio recorded';
        return null;
      }

      debugPrint('VoiceSearch: Recording stopped, transcribing...');
      final transcription = await _transcribeAudio(audioPath);
      _lastWords = transcription ?? '';

      if (_lastWords.isEmpty) {
        _lastError = 'No speech detected. Please try again.';
        return null;
      }

      return _lastWords;
    } catch (e) {
      _lastError = 'Error during transcription: $e';
      debugPrint('VoiceSearch: $_lastError');
      _isRecording = false;
      _isListening = false;
      return null;
    }
  }

  /// Send audio to backend Gemini transcription endpoint
  Future<String?> _transcribeAudio(String audioPath) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        debugPrint('VoiceSearch: Audio file not found: $audioPath');
        return null;
      }

      final fileSize = await file.length();
      debugPrint('VoiceSearch: Sending audio (${fileSize ~/ 1024}KB) to Gemini...');

      final uri = Uri.parse('${EnvConfig.fullApiUrl}/v1/products/search/voice-audio');

      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        audioPath,
        filename: 'voice.m4a',
      ));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['statusCode'] == '0000' && data['data'] != null) {
          final transcription = data['data']['transcription']?.toString() ?? '';
          debugPrint('VoiceSearch: Transcription = "$transcription"');
          return transcription.isNotEmpty ? transcription : null;
        }
      }

      debugPrint('VoiceSearch: Transcription failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('VoiceSearch: Transcription error: $e');
      return null;
    } finally {
      _cleanupAudioFile(audioPath);
    }
  }

  /// Legacy listen() — records for up to 10 seconds, then transcribes via Gemini.
  /// Used by screens that call listen() and wait for result.
  Future<String?> listen({String? localeId}) async {
    debugPrint('VoiceSearch: listen() called');

    if (!await initialize()) {
      debugPrint('VoiceSearch: initialize() failed');
      return null;
    }

    try {
      _lastWords = '';
      _isListening = true;
      _lastError = null;

      _audioPath = '${Directory.systemTemp.path}/voice_listen_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        path: _audioPath!,
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        samplingRate: 16000,
      );

      _isRecording = true;
      debugPrint('VoiceSearch: Auto-recording started, waiting for speech...');

      // Record for up to 8 seconds (short grocery queries)
      // Check amplitude to detect silence and stop early
      int elapsed = 0;
      int silentCount = 0;
      bool heardSpeech = false;

      while (_isRecording && elapsed < 16) {
        await Future.delayed(const Duration(milliseconds: 500));
        elapsed++;

        try {
          final amplitude = await _recorder.getAmplitude();
          final db = amplitude.current;
          // Typical speech is -20 to -10 dB, silence is below -40 dB
          if (db > -35) {
            heardSpeech = true;
            silentCount = 0;
          } else if (heardSpeech) {
            silentCount++;
            // 1.5 seconds of silence after speech → stop
            if (silentCount >= 3) {
              debugPrint('VoiceSearch: Silence detected, stopping');
              break;
            }
          }
        } catch (_) {
          // Amplitude not supported on all platforms, just use timeout
        }
      }

      // Stop recording and transcribe
      final path = await _recorder.stop();
      _isRecording = false;
      _isListening = false;

      final audioFile = path ?? _audioPath;
      if (audioFile == null) {
        _lastError = 'No audio recorded';
        return null;
      }

      debugPrint('VoiceSearch: Recorded ${elapsed * 500}ms, transcribing...');
      final transcription = await _transcribeAudio(audioFile);
      _lastWords = transcription ?? '';

      if (_lastWords.isEmpty) {
        _lastError = 'No speech detected. Please try again.';
        return null;
      }

      debugPrint('VoiceSearch: Final text: $_lastWords');
      return _lastWords;
    } catch (e) {
      _lastError = 'Error during voice search: $e';
      debugPrint('VoiceSearch: $_lastError');
      _isListening = false;
      _isRecording = false;
      return null;
    }
  }

  /// Listen with Tamil locale (same as listen — Gemini handles all languages)
  Future<String?> listenTamil() async {
    return listen();
  }

  /// Stop listening/recording
  Future<void> stopListening() async {
    if (_isRecording) {
      try {
        await _recorder.stop();
      } catch (_) {}
    }
    _isRecording = false;
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
          debugPrint('VoiceSearch: AI search timeout');
          return http.Response('{"error": "timeout"}', 408);
        },
      );

      debugPrint('VoiceSearch: AI Search Response: ${aiResponse.statusCode}');

      if (aiResponse.statusCode == 200) {
        final data = json.decode(aiResponse.body);

        if (data['statusCode'] == '0000' && data['data'] != null) {
          final matchedProducts = data['data']['matchedProducts'] ?? [];
          debugPrint('VoiceSearch: Found ${matchedProducts.length} products via AI');
          return matchedProducts;
        }
      }

      // Fallback to regular search
      debugPrint('VoiceSearch: AI search not available, using regular search');
      final searchUrl = Uri.parse(
        '${EnvConfig.fullApiUrl}/shops/$shopId/products/search?query=${Uri.encodeComponent(query)}',
      );

      final searchResponse = await http.get(
        searchUrl,
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('VoiceSearch: Regular search timeout');
          return http.Response('{"error": "timeout"}', 408);
        },
      );

      if (searchResponse.statusCode == 200) {
        final data = json.decode(searchResponse.body);

        if (data['statusCode'] == '0000' && data['data'] != null) {
          final products = data['data'] is List ? data['data'] : [];
          debugPrint('VoiceSearch: Found ${products.length} products via regular search');
          return products;
        }
      }

      debugPrint('VoiceSearch: Both searches failed');
      return [];
    } catch (e) {
      debugPrint('VoiceSearch: Error calling search: $e');
      _lastError = 'Network error: Unable to search products';
      return [];
    }
  }

  /// Voice search: listen + AI search
  Future<List<dynamic>> voiceSearch(int shopId) async {
    debugPrint('VoiceSearch: voiceSearch() started for shop $shopId');
    final query = await listen();
    debugPrint('VoiceSearch: listen() returned: "$query"');

    if (query == null || query.trim().isEmpty) {
      debugPrint('VoiceSearch: No voice input detected');
      _lastError = _lastError ?? 'No voice input detected';
      return [];
    }

    debugPrint('VoiceSearch: calling searchProducts with query: "$query"');
    return await searchProducts(shopId, query);
  }

  bool get isListening => _isListening;
  bool get isRecording => _isRecording;
  String get lastWords => _lastWords;
  String? get lastError => _lastError;

  /// Always available (just needs mic permission)
  bool get isAvailable => true;

  void _cleanupAudioFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }

  void dispose() {
    stopListening();
    _recorder.dispose();
  }
}
