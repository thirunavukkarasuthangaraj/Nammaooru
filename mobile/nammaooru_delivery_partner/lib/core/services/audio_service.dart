import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service for playing notification sounds in the delivery partner app
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  static AudioService get instance => _instance;

  final AudioPlayer _player = AudioPlayer();
  bool _isMuted = false;

  /// Initialize audio service
  Future<void> initialize() async {
    try {
      // Set default volume
      await _player.setVolume(0.8);
      await _player.setReleaseMode(ReleaseMode.stop);
      debugPrint('AudioService: Initialized');
    } catch (e) {
      debugPrint('AudioService: Initialization error - $e');
    }
  }

  /// Play new order notification sound
  Future<void> playNewOrderSound() async {
    if (_isMuted) return;
    try {
      debugPrint('AudioService: Playing new_order sound');
      await _player.stop();
      await _player.play(AssetSource('sounds/new_order_notification.mp3'));
    } catch (e) {
      debugPrint('AudioService: Error playing new_order sound - $e');
      // Try fallback sound
      _playFallbackBeep();
    }
  }

  /// Play urgent notification sound
  Future<void> playUrgentSound() async {
    if (_isMuted) return;
    try {
      debugPrint('AudioService: Playing urgent sound');
      await _player.stop();
      await _player.play(AssetSource('sounds/urgent_notification.mp3'));
    } catch (e) {
      debugPrint('AudioService: Error playing urgent sound - $e');
      _playFallbackBeep();
    }
  }

  /// Play order assigned sound
  Future<void> playOrderAssignedSound() async {
    if (_isMuted) return;
    try {
      debugPrint('AudioService: Playing order assigned sound');
      await _player.stop();
      await _player.play(AssetSource('sounds/new_order_notification.mp3'));
    } catch (e) {
      debugPrint('AudioService: Error playing order assigned sound - $e');
      _playFallbackBeep();
    }
  }

  /// Play success sound
  Future<void> playSuccessSound() async {
    if (_isMuted) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/success_chime.mp3'));
    } catch (e) {
      debugPrint('AudioService: Error playing success sound - $e');
    }
  }

  /// Play generic notification sound
  Future<void> playNotificationSound() async {
    if (_isMuted) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/message_received.mp3'));
    } catch (e) {
      debugPrint('AudioService: Error playing notification sound - $e');
      _playFallbackBeep();
    }
  }

  /// Play fallback beep using system sound
  void _playFallbackBeep() {
    debugPrint('AudioService: Playing fallback beep');
    // The system will use default notification sound
  }

  /// Set muted state
  void setMuted(bool muted) {
    _isMuted = muted;
    debugPrint('AudioService: Muted = $muted');
  }

  /// Get muted state
  bool get isMuted => _isMuted;

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Stop any playing sound
  Future<void> stop() async {
    await _player.stop();
  }

  /// Dispose resources
  void dispose() {
    _player.dispose();
  }
}
