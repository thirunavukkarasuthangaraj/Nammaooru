import 'dart:io';
import 'dart:convert';

/// Deployment automation script for NammaOoru Shop Owner App
///
/// Usage:
/// dart run deployment/deploy.dart --environment=production --platform=android
/// dart run deployment/deploy.dart --environment=staging --platform=ios
/// dart run deployment/deploy.dart --help

class DeploymentManager {
  static const String version = '1.0.0';

  // Command line arguments
  late final String environment;
  late final String platform;
  late final bool buildOnly;
  late final bool skipTests;
  late final bool verbose;

  DeploymentManager({
    required this.environment,
    required this.platform,
    this.buildOnly = false,
    this.skipTests = false,
    this.verbose = false,
  });

  /// Main deployment process
  Future<void> deploy() async {
    try {
      _logInfo('🚀 Starting deployment process...');
      _logInfo('Environment: $environment');
      _logInfo('Platform: $platform');
      _logInfo('Build Only: $buildOnly');

      // Validate environment and platform
      _validateInputs();

      // Pre-deployment checks
      await _runPreDeploymentChecks();

      // Run tests if not skipped
      if (!skipTests) {
        await _runTests();
      }

      // Clean and prepare
      await _cleanAndPrepare();

      // Build the app
      await _buildApp();

      // Deploy if not build-only
      if (!buildOnly) {
        await _deployApp();
      }

      // Post-deployment tasks
      await _runPostDeploymentTasks();

      _logSuccess('✅ Deployment completed successfully!');

    } catch (e, stackTrace) {
      _logError('❌ Deployment failed: $e');
      if (verbose) {
        _logError('Stack trace: $stackTrace');
      }
      exit(1);
    }
  }

  /// Validate inputs
  void _validateInputs() {
    _logInfo('🔍 Validating inputs...');

    final validEnvironments = ['development', 'staging', 'production'];
    if (!validEnvironments.contains(environment)) {
      throw Exception('Invalid environment: $environment. Valid options: ${validEnvironments.join(', ')}');
    }

    final validPlatforms = ['android', 'ios', 'both'];
    if (!validPlatforms.contains(platform)) {
      throw Exception('Invalid platform: $platform. Valid options: ${validPlatforms.join(', ')}');
    }

    _logSuccess('✅ Inputs validated');
  }

  /// Run pre-deployment checks
  Future<void> _runPreDeploymentChecks() async {
    _logInfo('🔍 Running pre-deployment checks...');

    // Check Flutter installation
    await _runCommand('flutter', ['--version']);

    // Check if we're in the correct directory
    if (!await File('pubspec.yaml').exists()) {
      throw Exception('pubspec.yaml not found. Make sure you\'re in the Flutter project root.');
    }

    // Check if necessary files exist
    await _checkRequiredFiles();

    // Check git status
    await _checkGitStatus();

    _logSuccess('✅ Pre-deployment checks passed');
  }

  /// Check required files exist
  Future<void> _checkRequiredFiles() async {
    final requiredFiles = [
      'lib/main.dart',
      'android/app/build.gradle',
      'ios/Runner.xcodeproj/project.pbxproj',
    ];

    for (final file in requiredFiles) {
      if (!await File(file).exists()) {
        throw Exception('Required file not found: $file');
      }
    }
  }

  /// Check git status
  Future<void> _checkGitStatus() async {
    try {
      final result = await _runCommand('git', ['status', '--porcelain'], captureOutput: true);
      if (result.stdout.toString().trim().isNotEmpty && environment == 'production') {
        _logWarning('⚠️ Warning: There are uncommitted changes. Consider committing before production deployment.');
      }
    } catch (e) {
      _logWarning('⚠️ Could not check git status: $e');
    }
  }

  /// Run tests
  Future<void> _runTests() async {
    _logInfo('🧪 Running tests...');

    // Run unit tests
    await _runCommand('flutter', ['test']);

    // Run integration tests if they exist
    if (await Directory('integration_test').exists()) {
      await _runCommand('flutter', ['test', 'integration_test']);
    }

    _logSuccess('✅ All tests passed');
  }

  /// Clean and prepare
  Future<void> _cleanAndPrepare() async {
    _logInfo('🧹 Cleaning and preparing...');

    // Flutter clean
    await _runCommand('flutter', ['clean']);

    // Get dependencies
    await _runCommand('flutter', ['pub', 'get']);

    // Generate code if needed
    if (await File('build_runner.yaml').exists() ||
        await _hasDevDependency('build_runner')) {
      await _runCommand('flutter', ['packages', 'pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs']);
    }

    _logSuccess('✅ Cleaning and preparation completed');
  }

  /// Build the app
  Future<void> _buildApp() async {
    _logInfo('🔨 Building app...');

    if (platform == 'android' || platform == 'both') {
      await _buildAndroid();
    }

    if (platform == 'ios' || platform == 'both') {
      await _buildIOS();
    }

    _logSuccess('✅ Build completed');
  }

