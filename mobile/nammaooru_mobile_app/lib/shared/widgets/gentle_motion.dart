import 'package:flutter/material.dart';

/// Brief perspective entrance. Respects the device's reduced-motion setting.
class GentleEntrance extends StatelessWidget {
  final Widget child;
  const GentleEntrance({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (_, value, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY((1 - value) * -0.35)
          ..translate(0.0, (1 - value) * 8),
        child: Opacity(opacity: value, child: child),
      ),
    );
  }
}

/// Adds press depth without replacing the child's tap or keyboard actions.
class DepthPress extends StatefulWidget {
  final Widget child;
  const DepthPress({super.key, required this.child});

  @override
  State<DepthPress> createState() => _DepthPressState();
}

class _DepthPressState extends State<DepthPress> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _pressed && !reduced ? 1 : 0),
        duration: reduced ? Duration.zero : const Duration(milliseconds: 130),
        child: widget.child,
        builder: (_, value, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(value * 0.045)
            ..scale(1 - value * 0.025),
          child: child,
        ),
      ),
    );
  }
}

class SuccessPop extends StatelessWidget {
  final Color color;
  final double size;
  const SuccessPop({super.key, required this.color, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.check_circle, color: color, size: size);
    if (MediaQuery.disableAnimationsOf(context)) return icon;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.65, end: 1),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutBack,
      child: icon,
      builder: (_, value, child) => Transform.scale(scale: value, child: child),
    );
  }
}
