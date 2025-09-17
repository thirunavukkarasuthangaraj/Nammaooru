import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OTPInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onChanged;
  final Function(String)? onCompleted;
  final int length;
  final bool autoFocus;

  const OTPInputWidget({
    Key? key,
    required this.controller,
    this.onChanged,
    this.onCompleted,
    this.length = 6,
    this.autoFocus = true,
  }) : super(key: key);

  @override
  State<OTPInputWidget> createState() => _OTPInputWidgetState();
}

class _OTPInputWidgetState extends State<OTPInputWidget> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _controllers = List.generate(widget.length, (index) => TextEditingController());

    // Auto focus the first field
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[0].requestFocus();
      });
    }

    // Listen to controller changes to update individual controllers
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onControllerChanged() {
    final text = widget.controller.text;
    for (int i = 0; i < widget.length; i++) {
      if (i < text.length) {
        _controllers[i].text = text[i];
      } else {
        _controllers[i].text = '';
      }
    }
  }

  void _onFieldChanged(int index, String value) {
    if (value.isNotEmpty && value.length == 1) {
      // Move to next field
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    // Update main controller
    String otpValue = '';
    for (var controller in _controllers) {
      otpValue += controller.text;
    }

    widget.controller.text = otpValue;

    if (widget.onChanged != null) {
      widget.onChanged!(otpValue);
    }

    if (otpValue.length == widget.length && widget.onCompleted != null) {
      widget.onCompleted!(otpValue);
    }
  }

  void _onFieldSubmitted(int index) {
    if (index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _onFieldTap(int index) {
    // Clear current field and all subsequent fields
    for (int i = index; i < widget.length; i++) {
      _controllers[i].clear();
    }
    _updateMainController();
  }

  void _updateMainController() {
    String otpValue = '';
    for (var controller in _controllers) {
      otpValue += controller.text;
    }
    widget.controller.text = otpValue;

    if (widget.onChanged != null) {
      widget.onChanged!(otpValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          widget.length,
          (index) => Container(
            width: 45,
            height: 55,
            decoration: BoxDecoration(
              border: Border.all(
                color: _focusNodes[index].hasFocus
                    ? Theme.of(context).primaryColor
                    : Colors.grey[400]!,
                width: _focusNodes[index].hasFocus ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              keyboardType: TextInputType.number,
              maxLength: 1,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(0),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) => _onFieldChanged(index, value),
              onSubmitted: (_) => _onFieldSubmitted(index),
              onTap: () => _onFieldTap(index),
            ),
          ),
        ),
      ),
    );
  }
}