  /// Build Android app
  Future<void> _buildAndroid() async {
    _logInfo('🤖 Building Android app...');

    final buildArgs = [
      'build',
      'appbundle',
      '--release',
      '--dart-define=dart.vm.product=true',
      '--dart-define=ENVIRONMENT=$environment',
    ];

    if (environment == 'production') {
      buildArgs.addAll([
        '--obfuscate',
        '--split-debug-info=build/app/outputs/symbols',
      ]);
    }

    await _runCommand('flutter', buildArgs);

    // Also build APK for testing
    final apkArgs = [
      'build',
      'apk',
      '--release',
      '--dart-define=dart.vm.product=true',
      '--dart-define=ENVIRONMENT=$environment',
    ];

    await _runCommand('flutter', apkArgs);

    _logSuccess('✅ Android build completed');
  }

  /// Build iOS app
  Future<void> _buildIOS() async {
    _logInfo('🍎 Building iOS app...');

    // Check if running on macOS
    if (!Platform.isMacOS) {
      throw Exception('iOS builds can only be performed on macOS');
    }

    final buildArgs = [
      'build',
      'ipa',
      '--release',
      '--dart-define=dart.vm.product=true',
      '--dart-define=ENVIRONMENT=$environment',
    ];

    if (environment == 'production') {
      buildArgs.addAll([
        '--obfuscate',
        '--split-debug-info=build/ios/symbols',
      ]);
    }

    await _runCommand('flutter', buildArgs);

    _logSuccess('✅ iOS build completed');
  }

  /// Deploy the app
  Future<void> _deployApp() async {
    _logInfo('🚀 Deploying app...');

    if (platform == 'android' || platform == 'both') {
      await _deployAndroid();
    }

    if (platform == 'ios' || platform == 'both') {
      await _deployIOS();
    }

    _logSuccess('✅ Deployment completed');
  }

  /// Deploy Android app
  Future<void> _deployAndroid() async {
    _logInfo('🤖 Deploying Android app...');

    if (environment == 'production') {
      _logInfo('📦 For production deployment, manually upload the AAB file to Google Play Console:');
      _logInfo('   File: build/app/outputs/bundle/release/app-release.aab');
    } else {
      _logInfo('🔧 Deploying to Firebase App Distribution...');
      // Here you would integrate with Firebase CLI or other deployment tools
      _logInfo('   APK File: build/app/outputs/flutter-apk/app-release.apk');
    }
  }

  /// Deploy iOS app
  Future<void> _deployIOS() async {
    _logInfo('🍎 Deploying iOS app...');

    if (environment == 'production') {
      _logInfo('📦 For production deployment, manually upload the IPA file to App Store Connect:');
      _logInfo('   File: build/ios/ipa/Runner.ipa');
    } else {
      _logInfo('🔧 Deploying to TestFlight or Firebase App Distribution...');
      _logInfo('   IPA File: build/ios/ipa/Runner.ipa');
    }
  }

  /// Run post-deployment tasks
  Future<void> _runPostDeploymentTasks() async {
    _logInfo('📋 Running post-deployment tasks...');

    // Create deployment summary
    await _createDeploymentSummary();

    // Archive build artifacts
    await _archiveBuildArtifacts();

    // Update version if needed
    if (environment == 'production') {
      _logInfo('💡 Consider updating version number for next release');
    }

    _logSuccess('✅ Post-deployment tasks completed');
  }

  /// Create deployment summary
  Future<void> _createDeploymentSummary() async {
    final summary = {
      'deployment_info': {
        'timestamp': DateTime.now().toIso8601String(),
        'environment': environment,
        'platform': platform,
        'version': version,
        'build_number': await _getBuildNumber(),
      },
      'build_artifacts': await _getBuildArtifacts(),
      'git_info': await _getGitInfo(),
    };

    final summaryFile = File('deployment/deployment_summary_${DateTime.now().millisecondsSinceEpoch}.json');
    await summaryFile.writeAsString(jsonEncode(summary));

    _logInfo('📄 Deployment summary saved: ${summaryFile.path}');
  }

  /// Archive build artifacts
  Future<void> _archiveBuildArtifacts() async {
    final archiveDir = Directory('deployment/archives/${DateTime.now().toIso8601String().split('T')[0]}');
    await archiveDir.create(recursive: true);

    // Copy build artifacts
    if (platform == 'android' || platform == 'both') {
      await _copyFileIfExists('build/app/outputs/bundle/release/app-release.aab', '${archiveDir.path}/');
      await _copyFileIfExists('build/app/outputs/flutter-apk/app-release.apk', '${archiveDir.path}/');
    }

    if (platform == 'ios' || platform == 'both') {
      await _copyFileIfExists('build/ios/ipa/Runner.ipa', '${archiveDir.path}/');
    }

    _logInfo('📦 Build artifacts archived: ${archiveDir.path}');
  }

  /// Helper methods

