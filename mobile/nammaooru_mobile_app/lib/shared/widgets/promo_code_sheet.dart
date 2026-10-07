import 'dart:async';
import 'dart:ui' show FontFeature, PathMetric;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/theme/village_theme.dart';
import '../../core/utils/image_url_helper.dart';

/// Bottom sheet that shows a promotion in full: banner, offer, the code in a
/// dashed ticket box and a one-tap copy button. Opened when a customer taps a
/// promo banner on Home. Every field is optional - the sheet lays out only
/// what it is given, so a bare code with a title still looks finished.
class PromoCodeSheet extends StatefulWidget {
  final String? title;
  final String? shopName;
  final String? description;
  /// Already formatted, e.g. "20% OFF" / "₹50 OFF" / "FREE DELIVERY".
  final String? discountLabel;
  final String? code;
  final String? imageUrl;
  final double? minimumOrderAmount;
  final double? maximumDiscountAmount;
  final DateTime? validUntil;
  final bool firstTimeOnly;
  final String? terms;
  /// When set, a secondary "Visit shop" button is shown. The sheet pops itself
  /// before invoking this, so the caller can push with its own context.
  final VoidCallback? onVisitShop;

  const PromoCodeSheet({
    super.key,
    this.title,
    this.shopName,
    this.description,
    this.discountLabel,
    this.code,
    this.imageUrl,
    this.minimumOrderAmount,
    this.maximumDiscountAmount,
    this.validUntil,
    this.firstTimeOnly = false,
    this.terms,
    this.onVisitShop,
  });

  /// Convenience wrapper around [showModalBottomSheet] with the sheet's own
  /// chrome (transparent host so the rounded top shows against the scrim,
  /// scroll-controlled so a tall promo can grow past half the screen).
  static Future<void> show(
    BuildContext context, {
    String? title,
    String? shopName,
    String? description,
    String? discountLabel,
    String? code,
    String? imageUrl,
    double? minimumOrderAmount,
    double? maximumDiscountAmount,
    DateTime? validUntil,
    bool firstTimeOnly = false,
    String? terms,
    VoidCallback? onVisitShop,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PromoCodeSheet(
        title: title,
        shopName: shopName,
        description: description,
        discountLabel: discountLabel,
        code: code,
        imageUrl: imageUrl,
        minimumOrderAmount: minimumOrderAmount,
        maximumDiscountAmount: maximumDiscountAmount,
        validUntil: validUntil,
        firstTimeOnly: firstTimeOnly,
        terms: terms,
        onVisitShop: onVisitShop,
      ),
    );
  }

  @override
  State<PromoCodeSheet> createState() => _PromoCodeSheetState();
}

class _PromoCodeSheetState extends State<PromoCodeSheet> {
  static const _ink = Color(0xFF212121);
  static const _green = VillageTheme.primaryGreen;
  static const _amber = Color(0xFFB36B00);

  bool _copied = false;
  bool _termsOpen = false;
  Timer? _copiedTimer;

  String get _code => (widget.code ?? '').trim();
  bool get _hasCode => _code.isNotEmpty;
  bool get _hasImage => (widget.imageUrl ?? '').trim().isNotEmpty;

