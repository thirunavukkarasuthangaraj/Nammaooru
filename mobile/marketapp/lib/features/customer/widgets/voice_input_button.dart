import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Hold-to-record voice input button — uses device STT.
/// Tamil text gets sent to Gemini AI search on backend which corrects errors.
class VoiceInputButton extends StatefulWidget {
  final TextEditingController controller;

  const VoiceInputButton({super.key, required this.controller});

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

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
    if (_speech.isListening) _speech.stop();
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

  Future<void> _startListening() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if ((status == 'notListening' || status == 'done') &&
              mounted &&
              _isListening) {
            _stopListening();
          }
        },
        onError: (error) {
          debugPrint('Voice input error: ${error.errorMsg}');
          _stopListening();
        },
      );

      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition not available'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      setState(() => _isListening = true);
      _pulseController.repeat(reverse: true);
      _rippleController.repeat();

      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            final existing = widget.controller.text;
            widget.controller.text = existing.isNotEmpty && !existing.endsWith(' ')
                ? '$existing ${result.recognizedWords}'
                : '$existing${result.recognizedWords}';
            widget.controller.selection = TextSelection.fromPosition(
              TextPosition(offset: widget.controller.text.length),
            );
          }
        },
        localeId: 'ta-IN',
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: false,
          partialResults: false,
        ),
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(seconds: 30),
      );
    } catch (e) {
      debugPrint('Voice input error: $e');
      _stopListening();
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (!mounted) return;
    setState(() => _isListening = false);
    _pulseController.stop();
    _pulseController.reset();
    _rippleController.stop();
    _rippleController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showHoldHint,
      onLongPressStart: (_) async {
        HapticFeedback.mediumImpact();
        await _startListening();
      },
      onLongPressEnd: (_) => _stopListening(),
      onLongPressCancel: () => _stopListening(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _rippleAnimation]),
        builder: (context, _) {
          return SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isListening)
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
                  scale: _isListening ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? Colors.red
                          : Colors.transparent,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.white : Colors.grey[600],
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