  Future<ProcessResult> _runCommand(String command, List<String> args, {bool captureOutput = false}) async {
    if (verbose) {
      _logInfo('🔧 Running: $command ${args.join(' ')}');
    }

    final result = await Process.run(command, args);

    if (result.exitCode != 0) {
      throw Exception('Command failed: $command ${args.join(' ')}\nExit code: ${result.exitCode}\nError: ${result.stderr}');
    }

    if (!captureOutput && verbose) {
      print(result.stdout);
    }

    return result;
  }

  Future<bool> _hasDevDependency(String dependency) async {
    final pubspec = await File('pubspec.yaml').readAsString();
    return pubspec.contains('$dependency:');
  }

  Future<String> _getBuildNumber() async {
    final pubspec = await File('pubspec.yaml').readAsString();
    final match = RegExp(r'version:\s*(.+)\+(\d+)').firstMatch(pubspec);
    return match?.group(2) ?? '1';
  }

  Future<List<String>> _getBuildArtifacts() async {
    final artifacts = <String>[];

    if (await File('build/app/outputs/bundle/release/app-release.aab').exists()) {
      artifacts.add('build/app/outputs/bundle/release/app-release.aab');
    }

    if (await File('build/app/outputs/flutter-apk/app-release.apk').exists()) {
      artifacts.add('build/app/outputs/flutter-apk/app-release.apk');
    }

    if (await File('build/ios/ipa/Runner.ipa').exists()) {
      artifacts.add('build/ios/ipa/Runner.ipa');
    }

    return artifacts;
  }

  Future<Map<String, String?>> _getGitInfo() async {
    try {
      final commitHash = await _runCommand('git', ['rev-parse', 'HEAD'], captureOutput: true);
      final branch = await _runCommand('git', ['rev-parse', '--abbrev-ref', 'HEAD'], captureOutput: true);

      return {
        'commit_hash': commitHash.stdout.toString().trim(),
        'branch': branch.stdout.toString().trim(),
      };
    } catch (e) {
      return {'error': 'Could not get git info: $e'};
    }
  }

  Future<void> _copyFileIfExists(String source, String destination) async {
    final sourceFile = File(source);
    if (await sourceFile.exists()) {
      final destinationDir = Directory(destination);
      await destinationDir.create(recursive: true);
      await sourceFile.copy('$destination${source.split('/').last}');
    }
  }

  void _logInfo(String message) {
    print('\x1B[34m$message\x1B[0m'); // Blue
  }

  void _logSuccess(String message) {
    print('\x1B[32m$message\x1B[0m'); // Green
  }

  void _logWarning(String message) {
    print('\x1B[33m$message\x1B[0m'); // Yellow
  }

  void _logError(String message) {
    print('\x1B[31m$message\x1B[0m'); // Red
  }
}

/// Main entry point
void main(List<String> args) async {
  // Parse command line arguments
  final argParser = _createArgParser();

  try {
    final results = argParser.parse(args);

    if (results['help'] == true) {
      print('NammaOoru Shop Owner App Deployment Script v${DeploymentManager.version}');
      print('');
      print('Usage: dart run deployment/deploy.dart [options]');
      print('');
      print(argParser.usage);
      return;
    }

    final deploymentManager = DeploymentManager(
      environment: results['environment'] ?? 'development',
      platform: results['platform'] ?? 'android',
      buildOnly: results['build-only'] ?? false,
      skipTests: results['skip-tests'] ?? false,
      verbose: results['verbose'] ?? false,
    );

    await deploymentManager.deploy();

  } catch (e) {
    print('\x1B[31m❌ Error: $e\x1B[0m');
    print('');
    print('Use --help for usage information');
    exit(1);
  }
}

/// Create argument parser
dynamic _createArgParser() {
  // Note: In a real implementation, you would use the 'args' package
  // For simplicity, we'll create a basic parser
  return _BasicArgParser();
}

/// Basic argument parser implementation
class _BasicArgParser {
  Map<String, dynamic> parse(List<String> args) {
    final results = <String, dynamic>{};

    for (int i = 0; i < args.length; i++) {
      final arg = args[i];

      if (arg.startsWith('--')) {
        final key = arg.substring(2);

        if (key == 'help') {
          results['help'] = true;
        } else if (key == 'build-only') {
          results['build-only'] = true;
        } else if (key == 'skip-tests') {
          results['skip-tests'] = true;
        } else if (key == 'verbose') {
          results['verbose'] = true;
        } else if (key.contains('=')) {
          final parts = key.split('=');
          results[parts[0]] = parts[1];
        } else if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
          results[key] = args[i + 1];
          i++; // Skip next argument
        }
      }
    }

    return results;
  }

  String get usage => '''
Options:
  --environment=<env>    Target environment (development, staging, production)
  --platform=<platform>  Target platform (android, ios, both)
  --build-only          Only build, don't deploy
  --skip-tests          Skip running tests
  --verbose             Verbose output
  --help                Show this help message

Examples:
  dart run deployment/deploy.dart --environment=production --platform=android
  dart run deployment/deploy.dart --environment=staging --platform=both --verbose
  dart run deployment/deploy.dart --build-only --skip-tests
''';
}