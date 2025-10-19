import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_config.dart';

class AppUpdateService {
  static const String APP_NAME = 'SHOP_OWNER_APP';
  static const String APP_VERSION = '1.0.0'; // Update this with each release

  /// Check if app update is available
  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final platform = Platform.isAndroid ? 'ANDROID' : 'IOS';
      final baseUrl = AppConfig.serverBaseUrl;
      final url = Uri.parse(
        '$baseUrl/api/app-version/check?appName=$APP_NAME&platform=$platform&currentVersion=$APP_VERSION'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print('Error checking app version: $e');
      return null;
    }
  }

  /// Show update dialog if update is available
  static Future<void> showUpdateDialogIfNeeded(BuildContext context) async {
    final updateInfo = await checkForUpdate();

    if (updateInfo == null) return;

    final bool updateRequired = updateInfo['updateRequired'] ?? false;
    final bool updateAvailable = updateInfo['updateAvailable'] ?? false;
    final bool isMandatory = updateInfo['isMandatory'] ?? false;

    if (updateRequired || updateAvailable) {
      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: !isMandatory && !updateRequired,
        builder: (context) => WillPopScope(
          onWillPop: () async => !isMandatory && !updateRequired,
          child: _UpdateDialog(
            updateInfo: updateInfo,
            isMandatory: isMandatory || updateRequired,
          ),
        ),
      );
    }
  }

  /// Open app store/play store
  static Future<void> openUpdateUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _UpdateDialog extends StatelessWidget {
  final Map<String, dynamic> updateInfo;
  final bool isMandatory;

  const _UpdateDialog({
    required this.updateInfo,
    required this.isMandatory,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.system_update, color: Colors.blue, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isMandatory ? 'Update Required' : 'Update Available',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMandatory)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This update is mandatory. Please update to continue using the app.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'New Version: ${updateInfo['currentVersion']}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (updateInfo['releaseNotes'] != null && updateInfo['releaseNotes'].toString().isNotEmpty) ...[
            const Text(
              'What\'s New:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Text(
                  updateInfo['releaseNotes'],
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!isMandatory)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Later',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ElevatedButton(
          onPressed: () {
            AppUpdateService.openUpdateUrl(updateInfo['updateUrl']);
            if (isMandatory) {
              // Don't close dialog for mandatory updates
            } else {
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text(
            'Update Now',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
