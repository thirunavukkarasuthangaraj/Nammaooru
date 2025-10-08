// Conditional export - use mobile version on mobile, web stub on web
export 'firebase_notification_service_mobile.dart' if (dart.library.html) 'firebase_notification_service_web.dart';
