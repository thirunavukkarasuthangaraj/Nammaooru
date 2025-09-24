# NammaOoru Shop Owner App - Deployment Guide

This guide provides comprehensive instructions for deploying the NammaOoru Shop Owner App to production and staging environments.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Build Configuration](#build-configuration)
4. [Testing](#testing)
5. [Building the App](#building-the-app)
6. [Deployment Process](#deployment-process)
7. [Post-Deployment](#post-deployment)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### Development Environment
- Flutter SDK 3.16.0 or later
- Dart SDK 3.2.0 or later
- Android Studio / Xcode (for respective platforms)
- Git
- Firebase CLI (optional, for Firebase features)

### Accounts & Access
- Google Play Console account (for Android)
- Apple Developer account (for iOS)
- Firebase project access
- Git repository access

### Tools
- fastlane (optional, for automated deployment)
- Firebase CLI
- App signing certificates

## Environment Setup

### 1. Flutter Environment
```bash
# Verify Flutter installation
flutter doctor

# Ensure all dependencies are up to date
flutter pub get
```

### 2. Android Setup
```bash
# Set Android SDK path
export ANDROID_HOME=/path/to/android/sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# Accept all licenses
flutter doctor --android-licenses
```

### 3. iOS Setup (macOS only)
```bash
# Install CocoaPods
sudo gem install cocoapods

# Install iOS dependencies
cd ios && pod install
```

## Build Configuration

### 1. Update Version Information

Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

### 2. Configure Environment Variables

Create environment-specific configuration files:

**For Development:**
```dart
// lib/config/development.dart
const String API_URL = 'https://dev-api.nammaooru.com';
const String FIREBASE_PROJECT = 'nammaooru-dev';
```

**For Production:**
```dart
// lib/config/production.dart
const String API_URL = 'https://api.nammaooru.com';
const String FIREBASE_PROJECT = 'nammaooru-prod';
```

### 3. App Signing

#### Android Signing
1. Generate upload keystore:
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Create `android/key.properties`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=upload
storeFile=upload-keystore.jks
```

#### iOS Signing
1. Configure signing in Xcode
2. Set up provisioning profiles
3. Configure automatic signing (recommended)

## Testing

### 1. Run All Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widget_test.dart
```

### 2. Performance Testing
```bash
# Run performance tests
dart run lib/utils/app_test_suite.dart
```

### 3. Manual Testing Checklist
- [ ] Login/Logout functionality
- [ ] Dashboard loads correctly
- [ ] Product management works
- [ ] Order management works
- [ ] Notifications are received
- [ ] App handles offline scenarios
- [ ] Deep links work correctly
- [ ] Push notifications work

## Building the App

### Using the Deployment Script

The recommended way to build and deploy:

```bash
# Development build
dart run deployment/deploy.dart --environment=development --platform=android

# Staging build
dart run deployment/deploy.dart --environment=staging --platform=both

# Production build
dart run deployment/deploy.dart --environment=production --platform=both
```

### Manual Build Commands

#### Android
```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

# App Bundle (recommended for Play Store)
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

#### iOS
```bash
# Release build
flutter build ios --release --obfuscate --split-debug-info=build/ios/symbols

# IPA for distribution
flutter build ipa --release --obfuscate --split-debug-info=build/ios/symbols
```

## Deployment Process

### Development Environment

1. **Automated Deployment:**
```bash
dart run deployment/deploy.dart --environment=development --platform=both --verbose
```

2. **Manual Steps:**
   - Build APK/IPA
   - Distribute via Firebase App Distribution
   - Notify testing team

### Staging Environment

1. **Pre-deployment Checklist:**
   - [ ] All tests pass
   - [ ] Code reviewed and approved
   - [ ] Version number updated
   - [ ] Release notes prepared

2. **Deployment:**
```bash
dart run deployment/deploy.dart --environment=staging --platform=both
```

3. **Post-deployment:**
   - [ ] Verify app functionality
   - [ ] Test critical user flows
   - [ ] Check analytics integration

### Production Environment

1. **Pre-deployment Checklist:**
   - [ ] Staging testing completed
   - [ ] Performance testing passed
   - [ ] Security review completed
   - [ ] App store assets prepared
   - [ ] Release notes finalized

2. **Android Production Deployment:**

   a. **Build:**
   ```bash
   dart run deployment/deploy.dart --environment=production --platform=android
   ```

   b. **Upload to Play Console:**
   - Navigate to Google Play Console
   - Upload `build/app/outputs/bundle/release/app-release.aab`
   - Fill in release notes
   - Submit for review

3. **iOS Production Deployment:**

   a. **Build:**
   ```bash
   dart run deployment/deploy.dart --environment=production --platform=ios
   ```

   b. **Upload to App Store Connect:**
   - Use Xcode or Application Loader
   - Upload `build/ios/ipa/Runner.ipa`
   - Submit for review

## Post-Deployment

### 1. Monitoring

- **Crashlytics:** Monitor for crashes
- **Analytics:** Check user engagement
- **Performance:** Monitor app performance
- **Reviews:** Monitor app store reviews

### 2. Health Checks

```bash
# Run app health check
dart run lib/utils/app_initializer.dart --health-check
```

### 3. Rollback Plan

If issues are detected:

1. **Immediate Actions:**
   - Stop staged rollout
   - Communicate with stakeholders
   - Investigate the issue

2. **Rollback Process:**
   - Revert to previous version on app stores
   - Deploy hotfix if possible
   - Monitor for stability

## Troubleshooting

### Common Build Issues

#### Android

**Issue:** Build fails with "Could not resolve dependencies"
**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**Issue:** Signing issues
**Solution:**
- Verify `key.properties` file
- Check keystore file path
- Ensure passwords are correct

#### iOS

**Issue:** Code signing errors
**Solution:**
- Clean Xcode build folder
- Update provisioning profiles
- Check certificate validity

**Issue:** CocoaPods issues
**Solution:**
```bash
cd ios
pod deintegrate
pod install
```

### Performance Issues

**Issue:** App startup is slow
**Solution:**
- Check for heavy initialization code
- Use performance profiler
- Optimize image assets

**Issue:** Memory leaks detected
**Solution:**
```bash
# Run memory analysis
dart run lib/utils/memory_manager.dart --analyze
```

### Deployment Issues

**Issue:** Deployment script fails
**Solution:**
- Check environment variables
- Verify file permissions
- Run with `--verbose` flag for details

**Issue:** App store rejection
**Solution:**
- Review rejection reason
- Fix identified issues
- Resubmit with changes

## Environment-Specific Notes

### Development
- Uses mock data by default
- Debug tools enabled
- Verbose logging enabled
- Performance monitoring enabled

### Staging
- Real API endpoints
- Limited feature flags
- Basic analytics
- User acceptance testing

### Production
- Full feature set
- Optimized performance
- Complete analytics
- Error reporting
- User feedback collection

## Security Considerations

### Code Obfuscation
- Enabled for production builds
- Debug symbols stripped
- API keys secured

### Network Security
- Certificate pinning enabled
- HTTPS enforced
- API request signing

### Data Protection
- User data encrypted
- Secure storage used
- Privacy compliance

## Support and Maintenance

### Version Updates
- Semantic versioning used
- Release notes maintained
- Backward compatibility considered

### Bug Fixes
- Hotfix process established
- Testing procedures defined
- Rollback plan ready

### Feature Updates
- Feature flag system
- A/B testing capability
- Gradual rollout strategy

## Contact Information

- **Development Team:** dev-team@nammaooru.com
- **DevOps Team:** devops@nammaooru.com
- **Support Team:** support@nammaooru.com

## Additional Resources

- [Flutter Deployment Documentation](https://flutter.dev/docs/deployment)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
- [Firebase Documentation](https://firebase.google.com/docs)

---

**Last Updated:** January 15, 2024
**Version:** 1.0.0