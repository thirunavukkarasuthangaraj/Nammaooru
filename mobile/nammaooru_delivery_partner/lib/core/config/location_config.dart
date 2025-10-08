import '../services/location_service.dart';

class LocationConfig {
  // Environment-configurable intervals (in seconds)
  static const int DEFAULT_IDLE_INTERVAL = 300;    // 5 minutes
  static const int DEFAULT_ACTIVE_INTERVAL = 30;   // 30 seconds

  /// Initialize location configuration from environment or defaults
  static void initialize({
    int? idleIntervalSeconds,
    int? activeIntervalSeconds,
  }) {
    // Set custom intervals or use defaults
    final idleInterval = idleIntervalSeconds ?? DEFAULT_IDLE_INTERVAL;
    final activeInterval = activeIntervalSeconds ?? DEFAULT_ACTIVE_INTERVAL;

    LocationService.setTrackingIntervals(
      idleInterval: idleInterval,
      activeInterval: activeInterval,
    );

    print('🔧 Location tracking configured:');
    print('   - Idle mode (no orders): ${idleInterval}s intervals (${(idleInterval/60).round()} minutes)');
    print('   - Active mode (with orders): ${activeInterval}s intervals');
  }

  /// Load configuration from environment variables or config file
  static Map<String, int> loadFromEnvironment() {
    // In a real app, you might load from:
    // - Environment variables
    // - Remote config
    // - Local config file
    // - Firebase Remote Config, etc.

    try {
      // Example: Load from environment (you'll need flutter_dotenv package)
      // final idleInterval = int.tryParse(dotenv.env['LOCATION_IDLE_INTERVAL'] ?? '120') ?? DEFAULT_IDLE_INTERVAL;
      // final activeInterval = int.tryParse(dotenv.env['LOCATION_ACTIVE_INTERVAL'] ?? '30') ?? DEFAULT_ACTIVE_INTERVAL;

      // For now, using defaults
      return {
        'idleInterval': DEFAULT_IDLE_INTERVAL, // 5 minutes
        'activeInterval': DEFAULT_ACTIVE_INTERVAL, // 30 seconds
      };
    } catch (e) {
      print('⚠️ Failed to load location config from environment: $e');
      return {
        'idleInterval': DEFAULT_IDLE_INTERVAL,
        'activeInterval': DEFAULT_ACTIVE_INTERVAL,
      };
    }
  }
}