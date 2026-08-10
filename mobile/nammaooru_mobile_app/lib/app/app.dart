import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'routes.dart';
import 'theme.dart';
import '../core/auth/auth_provider.dart';
import '../core/widgets/connectivity_banner.dart';
import '../services/version_service.dart';
import '../shared/widgets/update_dialog.dart';

class NammaOoruApp extends StatefulWidget {
  const NammaOoruApp({super.key});

  @override
  State<NammaOoruApp> createState() => _NammaOoruAppState();
}

class _NammaOoruAppState extends State<NammaOoruApp> {
  @override
  void initState() {
    super.initState();
    _checkAppVersion();
  }

  Future<void> _checkAppVersion() async {
    try {
      debugPrint('🔄 Starting version check...');
      // Wait longer for the app to fully initialize and build context
      await Future.delayed(const Duration(seconds: 3));

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      debugPrint('📱 Current app version: $currentVersion');

      // Check for updates
      debugPrint('🌐 Calling version API...');
      final versionInfo = await VersionService.checkVersion(currentVersion);
      debugPrint('✅ Version check response: $versionInfo');

      if (versionInfo != null) {
        debugPrint('🎯 Update available! Showing dialog...');
        // Wait a bit more and show update dialog
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && context.mounted) {
          _showUpdateDialog(versionInfo, currentVersion);
        }
      } else {
        debugPrint('ℹ️ No update needed or check skipped');
      }
    } catch (e) {
      debugPrint('❌ Error checking app version: $e');
    }
  }

  void _showUpdateDialog(Map<String, dynamic> versionInfo, String currentVersion) {
    if (!mounted || !context.mounted) {
      debugPrint('❌ Context not mounted, cannot show dialog');
      return;
    }

    final bool updateRequired = versionInfo['updateRequired'] ?? false;
    final bool isMandatory = versionInfo['isMandatory'] ?? false;

    try {
      showDialog(
        context: context,
        barrierDismissible: !isMandatory,
        builder: (context) => UpdateDialog(
          currentVersion: currentVersion,
          newVersion: versionInfo['currentVersion'] ?? 'Unknown',
          releaseNotes: versionInfo['releaseNotes'] ?? '',
          updateUrl: versionInfo['updateUrl'] ?? '',
          isMandatory: isMandatory,
          updateRequired: updateRequired,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error showing update dialog: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Namma Ooru Connect',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        // Global keyboard dismiss: tapping anywhere outside a text field
        // closes the keyboard (cart, checkout, search - all screens)
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: ConnectivityBanner(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      localizationsDelegates: const [
        // AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ta', ''),
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}