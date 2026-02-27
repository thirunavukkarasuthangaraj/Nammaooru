import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/env_config.dart';

/// Hold-to-record voice input button — records audio and sends to Gemini
/// for transcription. Much better Tamil recognition than device STT.
class VoiceInputButton extends StatefulWidget {
  final TextEditingController controller;

  const VoiceInputButton({super.key, required this.controller});

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with TickerProviderStateMixin {
  final Record _recorder = Record();
  bool _isRecording = false;
  String? _audioPath;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;

  OverlayEntry? _hintOverlay;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _removeHint();
    _pulseController.dispose();
    _rippleController.dispose();
    if (_isRecording) _recorder.stop();
    _recorder.dispose();
    super.dispose();
  }

  void _showHoldHint() {
    _removeHint();
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final pos = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _hintOverlay = OverlayEntry(
      builder: (_) => Positioned(
        top: pos.dy - 38,
        left: pos.dx + size.width / 2 - 52,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Hold to record',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_hintOverlay!);
    Future.delayed(const Duration(milliseconds: 1500), _removeHint);
  }

  void _removeHint() {
    _hintOverlay?.remove();
    _hintOverlay = null;
  }

  Future<void> _startRecording() async {
    try {
      final hasPerms = await _recorder.hasPermission();
      if (!hasPerms) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission required'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      _audioPath = '${Directory.systemTemp.path}/voice_input_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        path: _audioPath!,
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        samplingRate: 16000,
      );

      if (!mounted) return;
      setState(() => _isRecording = true);
      _pulseController.repeat(reverse: true);
      _rippleController.repeat();
    } catch (e) {
      debugPrint('VoiceInput: Failed to start recording: $e');
      _stopRecording();
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      if (!mounted) return;
      setState(() => _isRecording = false);
      _pulseController.stop();
      _pulseController.reset();
      _rippleController.stop();
      _rippleController.reset();

      final audioPath = path ?? _audioPath;
      if (audioPath == null) return;

      // Send to Gemini for transcription
      final transcription = await _transcribeAudio(audioPath);
      if (transcription != null && transcription.isNotEmpty && mounted) {
        final existing = widget.controller.text;
        widget.controller.text = existing.isNotEmpty && !existing.endsWith(' ')
            ? '$existing $transcription'
            : '$existing$transcription';
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controller.text.length),
        );
      }
    } catch (e) {
      debugPrint('VoiceInput: Error stopping recording: $e');
      if (mounted) {
        setState(() => _isRecording = false);
        _pulseController.stop();
        _pulseController.reset();
        _rippleController.stop();
        _rippleController.reset();
      }
    }
  }

  Future<String?> _transcribeAudio(String audioPath) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) return null;

      final uri = Uri.parse('${EnvConfig.fullApiUrl}/v1/products/search/voice-audio');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath(
        'audio', audioPath, filename: 'voice.m4a',
      ));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['statusCode'] == '0000' && data['data'] != null) {
          return data['data']['transcription']?.toString();
        }
      }
      return null;
    } catch (e) {
      debugPrint('VoiceInput: Transcription error: $e');
      return null;
    } finally {
      try {
        final f = File(audioPath);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showHoldHint,
      onLongPressStart: (_) async {
        HapticFeedback.mediumImpact();
        await _startRecording();
      },
      onLongPressEnd: (_) => _stopRecording(),
      onLongPressCancel: () => _stopRecording(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _rippleAnimation]),
        builder: (context, _) {
          return SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isRecording)
                  Transform.scale(
                    scale: 1.0 + _rippleAnimation.value * 1.8,
                    child: Opacity(
                      opacity: (1.0 - _rippleAnimation.value).clamp(0.0, 1.0),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                Transform.scale(
                  scale: _isRecording ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.red : Colors.transparent,
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      color: _isRecording ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
