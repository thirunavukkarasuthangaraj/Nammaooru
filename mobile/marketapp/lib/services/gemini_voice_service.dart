import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../core/config/env_config.dart';
// dart:io is available as a stub on web — guard actual usage with kIsWeb checks
// ignore: avoid_web_libraries_in_flutter
import 'dart:io';

/// Records audio and sends to Gemini via backend for transcription.
/// On web (Chrome): uses Web Speech API (speech_to_text) instead of file recording.
/// On mobile: records WAV file and sends to backend Gemini for transcription.
class GeminiVoiceService {
  final Record _recorder = Record();
  bool _isRecording = false;
  String? _audioPath;

  // Web-only: STT for Chrome
  final stt.SpeechToText _webStt = stt.SpeechToText();
  String _webTranscribedText = '';
  bool _webSttInitialized = false;

  bool get isRecording => _isRecording;

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    if (kIsWeb) return true; // Web Speech API handles permissions itself
    return await _recorder.hasPermission();
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      if (_isRecording) await stopRecording();

      if (kIsWeb) {
        return await _startWebRecording();
      }

      final hasPerms = await _recorder.hasPermission();
      if (!hasPerms) {
        debugPrint('GeminiVoice: No microphone permission');
        return false;
      }

      // Use system temp directory for audio file — WAV format for max compatibility
      _audioPath = '${Directory.systemTemp.path}/voice_order_${DateTime.now().millisecondsSinceEpoch}.wav';

      // Record as WAV (raw, works on all devices)
      await _recorder.start(
        path: _audioPath!,
        encoder: AudioEncoder.wav,
        samplingRate: 16000,
        numChannels: 1,
      );

      // Verify recording actually started
      final isActive = await _recorder.isRecording();
      debugPrint('GeminiVoice: isRecording check after start: $isActive');

      _isRecording = true;
      debugPrint('GeminiVoice: Recording started → $_audioPath');
      return true;
    } catch (e) {
      debugPrint('GeminiVoice: Failed to start recording: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Web-specific: use speech_to_text (Web Speech API)
  Future<bool> _startWebRecording() async {
    _webTranscribedText = '';
    if (!_webSttInitialized) {
      _webSttInitialized = await _webStt.initialize(
        onError: (e) => debugPrint('GeminiVoice Web STT error: ${e.errorMsg}'),
      );
    }
    if (!_webSttInitialized) {
      debugPrint('GeminiVoice: Web STT not available');
      return false;
    }
    await _webStt.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          _webTranscribedText = result.recognizedWords;
          debugPrint('GeminiVoice Web STT: "${result.recognizedWords}" (final=${result.finalResult})');
        }
      },
      localeId: 'ta-IN',
      listenMode: stt.ListenMode.search,
      partialResults: true,
      cancelOnError: false,
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 10),
    );
    _isRecording = true;
    debugPrint('GeminiVoice: Web STT started');
    return true;
  }

  /// Stop recording and return the audio file path (or web sentinel)
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;
      _isRecording = false;

      if (kIsWeb) {
        if (_webStt.isListening) await _webStt.stop();
        debugPrint('GeminiVoice: Web STT stopped, text="$_webTranscribedText"');
        return _webTranscribedText.isNotEmpty ? '__web__' : null;
      }

      final path = await _recorder.stop();
      debugPrint('GeminiVoice: Recording stopped → $path');
      return path ?? _audioPath;
    } catch (e) {
      debugPrint('GeminiVoice: Failed to stop recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Send audio to backend → Gemini transcription → get product names
  Future<String?> transcribeAudio(String audioPath) async {
    // Web: STT already gave us the text directly — no file to upload
    if (kIsWeb || audioPath == '__web__') {
      debugPrint('GeminiVoice: Web transcription = "$_webTranscribedText"');
      return _webTranscribedText.isNotEmpty ? _webTranscribedText : null;
    }
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        debugPrint('GeminiVoice: Audio file not found: $audioPath');
        return null;
      }

      final fileSize = await file.length();
      debugPrint('GeminiVoice: Audio file size: ${fileSize} bytes (${fileSize ~/ 1024}KB)');

      // Skip if file is too small (likely empty/no speech captured)
      if (fileSize < 3000) {
        debugPrint('GeminiVoice: Audio file too small (${fileSize}B), likely no speech captured');
        return null;
      }

      debugPrint('GeminiVoice: Sending audio (${fileSize ~/ 1024}KB) to backend...');

      final uri = Uri.parse('${EnvConfig.fullApiUrl}/v1/products/search/voice-audio');

      final request = http.MultipartRequest('POST', uri);
      final filename = audioPath.endsWith('.wav') ? 'voice.wav' : 'voice.m4a';
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        audioPath,
        filename: filename,
      ));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('GeminiVoice: Response: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
        // Backend returns {success: true, data: {transcription: "...", provider: "..."}}
        if ((data['success'] == true || data['statusCode'] == '0000') && data['data'] != null) {
          final transcription = data['data']['transcription']?.toString() ?? '';
          final provider = data['data']['provider']?.toString() ?? 'unknown';
          debugPrint('GeminiVoice: Transcription ($provider) = "$transcription"');
          return transcription.isNotEmpty ? transcription : null;
        }
      }

      debugPrint('GeminiVoice: Transcription failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      debugPrint('GeminiVoice: Transcription error: $e');
      return null;
    }
    // NOTE: caller is responsible for cleaning up audioPath
  }

  /// Stop recording and transcribe immediately (cleans up audio file)
  Future<String?> stopAndTranscribe() async {
    final path = await stopRecording();
    if (path == null) return null;
    try {
      return await transcribeAudio(path);
    } finally {
      _cleanupAudioFile(path);
    }
  }

  /// Send audio + options context to Gemini for choice understanding.
  /// Returns structured JSON: {"action":"select","index":N} etc.
  Future<Map<String, dynamic>?> understandChoice(String audioPath, List<Map<String, dynamic>> options) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        debugPrint('GeminiVoice: Audio file not found: $audioPath');
        return null;
      }

      final fileSize = await file.length();
      debugPrint('GeminiVoice: Sending choice audio (${fileSize ~/ 1024}KB) + ${options.length} options to backend...');

      final uri = Uri.parse('${EnvConfig.fullApiUrl}/v1/products/search/voice-choice');

      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        audioPath,
        filename: 'voice_choice.m4a',
      ));

      // Build options JSON
      final optionsJson = json.encode(options.asMap().entries.map((e) => {
        'index': e.key + 1,
        'name': '${e.value['name'] ?? ''} ${e.value['weightDisplay'] ?? ''}'.trim(),
        'price': e.value['price'] ?? '0',
      }).toList());
      request.fields['options'] = optionsJson;

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if ((data['success'] == true || data['statusCode'] == '0000') && data['data'] != null) {
          final result = Map<String, dynamic>.from(data['data']);
          debugPrint('GeminiVoice: Choice result = $result');
          return result;
        }
      }

      debugPrint('GeminiVoice: Choice understanding failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      debugPrint('GeminiVoice: Choice understanding error: $e');
      return null;
    } finally {
      _cleanupAudioFile(audioPath);
    }
  }

  /// Stop recording and understand choice immediately
  Future<Map<String, dynamic>?> stopAndUnderstandChoice(List<Map<String, dynamic>> options) async {
    final path = await stopRecording();
    if (path == null) return null;
    return await understandChoice(path, options);
  }

  void _cleanupAudioFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }

  void dispose() {
    if (_isRecording) {
      _recorder.stop();
    }
    _recorder.dispose();
  }
}
