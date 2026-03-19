import 'package:flutter/material.dart';
import '../../features/customer/services/feature_config_service.dart';

/// Shared provider that drives ALL dynamic visibility in the customer app.
///
/// Two API calls are made on startup:
///  1. /feature-config/visible  → service grid items (location-aware, only active)
///  2. /feature-config/app-config → nav + section items (active + inactive, global)
///
/// Feature name conventions:
///   nav_cart / nav_orders / nav_profile  → bottom navigation bar items
///   section_deliver_to                   → "Deliver To" location bar on dashboard
///   section_featured_shops               → Featured Shops section
///   section_recent_orders                → Recent Orders section
///   (anything else)                      → service grid tile (Grocery, Food, etc.)
///
/// Visibility rule:
///   - Fail-open: if no app-config rows exist in DB → show everything
///   - If rows exist: isActive=true → show, isActive=false → hide
class FeatureConfigProvider extends ChangeNotifier {
  final FeatureConfigService _service = FeatureConfigService();

  // Service grid features from /visible endpoint (already filtered to active only)
  List<Map<String, dynamic>> _serviceFeatures = [];

  // Map of featureName → isActive from /app-config (nav_ and section_ items)
  Map<String, bool> _appConfig = {};
  bool _appConfigLoaded = false;

  bool _serviceLoaded = false;

  bool get isLoaded => _serviceLoaded && _appConfigLoaded;

  /// Service grid tiles (Grocery, Food, Labours, etc.) — already active-only
  List<Map<String, dynamic>> get serviceFeatures => _serviceFeatures;

  /// Whether a named section or nav item should be shown.
  ///
  /// [key] examples: 'nav_cart', 'section_deliver_to', 'section_featured_shops'
  /// Home nav item is never passed here — it is always shown by the shell.
  bool isVisible(String key) {
    // While loading, show everything (avoid flash-hide on startup)
    if (!_appConfigLoaded) return true;

    // Fail-open: if admin hasn't configured ANY app-config rows → show everything
    if (_appConfig.isEmpty) return true;

    // If this specific key isn't in the config → show (not yet managed by admin)
    if (!_appConfig.containsKey(key)) return true;

    // Respect admin's setting
    return _appConfig[key] == true;
  }

  /// Load service grid features (location-aware). Called by dashboard after GPS fix.
  Future<void> loadServiceFeatures(double lat, double lng) async {
    try {
      final features = await _service.getVisibleFeatures(lat, lng);
      _serviceFeatures = features
          .where((f) => !f['featureName'].toString().startsWith('nav_') &&
                        !f['featureName'].toString().startsWith('section_'))
          .toList();
      _serviceLoaded = true;
      notifyListeners();
    } catch (_) {
      _serviceLoaded = true;
      notifyListeners();
    }
  }

  /// Load nav + section visibility config. Called once on app start (no location needed).
  Future<void> loadAppConfig() async {
    try {
      final configs = await _service.getAppConfig();
      _appConfig = {
        for (final c in configs)
          c['featureName'].toString(): c['isActive'] == true,
      };
      _appConfigLoaded = true;
      notifyListeners();
    } catch (_) {
      _appConfigLoaded = true; // Fail-open
      notifyListeners();
    }
  }

  /// Convenience: load both in parallel. Call this from the dashboard init.
  Future<void> load(double lat, double lng) async {
    await Future.wait([
      loadServiceFeatures(lat, lng),
      if (!_appConfigLoaded) loadAppConfig(),
    ]);
  }
}
