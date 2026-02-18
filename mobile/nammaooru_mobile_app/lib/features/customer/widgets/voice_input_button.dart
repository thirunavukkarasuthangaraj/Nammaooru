import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceInputButton extends StatefulWidget {
  final TextEditingController controller;

  const VoiceInputButton({super.key, required this.controller});

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (_speech.isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            if (mounted && _isListening) {
              setState(() {
                _isListening = false;
              });
              _pulseController.stop();
              _pulseController.reset();
            }
          }
        },
        onError: (error) {
          debugPrint('Voice input error: ${error.errorMsg}');
          if (mounted) {
            setState(() {
              _isListening = false;
            });
            _pulseController.stop();
            _pulseController.reset();
          }
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

      setState(() {
        _isListening = true;
      });
      _pulseController.repeat(reverse: true);

      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            final existing = widget.controller.text;
            if (existing.isNotEmpty && !existing.endsWith(' ')) {
              widget.controller.text = '$existing ${result.recognizedWords}';
            } else {
              widget.controller.text = '$existing${result.recognizedWords}';
            }
            widget.controller.selection = TextSelection.fromPosition(
              TextPosition(offset: widget.controller.text.length),
            );
          }
        },
        localeId: 'ta-IN',
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: false,
        partialResults: false,
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(seconds: 30),
      );
    } catch (e) {
      debugPrint('Voice input error: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
        });
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isListening ? _pulseAnimation.value : 1.0,
          child: IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : Colors.grey[600],
            ),
            onPressed: _toggleListening,
            tooltip: _isListening ? 'Stop' : 'Speak in Tamil',
          ),
        );
      },
    );
  }
}
