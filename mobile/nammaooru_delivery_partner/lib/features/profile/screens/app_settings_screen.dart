import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/delivery_partner_provider.dart';
import '../services/profile_service.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_switch_tile.dart';
import '../widgets/settings_dropdown_tile.dart';
import '../widgets/settings_slider_tile.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = false;
  Map<String, dynamic>? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
      final partnerId = provider.currentPartner?.id;

      if (partnerId != null) {
        final settings = await _profileService.getSettings(partnerId);
        setState(() {
          _settings = settings;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'App Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF2196F3),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSettings,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Notification Settings
                    _buildNotificationSettings(),

                    const SizedBox(height: 24),

                    // App Preferences
                    _buildAppPreferences(),

                    const SizedBox(height: 24),

                    // Work Settings
                    _buildWorkSettings(),

                    const SizedBox(height: 24),

                    // Location Settings
                    _buildLocationSettings(),

                    const SizedBox(height: 24),

                    // App Behavior
                    _buildAppBehaviorSettings(),

                    const SizedBox(height: 24),

                    // Reset Settings
                    _buildResetSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNotificationSettings() {
    if (_settings == null) return const SizedBox.shrink();

    return SettingsSection(
      title: 'Notifications',
      icon: Icons.notifications,
      children: [
        SettingsSwitchTile(
          title: 'Push Notifications',
          subtitle: 'Receive push notifications',
          value: _settings!['pushNotificationsEnabled'] ?? true,
          onChanged: (value) => _updateNotificationSetting('pushNotificationsEnabled', value),
        ),
        SettingsSwitchTile(
          title: 'Email Notifications',
          subtitle: 'Receive email notifications',
          value: _settings!['emailNotificationsEnabled'] ?? true,
          onChanged: (value) => _updateNotificationSetting('emailNotificationsEnabled', value),
        ),
        SettingsSwitchTile(
          title: 'SMS Notifications',
          subtitle: 'Receive SMS notifications',
          value: _settings!['smsNotificationsEnabled'] ?? true,
          onChanged: (value) => _updateNotificationSetting('smsNotificationsEnabled', value),
        ),
        SettingsSwitchTile(
          title: 'Order Notifications',
          subtitle: 'Get notified about new orders',
          value: _settings!['orderNotificationsEnabled'] ?? true,
          onChanged: (value) => _updateNotificationSetting('orderNotificationsEnabled', value),
        ),
        SettingsSwitchTile(
          title: 'Earnings Notifications',
          subtitle: 'Get notified about earnings updates',
          value: _settings!['earningsNotificationsEnabled'] ?? true,
          onChanged: (value) => _updateNotificationSetting('earningsNotificationsEnabled', value),
        ),
        SettingsSwitchTile(
          title: 'Promotional Notifications',
          subtitle: 'Receive promotional offers',
          value: _settings!['promotionalNotificationsEnabled'] ?? true,
          onChanged: (value) => _updateNotificationSetting('promotionalNotificationsEnabled', value),
        ),
      ],
    );
  }

  Widget _buildAppPreferences() {
    if (_settings == null) return const SizedBox.shrink();

    return SettingsSection(
      title: 'App Preferences',
      icon: Icons.palette,
      children: [
        SettingsDropdownTile<String>(
          title: 'Language',
          subtitle: 'Choose your preferred language',
          value: _settings!['preferredLanguage'] ?? 'ENGLISH',
          items: _profileService.getSupportedLanguages().map((lang) => DropdownMenuItem(
            value: lang,
            child: Text(_profileService.getLanguageDisplayName(lang)),
          )).toList(),
          onChanged: (value) => _updateAppPreference('preferredLanguage', value),
        ),
        SettingsDropdownTile<String>(
          title: 'App Theme',
          subtitle: 'Choose your preferred theme',
          value: _settings!['appTheme'] ?? 'LIGHT',
          items: _profileService.getSupportedThemes().map((theme) => DropdownMenuItem(
            value: theme,
            child: Text(_profileService.getThemeDisplayName(theme)),
          )).toList(),
          onChanged: (value) => _updateAppPreference('appTheme', value),
        ),
      ],
    );
  }

  Widget _buildWorkSettings() {
    if (_settings == null) return const SizedBox.shrink();

    return SettingsSection(
      title: 'Work Settings',
      icon: Icons.work,
      children: [
        SettingsSwitchTile(
          title: 'Auto Accept Orders',
          subtitle: 'Automatically accept orders when available',
          value: _settings!['autoAcceptOrders'] ?? false,
          onChanged: (value) => _updateAutoAcceptOrders(value),
        ),
        SettingsSwitchTile(
          title: 'Work Schedule',
          subtitle: 'Enable work schedule restrictions',
          value: _settings!['workScheduleEnabled'] ?? false,
          onChanged: (value) => _updateWorkScheduleEnabled(value),
        ),
        if (_settings!['workScheduleEnabled'] == true) ...[
          ListTile(
            leading: const Icon(Icons.schedule, color: Color(0xFF2196F3)),
            title: const Text('Work Hours'),
            subtitle: Text(
              '${_settings!['workStartTime'] ?? '--:--'} - ${_settings!['workEndTime'] ?? '--:--'}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToWorkSchedule(),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationSettings() {
    if (_settings == null) return const SizedBox.shrink();

    return SettingsSection(
      title: 'Location Settings',
      icon: Icons.location_on,
      children: [
        SettingsSwitchTile(
          title: 'Location Sharing',
          subtitle: 'Share your location for deliveries',
          value: _settings!['locationSharingEnabled'] ?? true,
          onChanged: (value) => _updateLocationSharing(value),
        ),
        if (_settings!['locationSharingEnabled'] == true)
          SettingsSliderTile(
            title: 'Tracking Frequency',
            subtitle: 'How often to update location (seconds)',
            value: (_settings!['locationTrackingFrequencySeconds'] ?? 30).toDouble(),
            min: 10,
            max: 120,
            divisions: 11,
            onChanged: (value) => _updateTrackingFrequency(value.toInt()),
          ),
      ],
    );
  }

  Widget _buildAppBehaviorSettings() {
    if (_settings == null) return const SizedBox.shrink();

    return SettingsSection(
      title: 'App Behavior',
      icon: Icons.tune,
      children: [
        SettingsSwitchTile(
          title: 'Sound Alerts',
          subtitle: 'Play sounds for notifications',
          value: _settings!['enableSoundAlerts'] ?? true,
          onChanged: (value) => _updateAppBehavior('enableSoundAlerts', value),
        ),
        SettingsSwitchTile(
          title: 'Vibration Alerts',
          subtitle: 'Vibrate for notifications',
          value: _settings!['enableVibrationAlerts'] ?? true,
          onChanged: (value) => _updateAppBehavior('enableVibrationAlerts', value),
        ),
        SettingsSwitchTile(
          title: 'Traffic Overlay',
          subtitle: 'Show traffic information on map',
          value: _settings!['trafficOverlayEnabled'] ?? true,
          onChanged: (value) => _updateAppBehavior('trafficOverlayEnabled', value),
        ),
        SettingsSwitchTile(
          title: 'Show Tutorial',
          subtitle: 'Show tutorial on app start',
          value: _settings!['showTutorial'] ?? true,
          onChanged: (value) => _updateAppBehavior('showTutorial', value),
        ),
      ],
    );
  }

  Widget _buildResetSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restore, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  'Reset Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Reset all settings to their default values. This action cannot be undone.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showResetConfirmation(),
                icon: const Icon(Icons.restore),
                label: const Text('Reset All Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateNotificationSetting(String setting, bool value) async {
    try {
      final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
      final partnerId = provider.currentPartner?.id;

      if (partnerId != null) {
        await _profileService.updateNotificationPreferences(
          partnerId: partnerId,
          pushEnabled: setting == 'pushNotificationsEnabled' ? value : _settings!['pushNotificationsEnabled'],
          emailEnabled: setting == 'emailNotificationsEnabled' ? value : _settings!['emailNotificationsEnabled'],
          smsEnabled: setting == 'smsNotificationsEnabled' ? value : _settings!['smsNotificationsEnabled'],
          orderEnabled: setting == 'orderNotificationsEnabled' ? value : _settings!['orderNotificationsEnabled'],
          earningsEnabled: setting == 'earningsNotificationsEnabled' ? value : _settings!['earningsNotificationsEnabled'],
          promotionalEnabled: setting == 'promotionalNotificationsEnabled' ? value : _settings!['promotionalNotificationsEnabled'],
        );

        setState(() {
          _settings![setting] = value;
        });

        _showSuccessSnackBar('Notification settings updated');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update notification settings: $e');
    }
  }

  Future<void> _updateAppPreference(String setting, String? value) async {
    if (value == null) return;

    try {
      final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
      final partnerId = provider.currentPartner?.id;

      if (partnerId != null) {
        await _profileService.updateAppPreferences(
          partnerId: partnerId,
          language: setting == 'preferredLanguage' ? value : _settings!['preferredLanguage'],
          theme: setting == 'appTheme' ? value : _settings!['appTheme'],
        );

        setState(() {
          _settings![setting] = value;
        });

        _showSuccessSnackBar('App preferences updated');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update app preferences: $e');
    }
  }

  Future<void> _updateAutoAcceptOrders(bool value) async {
    try {
      final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
      final partnerId = provider.currentPartner?.id;

      if (partnerId != null) {
        await _profileService.updateAutoAcceptOrders(
          partnerId: partnerId,
          autoAccept: value,
        );

        setState(() {
          _settings!['autoAcceptOrders'] = value;
        });

        _showSuccessSnackBar('Auto accept setting updated');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update auto accept setting: $e');
    }
  }

  Future<void> _updateWorkScheduleEnabled(bool value) async {
    try {
      final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
      final partnerId = provider.currentPartner?.id;

      if (partnerId != null) {
        await _profileService.updateWorkSchedule(
          partnerId: partnerId,
          scheduleEnabled: value,
          startTime: _settings!['workStartTime'],
          endTime: _settings!['workEndTime'],
          workDays: _settings!['workDays'],
        );

        setState(() {
          _settings!['workScheduleEnabled'] = value;
        });

        _showSuccessSnackBar('Work schedule setting updated');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update work schedule setting: $e');
    }
  }

  Future<void> _updateLocationSharing(bool value) async {
    try {
      final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
      final partnerId = provider.currentPartner?.id;

      if (partnerId != null) {
        await _profileService.updateLocationSettings(
          partnerId: partnerId,
          locationSharingEnabled: value,
          trackingFrequencySeconds: _settings!['locationTrackingFrequencySeconds'] ?? 30,
        );

        setState(() {
          _settings!['locationSharingEnabled'] = value;
        });

        _showSuccessSnackBar('Location sharing updated');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update location sharing: $e');
    }
  }

  Future<void> _updateTrackingFrequency(int seconds) async {
    try {
      final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
      final partnerId = provider.currentPartner?.id;

      if (partnerId != null) {
        await _profileService.updateLocationSettings(
          partnerId: partnerId,
          locationSharingEnabled: _settings!['locationSharingEnabled'] ?? true,
          trackingFrequencySeconds: seconds,
        );

        setState(() {
          _settings!['locationTrackingFrequencySeconds'] = seconds;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update tracking frequency: $e');
    }
  }

  Future<void> _updateAppBehavior(String setting, bool value) async {
    setState(() {
      _settings![setting] = value;
    });

    // For app behavior settings, we might just update locally
    // as they might not need server sync
    _showSuccessSnackBar('Setting updated');
  }

  void _navigateToWorkSchedule() {
    Navigator.pushNamed(context, '/work-schedule').then((_) => _loadSettings());
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetSettings() async {
    try {
      final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
      final partnerId = provider.currentPartner?.id;

      if (partnerId != null) {
        await _profileService.resetSettings(partnerId: partnerId);
        await _loadSettings();
        _showSuccessSnackBar('Settings reset to default values');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to reset settings: $e');
    }
  }
}