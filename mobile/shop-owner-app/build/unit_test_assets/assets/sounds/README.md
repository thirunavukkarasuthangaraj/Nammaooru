# Sound Assets for NammaOoru Shop Owner App

This directory contains all the sound files used by the app for notifications and audio feedback.

## Sound Files Required

The following sound files need to be added to this directory:

### Notification Sounds
- `new_order.mp3` - Exciting bell sound for new orders (3 seconds)
- `payment_received.mp3` - Cash register sound for payments (2 seconds)
- `order_cancelled.mp3` - Gentle notification sound (2 seconds)
- `urgent_alert.mp3` - Attention-grabbing alarm (4 seconds)
- `success_chime.mp3` - Success confirmation sound (2 seconds)
- `message_received.mp3` - Chat message notification (1 second)
- `low_stock.mp3` - Warning sound for inventory alerts (3 seconds)

### UI Sounds
- `button_tap.mp3` - Subtle button tap feedback (0.5 seconds)
- `error.mp3` - Error notification sound (2 seconds)
- `notification.mp3` - Default notification sound (2 seconds)

### Additional Sounds
- `alert_reminder.mp3` - Secondary alert for unacknowledged notifications (2 seconds)

## Audio Specifications

All sound files should meet the following specifications:

- **Format**: MP3 or AAC
- **Sample Rate**: 44.1 kHz
- **Bit Rate**: 128 kbps or higher
- **Channels**: Mono or Stereo
- **Volume**: Normalized to -6dB to prevent clipping

## Usage in App

These sounds are used by the `AudioService` class and triggered by:

1. **New Order Notifications**: `new_order.mp3`
2. **Payment Confirmations**: `payment_received.mp3`
3. **Order Cancellations**: `order_cancelled.mp3`
4. **Urgent Alerts**: `urgent_alert.mp3`
5. **Success Actions**: `success_chime.mp3`
6. **Messages**: `message_received.mp3`
7. **Inventory Warnings**: `low_stock.mp3`

## Implementation Notes

- Sounds are played using the `audioplayers` package
- Volume can be controlled through app settings
- Sounds can be muted individually by notification type
- Background music capability is available for ambient sounds
- Vibration patterns accompany important notification sounds

## Adding New Sounds

To add new sound files:

1. Place the MP3 file in this directory
2. Update `SoundFiles` class in `lib/utils/constants.dart`
3. Add the sound mapping in `AudioService._getSoundFileForNotification()`
4. Update the `pubspec.yaml` assets section if needed

## License

Sound files should be royalty-free or properly licensed for commercial use.