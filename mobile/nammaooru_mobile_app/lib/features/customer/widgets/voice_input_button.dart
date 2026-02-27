import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/gemini_voice_service.dart';

/// Hold-to-record voice input button — uses GeminiVoiceService for recording
/// and Gemini backend for transcription. Much better Tamil recognition.
class VoiceInputButton extends StatefulWidget {
  final TextEditingController controller;

  const VoiceInputButton({super.key, required this.controller});

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with TickerProviderStateMixin {
  final GeminiVoiceService _gemini = GeminiVoiceService();
  bool _isRecording = false;
  bool _isTranscribing = false;

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
    _gemini.dispose();
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
    final started = await _gemini.startRecording();
    if (!started) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isRecording = true);
    _pulseController.repeat(reverse: true);
    _rippleController.repeat();
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    // Stop animations immediately
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isTranscribing = true;
      });
    }
    _pulseController.stop();
    _pulseController.reset();
    _rippleController.stop();
    _rippleController.reset();

    // Transcribe via Gemini
    final text = await _gemini.stopAndTranscribe();

    if (mounted) {
      setState(() => _isTranscribing = false);
    }

    if (text != null && text.isNotEmpty && mounted) {
      final existing = widget.controller.text;
      widget.controller.text = existing.isNotEmpty && !existing.endsWith(' ')
          ? '$existing $text'
          : '$existing$text';
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.controller.text.length),
      );
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
      onLongPressCancel: () {
        if (_isRecording) {
          _gemini.stopRecording();
          if (mounted) setState(() => _isRecording = false);
          _pulseController.stop();
          _pulseController.reset();
          _rippleController.stop();
          _rippleController.reset();
        }
      },
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
                      color: _isRecording
                          ? Colors.red
                          : _isTranscribing
                              ? Colors.orange
                              : Colors.transparent,
                    ),
                    child: _isTranscribing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
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
