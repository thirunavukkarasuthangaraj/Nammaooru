#!/bin/bash

# NammaOoru Mobile App Build Script
# This script automates the build process for different environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
BUILD_TYPE="release"
PLATFORM="all"
CLEAN_BUILD=false
RUN_TESTS=true
ENVIRONMENT="production"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --type TYPE         Build type (debug|profile|release) [default: release]"
    echo "  -p, --platform PLATFORM Platform (android|ios|all) [default: all]"
    echo "  -c, --clean             Clean build (removes previous build artifacts)"
    echo "  -s, --skip-tests        Skip running tests"
    echo "  -e, --env ENVIRONMENT   Environment (development|staging|production) [default: production]"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --type release --platform android"
    echo "  $0 --clean --skip-tests"
    echo "  $0 --env staging --type profile"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -s|--skip-tests)
            RUN_TESTS=false
            shift
            ;;
        -e|--env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate build type
if [[ ! "$BUILD_TYPE" =~ ^(debug|profile|release)$ ]]; then
    print_error "Invalid build type: $BUILD_TYPE"
    exit 1
fi

# Validate platform
if [[ ! "$PLATFORM" =~ ^(android|ios|all)$ ]]; then
    print_error "Invalid platform: $PLATFORM"
    exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(development|staging|production)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    exit 1
fi

print_status "Starting NammaOoru Mobile App build process..."
print_status "Build Type: $BUILD_TYPE"
print_status "Platform: $PLATFORM"
print_status "Environment: $ENVIRONMENT"
print_status "Clean Build: $CLEAN_BUILD"

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check Flutter doctor
print_status "Checking Flutter doctor..."
flutter doctor --no-version-check

# Navigate to project directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

print_status "Project directory: $PROJECT_DIR"

# Clean build if requested
if [[ "$CLEAN_BUILD" == true ]]; then
    print_status "Cleaning previous build artifacts..."
    flutter clean
    
    # Clean iOS pods if building for iOS
    if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "all" ]]; then
        if [[ -d "ios" ]]; then
            cd ios
            rm -rf Pods Podfile.lock
            cd ..
        fi
    fi
    
    # Clean Android build if building for Android
    if [[ "$PLATFORM" == "android" || "$PLATFORM" == "all" ]]; then
        if [[ -d "android" ]]; then
            cd android
            ./gradlew clean || true
            cd ..
        fi
    fi
fi

# Get dependencies
print_status "Getting Flutter dependencies..."
flutter pub get

# Run code generation if needed
if [[ -f "pubspec.yaml" ]] && grep -q "build_runner" pubspec.yaml; then
    print_status "Running code generation..."
    flutter packages pub run build_runner build --delete-conflicting-outputs
fi

# Run tests if not skipped
if [[ "$RUN_TESTS" == true ]]; then
    print_status "Running tests..."
    flutter test || {
        print_warning "Some tests failed, but continuing with build..."
    }
fi

# Run static analysis
print_status "Running static analysis..."
flutter analyze || {
    print_warning "Static analysis found issues, but continuing with build..."
}

# Set environment variables based on environment
case $ENVIRONMENT in
    development)
        DART_DEFINES="--dart-define=ENVIRONMENT=development"
        ;;
    staging)
        DART_DEFINES="--dart-define=ENVIRONMENT=staging"
        ;;
    production)
        DART_DEFINES="--dart-define=ENVIRONMENT=production"
        ;;
esac

# Build for Android
if [[ "$PLATFORM" == "android" || "$PLATFORM" == "all" ]]; then
    print_status "Building Android app..."
    
    # Check Android SDK
    if [[ -z "$ANDROID_HOME" ]]; then
        print_warning "ANDROID_HOME not set. Make sure Android SDK is properly configured."
    fi
    
    case $BUILD_TYPE in
        debug)
            print_status "Building Android APK (Debug)..."
            flutter build apk --debug $DART_DEFINES
            ;;
        profile)
            print_status "Building Android APK (Profile)..."
            flutter build apk --profile $DART_DEFINES
            ;;
        release)
            print_status "Building Android App Bundle (Release)..."
            flutter build appbundle --release $DART_DEFINES
            
            print_status "Building Android APK (Release)..."
            flutter build apk --release $DART_DEFINES
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        print_success "Android build completed successfully!"
        
        # Show build outputs
        if [[ "$BUILD_TYPE" == "release" ]]; then
            print_status "Android App Bundle: build/app/outputs/bundle/release/app-release.aab"
            print_status "Android APK: build/app/outputs/flutter-apk/app-release.apk"
        else
            print_status "Android APK: build/app/outputs/flutter-apk/app-$BUILD_TYPE.apk"
        fi
    else
        print_error "Android build failed!"
        exit 1
    fi
fi

# Build for iOS
if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "all" ]]; then
    # Check if running on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        print_warning "iOS builds are only supported on macOS. Skipping iOS build."
    else
        print_status "Building iOS app..."
        
        # Install iOS dependencies
        if [[ -d "ios" ]]; then
            cd ios
            if command -v pod &> /dev/null; then
                print_status "Installing iOS dependencies..."
                pod install
            else
                print_warning "CocoaPods not found. iOS dependencies may not be up to date."
            fi
            cd ..
        fi
        
        case $BUILD_TYPE in
            debug)
                print_status "Building iOS app (Debug)..."
                flutter build ios --debug --no-codesign $DART_DEFINES
                ;;
            profile)
                print_status "Building iOS app (Profile)..."
                flutter build ios --profile --no-codesign $DART_DEFINES
                ;;
            release)
                print_status "Building iOS app (Release)..."
                flutter build ios --release --no-codesign $DART_DEFINES
                ;;
        esac
        
        if [[ $? -eq 0 ]]; then
            print_success "iOS build completed successfully!"
            print_status "iOS app: build/ios/iphoneos/Runner.app"
            print_status "Open ios/Runner.xcworkspace in Xcode for signing and distribution"
        else
            print_error "iOS build failed!"
            exit 1
        fi
    fi
fi

# Generate build info
BUILD_INFO_FILE="build_info.json"
print_status "Generating build information..."

cat > "$BUILD_INFO_FILE" << EOF
{
  "buildTime": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "buildType": "$BUILD_TYPE",
  "platform": "$PLATFORM",
  "environment": "$ENVIRONMENT",
  "flutterVersion": "$(flutter --version | head -n 1)",
  "dartVersion": "$(dart --version)",
  "gitCommit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
  "gitBranch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
}
EOF

print_success "Build information saved to $BUILD_INFO_FILE"

# Performance suggestions
print_status "Build completed! Performance suggestions:"
echo "  • Test the $BUILD_TYPE build on physical devices"
echo "  • Monitor app size and performance metrics"
echo "  • Run integration tests on different device configurations"

if [[ "$BUILD_TYPE" == "release" ]]; then
    echo "  • Upload to internal testing before production release"
    echo "  • Update release notes and version information"
fi

print_success "NammaOoru Mobile App build process completed successfully!"