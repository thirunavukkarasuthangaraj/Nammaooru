import 'dart:js' as js;

void showBrowserNotification(String title, String body) {
  try {
    js.context.callMethod('showBrowserNotification', [title, body]);
  } catch (e) {
    print('Browser notification error: $e');
  }
}

void stopNotificationSound() {
  try {
    js.context.callMethod('stopNotificationSound');
  } catch (e) {
    print('Error stopping sound: $e');
  }
}
