import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class AudioService {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._internal();

  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  bool _isInitialized = false;
  bool _isMuted = false;
  double _volume = 0.8;

  // Initialize audio service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set audio context for mobile
      await _player.setPlayerMode(PlayerMode.lowLatency);
      await _backgroundPlayer.setPlayerMode(PlayerMode.lowLatency);

      // Load settings
      await _loadSettings();

      _isInitialized = true;
      print('AudioService initialized successfully');
    } catch (e) {
      print('Failed to initialize AudioService: $e');
    }
  }

  // Load audio settings from storage
  Future<void> _loadSettings() async {
    try {
      _volume = StorageService.getDouble('audio_volume', defaultValue: 0.8);
      _isMuted = StorageService.getBool('audio_muted', defaultValue: false);

      await _player.setVolume(_isMuted ? 0.0 : _volume);
      await _backgroundPlayer.setVolume(_isMuted ? 0.0 : _volume * 0.5);
    } catch (e) {
      print('Failed to load audio settings: $e');
    }
  }

  // Save audio settings to storage
  Future<void> _saveSettings() async {
    try {
      await StorageService.saveDouble('audio_volume', _volume);
      await StorageService.saveBool('audio_muted', _isMuted);
    } catch (e) {
      print('Failed to save audio settings: $e');
    }
  }

  // Play notification sound based on type
  Future<void> playNotificationSound(String notificationType) async {
    if (!_isInitialized) await initialize();

    final settings = StorageService.getNotificationSettings();
    if (!settings['soundEnabled']) return;

    final soundFile = _getSoundFileForNotification(notificationType);
    await _playSound(soundFile, withVibration: true);
  }

  // Play specific sound file
  Future<void> _playSound(String soundFile, {bool withVibration = false}) async {
    if (_isMuted) return;

    try {
      // Stop any currently playing sound
      await _player.stop();

      // Play the sound
      await _player.play(AssetSource('sounds/$soundFile'));

      // Add vibration if requested and available
      if (withVibration) {
        await _vibrate();
      }

      print('Playing sound: $soundFile');
    } catch (e) {
      print('Failed to play sound $soundFile: $e');
    }
  }

  // Play background music or ambient sound
  Future<void> playBackgroundSound(String soundFile, {bool loop = true}) async {
    if (!_isInitialized) await initialize();
    if (_isMuted) return;

    try {
      await _backgroundPlayer.stop();
      await _backgroundPlayer.play(
        AssetSource('sounds/$soundFile'),
        mode: loop ? PlayerMode.lowLatency : PlayerMode.mediaPlayer,
      );

      if (loop) {
        await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      }

      print('Playing background sound: $soundFile');
    } catch (e) {
      print('Failed to play background sound $soundFile: $e');
    }
  }

  // Stop background sound
  Future<void> stopBackgroundSound() async {
    try {
      await _backgroundPlayer.stop();
    } catch (e) {
      print('Failed to stop background sound: $e');
    }
  }

  // Play success sound
  Future<void> playSuccessSound() async {
    await _playSound(SoundFiles.successChime);
  }

  // Play error sound
  Future<void> playErrorSound() async {
    await _playSound('error.mp3');
  }

  // Play button tap sound
  Future<void> playButtonTapSound() async {
    await _playSound('button_tap.mp3');
  }

  // Play new order sound with special handling
  Future<void> playNewOrderSound() async {
    await _playSound(SoundFiles.newOrder, withVibration: true);

    // Play a secondary alert after 2 seconds if not acknowledged
    Timer(const Duration(seconds: 2), () async {
      await _playSound('alert_reminder.mp3');
    });
  }

  // Play payment received sound
  Future<void> playPaymentReceivedSound() async {
    await _playSound(SoundFiles.paymentReceived, withVibration: true);
  }

  // Play urgent alert sound
  Future<void> playUrgentAlertSound() async {
    await _playSound(SoundFiles.urgentAlert, withVibration: true);

    // Repeat urgent alerts
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (timer.tick <= 3) { // Play 3 times
        await _playSound(SoundFiles.urgentAlert, withVibration: true);
      } else {
        timer.cancel();
      }
    });
  }

  // Vibrate device
  Future<void> _vibrate() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        final settings = StorageService.getNotificationSettings();
        if (settings['vibrationEnabled']) {
          await Vibration.vibrate(duration: 500, amplitude: 128);
        }
      }
    } catch (e) {
      print('Failed to vibrate: $e');
    }
  }

  // Vibrate with pattern for different notification types
  Future<void> vibrateWithPattern(String notificationType) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) return;

      final settings = StorageService.getNotificationSettings();
      if (!settings['vibrationEnabled']) return;

      List<int> pattern;
      switch (notificationType) {
        case 'new_order':
          pattern = [0, 200, 100, 200, 100, 200]; // Triple pulse
          break;
        case 'urgent_alert':
          pattern = [0, 100, 50, 100, 50, 100, 50, 100]; // Rapid pulses
          break;
        case 'payment_received':
          pattern = [0, 500]; // Single long pulse
          break;
        default:
          pattern = [0, 300]; // Single medium pulse
      }

      await Vibration.vibrate(pattern: pattern);
    } catch (e) {
      print('Failed to vibrate with pattern: $e');
    }
  }

  // Get sound file for notification type
  String _getSoundFileForNotification(String notificationType) {
    switch (notificationType) {
      case 'new_order':
        return SoundFiles.newOrder;
      case 'payment_received':
        return SoundFiles.paymentReceived;
      case 'order_cancelled':
        return SoundFiles.orderCancelled;
      case 'urgent_alert':
      case 'time_alert':
        return SoundFiles.urgentAlert;
      case 'customer_message':
        return SoundFiles.messageReceived;
      case 'low_stock':
        return SoundFiles.lowStock;
      case 'review_received':
        return SoundFiles.successChime;
      default:
        return 'notification.mp3';
    }
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);

    if (!_isMuted) {
      await _player.setVolume(_volume);
      await _backgroundPlayer.setVolume(_volume * 0.5);
    }

    await _saveSettings();
  }

  // Get current volume
  double get volume => _volume;

  // Mute/unmute audio
  Future<void> setMuted(bool muted) async {
    _isMuted = muted;

    await _player.setVolume(_isMuted ? 0.0 : _volume);
    await _backgroundPlayer.setVolume(_isMuted ? 0.0 : _volume * 0.5);

    await _saveSettings();
  }

  // Check if audio is muted
  bool get isMuted => _isMuted;

  // Toggle mute
  Future<void> toggleMute() async {
    await setMuted(!_isMuted);
  }

  // Stop all sounds
  Future<void> stopAllSounds() async {
    try {
      await _player.stop();
      await _backgroundPlayer.stop();
    } catch (e) {
      print('Failed to stop all sounds: $e');
    }
  }

  // Pause all sounds
  Future<void> pauseAllSounds() async {
    try {
      await _player.pause();
      await _backgroundPlayer.pause();
    } catch (e) {
      print('Failed to pause all sounds: $e');
    }
  }

  // Resume all sounds
  Future<void> resumeAllSounds() async {
    try {
      await _player.resume();
      await _backgroundPlayer.resume();
    } catch (e) {
      print('Failed to resume all sounds: $e');
    }
  }

  // Test notification sound
  Future<void> testNotificationSound(String notificationType) async {
    await playNotificationSound(notificationType);
  }

  // Play sound with custom settings
  Future<void> playSoundWithSettings({
    required String soundFile,
    double? volume,
    bool? withVibration,
    bool? loop,
  }) async {
    if (!_isInitialized) await initialize();
    if (_isMuted && volume == null) return;

    try {
      final player = loop == true ? _backgroundPlayer : _player;

      if (volume != null) {
        await player.setVolume(volume);
      }

      await player.stop();
      await player.play(AssetSource('sounds/$soundFile'));

      if (loop == true) {
        await player.setReleaseMode(ReleaseMode.loop);
      }

      if (withVibration == true) {
        await _vibrate();
      }

      print('Playing sound with custom settings: $soundFile');
    } catch (e) {
      print('Failed to play sound with custom settings: $e');
    }
  }

  // Check if sound is currently playing
  bool get isPlaying => _player.state == PlayerState.playing;

  // Check if background sound is playing
  bool get isBackgroundPlaying => _backgroundPlayer.state == PlayerState.playing;

  // Get audio state
  PlayerState get audioState => _player.state;

  // Get background audio state
  PlayerState get backgroundAudioState => _backgroundPlayer.state;

  // Create audio session for calls
  Future<void> createCallSession() async {
    try {
      await _player.setPlayerMode(PlayerMode.mediaPlayer);
      await _player.setAudioContext(
        AudioContext(
          android: const AndroidAudioContext(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.voiceCommunication,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: const IOSAudioContext(
            category: AVAudioSessionCategory.playAndRecord,
            options: [
              AVAudioSessionOptions.defaultToSpeaker,
              AVAudioSessionOptions.allowBluetooth,
            ],
          ),
        ),
      );
    } catch (e) {
      print('Failed to create call session: $e');
    }
  }

  // Release call session
  Future<void> releaseCallSession() async {
    try {
      await _player.setPlayerMode(PlayerMode.lowLatency);
    } catch (e) {
      print('Failed to release call session: $e');
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    try {
      await _player.dispose();
      await _backgroundPlayer.dispose();
    } catch (e) {
      print('Failed to dispose AudioService: $e');
    }
  }
}