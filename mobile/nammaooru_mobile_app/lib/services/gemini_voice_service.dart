import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart';

/// Records audio and sends to Gemini via backend for transcription.
/// Replaces device STT with Gemini's much better multilingual understanding.
/// Cost: ~$0.0001 per 5-sec clip.
class GeminiVoiceService {
  final Record _recorder = Record();
  bool _isRecording = false;
  String? _audioPath;

  bool get isRecording => _isRecording;

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      if (_isRecording) await stopRecording();

      final hasPerms = await _recorder.hasPermission();
      if (!hasPerms) {
        debugPrint('GeminiVoice: No microphone permission');
        return false;
      }

      // Use system temp directory for audio file
      _audioPath = '${Directory.systemTemp.path}/voice_order_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Record as AAC/M4A (good quality, small size)
      await _recorder.start(
        path: _audioPath!,
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        samplingRate: 16000,
      );

      _isRecording = true;
      debugPrint('GeminiVoice: Recording started → $_audioPath');
      return true;
    } catch (e) {
      debugPrint('GeminiVoice: Failed to start recording: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Stop recording and return the audio file path
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final path = await _recorder.stop();
      _isRecording = false;
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
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        debugPrint('GeminiVoice: Audio file not found: $audioPath');
        return null;
      }

      final fileSize = await file.length();
      debugPrint('GeminiVoice: Sending audio (${fileSize ~/ 1024}KB) to backend...');

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
          debugPrint('GeminiVoice: Transcription = "$transcription"');
          return transcription.isNotEmpty ? transcription : null;
        }
      }

      debugPrint('GeminiVoice: Transcription failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      debugPrint('GeminiVoice: Transcription error: $e');
      return null;
    } finally {
      _cleanupAudioFile(audioPath);
    }
  }

  /// Stop recording and transcribe immediately
  Future<String?> stopAndTranscribe() async {
    final path = await stopRecording();
    if (path == null) return null;
    return await transcribeAudio(path);
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
        if (data['statusCode'] == '0000' && data['data'] != null) {
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
