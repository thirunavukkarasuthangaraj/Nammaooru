// Stub implementation for non-web platforms
void showBrowserNotification(String title, String body) {
  // No-op on non-web platforms
  print('Browser notification (no-op on non-web): $title - $body');
}

void stopNotificationSound() {
  // No-op on non-web platforms
  print('Stop notification sound (no-op on non-web)');
}