  String? _clean(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    if (!_hasCode) return;
    await Clipboard.setData(ClipboardData(text: _code));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.88;
    final bottomInset = media.viewPadding.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dragHandle(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 16),
                  _badges(),
                  _titleBlock(),
                  if (_hasCode) ...[
                    const SizedBox(height: 18),
                    _codeTicket(),
                  ],
                  ..._detailLines(),
                  if (_clean(widget.terms) != null) ...[
                    const SizedBox(height: 8),
                    _termsSection(),
                  ],
                ],
              ),
            ),
          ),
          _actions(bottomInset),
        ],
      ),
    );
  }

  Widget _dragHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Banner image when the promo has one; a soft green illustration otherwise
  /// (and when the image fails to load). Never plays video - the carousel
  /// already did that, the sheet is for reading the code.
  Widget _header() {
    const radius = BorderRadius.all(Radius.circular(16));
    if (!_hasImage) {
      return ClipRRect(borderRadius: radius, child: _fallbackBanner());
    }
    return ClipRRect(
      borderRadius: radius,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: CachedNetworkImage(
          imageUrl: ImageUrlHelper.getFullImageUrl(widget.imageUrl),
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (_, __) => Container(
            color: _green.withValues(alpha: 0.08),
            alignment: Alignment.center,
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _green.withValues(alpha: 0.5),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => _fallbackBanner(),
        ),
      ),
    );
  }

  Widget _fallbackBanner() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(gradient: VillageTheme.primaryGradient),
      child: Stack(
        children: [
          Positioned(right: -24, top: -24, child: _circle(110)),
          Positioned(right: 40, bottom: -36, child: _circle(90)),
          Positioned(left: -20, bottom: -30, child: _circle(80)),
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_offer_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.12),
      ),
    );
  }

  /// Discount pill (+ "First order only" tag). Nothing if neither applies.
  Widget _badges() {
    final discount = _clean(widget.discountLabel);
    final chips = <Widget>[];
    if (discount != null) {
      chips.add(_pill(
        discount.toUpperCase(),
        background: _green,
        foreground: Colors.white,
        icon: Icons.sell_rounded,
      ));
    }
    if (widget.firstTimeOnly) {
      chips.add(_pill(
        'First order only',
        background: VillageTheme.warmYellow.withValues(alpha: 0.15),
        foreground: _amber,
        icon: Icons.star_rounded,
      ));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _pill(
    String text, {
    required Color background,
    required Color foreground,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(VillageTheme.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleBlock() {
    final title = _clean(widget.title) ?? 'Special Offer';
    final shop = _clean(widget.shopName);
    final description = _clean(widget.description);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: _ink,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              shop != null ? Icons.storefront_rounded : Icons.public_rounded,
              size: 15,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                shop ?? 'Platform offer • valid at all shops',
                style: TextStyle(fontSize: 13.5, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }

  /// The code, ticket-style: dashed green border on a faint green fill, with
  /// a copy affordance that flips to a tick once copied. Tapping anywhere on
  /// the ticket copies too.
  Widget _codeTicket() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROMO CODE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _copy,
            borderRadius: BorderRadius.circular(14),
            child: CustomPaint(
              painter: const _DashedBorderPainter(
                color: _green,
                radius: 14,
                strokeWidth: 1.6,
                dash: 7,
                gap: 5,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _code,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _green,
                            letterSpacing: 2.5,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _copied ? _copiedTag() : _copyIcon(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter this code at checkout to apply the offer.',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _copiedTag() {
    return Container(
      key: const ValueKey('copied'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 16, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Copied',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _copyIcon() {
    return Container(
      key: const ValueKey('copy'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _green.withValues(alpha: 0.35)),
      ),
      child: const Icon(Icons.copy_rounded, size: 18, color: _green),
    );
  }

  /// Muted meta lines: validity, minimum order, discount cap. Each only when
  /// the data exists.
  List<Widget> _detailLines() {
    final lines = <Widget>[];

    final until = widget.validUntil;
    if (until != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final day = DateTime(until.year, until.month, until.day);
      final diff = day.difference(today).inDays;
      String text;
      Color? color;
      if (diff < 0) {
        text = 'Expired on ${DateFormat('dd MMM yyyy').format(until)}';
        color = VillageTheme.errorRed;
      } else if (diff == 0) {
        text = 'Expires today';
        color = _amber;
      } else if (diff <= 3) {
        text = 'Valid till ${DateFormat('dd MMM').format(until)} '
            '• $diff day${diff == 1 ? '' : 's'} left';
        color = _amber;
      } else {
        text = 'Valid till ${DateFormat('dd MMM yyyy').format(until)}';
      }
      lines.add(_detailLine(Icons.schedule_rounded, text, color: color));
    }

    final minOrder = widget.minimumOrderAmount;
    if (minOrder != null && minOrder > 0) {
      lines.add(_detailLine(
        Icons.shopping_bag_outlined,
        'Minimum order ₹${minOrder.toStringAsFixed(0)}',
      ));
    }

    final cap = widget.maximumDiscountAmount;
    if (cap != null && cap > 0) {
      lines.add(_detailLine(
        Icons.savings_outlined,
        'Save up to ₹${cap.toStringAsFixed(0)}',
      ));
    }

    if (lines.isEmpty) return const [];
    return [
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: VillageTheme.lightBackground,
          borderRadius: BorderRadius.circular(VillageTheme.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < lines.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              lines[i],
            ],
          ],
        ),
      ),
    ];
  }

  Widget _detailLine(IconData icon, String text, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color ?? Colors.grey[700],
              fontWeight: color != null ? FontWeight.w600 : FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _termsSection() {
    final terms = _clean(widget.terms)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _termsOpen = !_termsOpen),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(
                  'Terms & conditions',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _termsOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: _termsOpen
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              terms,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Fixed footer: one full-width primary action (copy, or close when there
  /// is no code) and, for shop promos, a secondary "Visit shop".
  Widget _actions(double bottomInset) {
    final String primaryLabel;
    final IconData primaryIcon;
    if (!_hasCode) {
      primaryLabel = 'Close';
      primaryIcon = Icons.close_rounded;
    } else if (_copied) {
      primaryLabel = 'Copied!';
      primaryIcon = Icons.check_rounded;
    } else {
      primaryLabel = 'Copy code';
      primaryIcon = Icons.copy_rounded;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _hasCode ? _copy : () => Navigator.of(context).pop(),
              icon: Icon(primaryIcon, size: 20),
              label: Text(primaryLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: _copied ? const Color(0xFF2E7D32) : _green,
                foregroundColor: Colors.white,
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (widget.onVisitShop != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onVisitShop!();
                },
                icon: const Icon(Icons.storefront_rounded, size: 20),
                label: const Text('Visit shop'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _green,
                  side: BorderSide(color: _green.withValues(alpha: 0.6), width: 1.4),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Draws a dashed rounded-rectangle outline around its child's bounds.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dash,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final inset = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - inset * 2,
        size.height - inset * 2,
      ),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dash != dash ||
      old.gap != gap;
}
