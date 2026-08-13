import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Tap-to-start / tap-to-stop voice input button.
/// Shows "Tap to speak" hint for first-time users.
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
  Timer? _listenTimeout;

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
    _listenTimeout?.cancel();
    _removeHint();
    _pulseController.dispose();
    _rippleController.dispose();
    if (_speech.isListening) _speech.stop();
    super.dispose();
  }

  void _showOverlayHint(String message, {Color color = Colors.black87, int durationMs = 2000}) {
    _removeHint();
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final pos = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _hintOverlay = OverlayEntry(
      builder: (_) => Positioned(
        top: pos.dy - 42,
        left: pos.dx + size.width / 2 - 70,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  color == Colors.red.shade700 ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 5),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(_hintOverlay!);
    if (durationMs > 0) {
      Future.delayed(Duration(milliseconds: durationMs), _removeHint);
    }
  }

  void _removeHint() {
    _hintOverlay?.remove();
    _hintOverlay = null;
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    HapticFeedback.mediumImpact();

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

      // Show "tap to stop" hint while recording
      _showOverlayHint('கேட்கிறது... நிறுத்த தட்டவும்', color: Colors.red.shade700, durationMs: 2500);

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
        listenFor: const Duration(seconds: 15),
      );

      // Watchdog: some devices never fire the 'done' status callback,
      // leaving the button red forever — force-stop past the cap.
      _listenTimeout?.cancel();
      _listenTimeout = Timer(const Duration(seconds: 17), () {
        if (_isListening) _stopListening();
      });
    } catch (e) {
      debugPrint('Voice input error: $e');
      _stopListening();
    }
  }

  Future<void> _stopListening() async {
    _listenTimeout?.cancel();
    if (!_isListening) return; // guard: prevent double-stop
    if (!mounted) return;
    // Update UI immediately — don't wait for _speech.stop()
    setState(() => _isListening = false);
    _pulseController.stop();
    _pulseController.reset();
    _rippleController.stop();
    _rippleController.reset();
    _removeHint();
    await _speech.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _isListening ? 'நிறுத்த தட்டவும் • Tap to stop' : 'குரல் உள்ளீடு • Tap to speak',
      preferBelow: false,
      child: GestureDetector(
        onTap: _toggleListening,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseAnimation, _rippleAnimation]),
          builder: (context, _) {
            return SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ripple ring when recording
                  if (_isListening)
                    Transform.scale(
                      scale: 1.0 + _rippleAnimation.value * 1.8,
                      child: Opacity(
                        opacity: (1.0 - _rippleAnimation.value).clamp(0.0, 1.0),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),

                  // Mic icon button
                  Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? Colors.red
                            : Colors.green.shade50,
                        border: Border.all(
                          color: _isListening
                              ? Colors.red.shade700
                              : Colors.green.shade300,
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.white : Colors.green.shade700,
                        size: 18,
                      ),
                    ),
                  ),

                  // "LIVE" dot badge when recording
                  if (_isListening)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
