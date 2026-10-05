import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

import '../../core/utils/image_url_helper.dart';

/// A promotion video playing inside the home "SPECIAL OFFERS" carousel.
///
/// Behaves like a banner, not like a media player: it autoplays muted and
/// loops, so it never hijacks whatever the customer is already listening to,
/// and a tap opens the offer rather than toggling playback (the small speaker
/// button is the only control, and it swallows the tap so it doesn't navigate).
///
/// Only ever handed an admin-approved video - the backend omits videoUrl
/// entirely until a super admin approves it.
class PromoVideoBanner extends StatefulWidget {
  const PromoVideoBanner({
    super.key,
    required this.videoUrl,
    required this.fallback,
    this.posterUrl,
    this.isActive = true,
    this.onTap,
    this.badge,
  });

  /// Relative (/uploads/...) or absolute URL of the video.
  final String videoUrl;

  /// Shown if the video can't be loaded or played at all. A banner that fails
  /// must still sell the offer, so this is the normal image/text card.
  final Widget fallback;

  /// Still image to hold the slot until the first frame decodes.
  final String? posterUrl;

  /// False while this slide is off-screen in the carousel - playback is paused
  /// so a deck of promos doesn't decode several videos at once.
  final bool isActive;

  final VoidCallback? onTap;

  /// Optional label drawn over the video (e.g. the shop name / discount).
  final Widget? badge;

  @override
  State<PromoVideoBanner> createState() => _PromoVideoBannerState();
}

class _PromoVideoBannerState extends State<PromoVideoBanner>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialise();
  }

  Future<void> _initialise() async {
    final resolved = ImageUrlHelper.getFullImageUrl(widget.videoUrl);
    final uri = Uri.tryParse(resolved);
    if (uri == null) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) {
        // The slide was disposed while the network fetch was still in flight;
        // without this the controller leaks and keeps buffering.
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);
      setState(() => _ready = true);
      if (widget.isActive) {
        await controller.play();
      }
    } catch (e) {
      debugPrint('Promo video failed to load ($resolved): $e');
      if (mounted) {
        setState(() => _failed = true);
      }
      await controller.dispose();
      _controller = null;
    }
  }

  @override
  void didUpdateWidget(covariant PromoVideoBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _ready = false;
      _failed = false;
      _initialise();
      return;
    }

    if (oldWidget.isActive != widget.isActive) {
      _syncPlayback();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Keep a backgrounded app from holding a decoder open (and from burning
    // mobile data looping a banner nobody is looking at).
    if (state == AppLifecycleState.resumed) {
      _syncPlayback();
    } else {
      _controller?.pause();
    }
  }

  void _syncPlayback() {
    final controller = _controller;
    if (controller == null || !_ready) return;
    if (widget.isActive) {
      controller.play();
    } else {
      controller.pause();
      // Restart from the top next time, so a customer swiping back to this
      // slide sees the promo from the beginning rather than mid-sentence.
      controller.seekTo(Duration.zero);
    }
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    setState(() => _muted = !_muted);
    controller.setVolume(_muted ? 0 : 1);
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    controller?.pause();
    controller?.dispose();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.fallback;

    final controller = _controller;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_ready && controller != null)
                // The video's own aspect ratio rarely matches the banner slot,
                // so scale it to cover and clip the overflow - letterbox bars
                // inside a carousel card look broken.
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                )
              else
                _buildPoster(),

              if (widget.badge != null)
                Positioned(left: 12, top: 12, child: widget.badge!),

              Positioned(
                right: 10,
                bottom: 10,
                child: GestureDetector(
                  // Without this the tap bubbles up and opens the offer
                  // instead of changing the sound.
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoster() {
    final poster = widget.posterUrl;
    if (poster != null && poster.trim().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: ImageUrlHelper.getFullImageUrl(poster),
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, __) => _buildLoadingSurface(),
        errorWidget: (_, __, ___) => _buildLoadingSurface(),
      );
    }
    return _buildLoadingSurface();
  }

  Widget _buildLoadingSurface() {
    return Container(
      color: Colors.black12,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
      ),
    );
  }
}
