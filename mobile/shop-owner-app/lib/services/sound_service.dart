import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Play new order sound
  Future<void> playNewOrderSound() async {
    try {
      // Try to play sound on both web and mobile
      await _audioPlayer.play(AssetSource('sounds/new_order.mp3'));
      print('🔔 New order notification sound played');
    } catch (e) {
      print('Error playing new order sound: $e');
      print('🔔 New order notification (sound failed to play)');
    }
  }

  // Play order cancelled sound
  Future<void> playOrderCancelledSound() async {
    try {
      if (kIsWeb) {
        await _audioPlayer.play(UrlSource('assets/sounds/order_cancelled.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('sounds/order_cancelled.mp3'));
      }
    } catch (e) {
      print('Error playing order cancelled sound: $e');
    }
  }

  // Play payment received sound
  Future<void> playPaymentReceivedSound() async {
    try {
      if (kIsWeb) {
        await _audioPlayer.play(UrlSource('assets/sounds/payment_received.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('sounds/payment_received.mp3'));
      }
    } catch (e) {
      print('Error playing payment received sound: $e');
    }
  }

  // Play success chime
  Future<void> playSuccessSound() async {
    try {
      if (kIsWeb) {
        await _audioPlayer.play(UrlSource('assets/sounds/success_chime.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('sounds/success_chime.mp3'));
      }
    } catch (e) {
      print('Error playing success sound: $e');
    }
  }

  // Play urgent alert
  Future<void> playUrgentAlertSound() async {
    try {
      if (kIsWeb) {
        await _audioPlayer.play(UrlSource('assets/sounds/urgent_alert.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('sounds/urgent_alert.mp3'));
      }
    } catch (e) {
      print('Error playing urgent alert sound: $e');
    }
  }

  // Play message received sound
  Future<void> playMessageSound() async {
    try {
      if (kIsWeb) {
        await _audioPlayer.play(UrlSource('assets/sounds/message_received.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('sounds/message_received.mp3'));
      }
    } catch (e) {
      print('Error playing message sound: $e');
    }
  }

  // Play low stock alert
  Future<void> playLowStockSound() async {
    try {
      if (kIsWeb) {
        await _audioPlayer.play(UrlSource('assets/sounds/low_stock.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('sounds/low_stock.mp3'));
      }
    } catch (e) {
      print('Error playing low stock sound: $e');
    }
  }

  // Stop any currently playing sound
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping sound: $e');
    }
  }

  // Dispose of the audio player
  void dispose() {
    _audioPlayer.dispose();
  }
}
