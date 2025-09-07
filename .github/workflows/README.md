# WhatsApp Clone Mobile CI/CD Pipeline

This document describes the Flutter mobile CI/CD pipeline that builds and deploys the WhatsApp Clone app to iOS App Store and Google Play Store.

## Pipeline Overview

The CI/CD pipeline consists of the following jobs:

1. **Test** - Runs Flutter tests, code analysis, and integration tests
2. **Security** - Performs security scanning with Trivy
3. **Build Android** - Builds APK for Android devices
4. **Build iOS** - Builds IPA for iOS devices  
5. **Deploy Android** - Deploys to Google Play Console
6. **Deploy iOS** - Deploys to App Store Connect
7. **Performance Test** - Runs mobile performance tests
8. **Cleanup** - Cleans up build artifacts

## Required GitHub Secrets

### Android Deployment Secrets

Add these secrets to your GitHub repository settings:

```
ANDROID_KEYSTORE_BASE64          # Base64 encoded Android keystore file
ANDROID_KEYSTORE_PASSWORD        # Password for the keystore
ANDROID_KEY_PASSWORD             # Password for the signing key
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON # Google Play Console service account JSON
```

### iOS Deployment Secrets

```
IOS_BUILD_CERTIFICATE_BASE64     # Base64 encoded iOS distribution certificate (.p12)
IOS_P12_PASSWORD                 # Password for the .p12 certificate
IOS_BUILD_PROVISION_PROFILE_BASE64 # Base64 encoded provisioning profile
IOS_KEYCHAIN_PASSWORD            # Temporary keychain password
APP_STORE_CONNECT_USERNAME       # App Store Connect username/email
APP_STORE_CONNECT_PASSWORD       # App Store Connect app-specific password
```

### Optional Secrets

```
CODECOV_TOKEN                    # Code coverage reporting (optional)
```

## Setup Instructions

### 1. Android Setup

1. **Generate Android Keystore:**
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks \
           -keyalg RSA -keysize 2048 -validity 10000 \
           -alias upload
   ```

2. **Convert keystore to base64:**
   ```bash
   base64 -i upload-keystore.jks | pbcopy  # macOS
   base64 upload-keystore.jks | xclip -selection clipboard  # Linux
   ```

3. **Create Google Play Service Account:**
   - Go to Google Play Console → Setup → API access
   - Create a service account and download JSON key
   - Convert to base64: `base64 -i service-account.json`

4. **Update Environment Variables:**
   - Update `ANDROID_PACKAGE_NAME` in the workflow file
   - Update `applicationId` in `android/app/build.gradle.kts`

### 2. iOS Setup

1. **Create App Store Connect App:**
   - Create new app in App Store Connect
   - Note the App ID for `IOS_APP_ID` environment variable

2. **Generate iOS Certificates:**
   - Create iOS Distribution certificate in Apple Developer portal
   - Export as .p12 file with password
   - Convert to base64: `base64 -i certificate.p12`

3. **Create Provisioning Profile:**
   - Create App Store provisioning profile
   - Download and convert to base64: `base64 -i profile.mobileprovision`

4. **Update Configuration:**
   - Update `IOS_BUNDLE_ID` in workflow file
   - Update `CFBundleIdentifier` in `ios/Runner/Info.plist`
   - Update team ID in `ios/ExportOptions.plist`

### 3. Flutter Configuration

1. **Update pubspec.yaml version:**
   ```yaml
   version: 1.0.0+1  # Format: semantic_version+build_number
   ```

2. **Verify build configuration:**
   ```bash
   flutter doctor -v
   flutter analyze
   flutter test
   ```

## Deployment Workflows

### Development Builds
- **Trigger:** Push to `develop` or feature branches
- **Output:** Debug APK and unsigned iOS build
- **Testing:** Performance tests run on develop branch

### Production Releases
- **Trigger:** Git tags starting with `v` (e.g., `v1.0.0`)
- **Process:**
  1. Build signed release APK/IPA
  2. Deploy to Google Play internal track
  3. Deploy to App Store Connect for review
  4. Create GitHub release with artifacts

### Manual Workflow Dispatch
- Available for all jobs through GitHub Actions UI
- Useful for debugging build issues

## Build Artifacts

- **APK files:** Retained for 30 days
- **IPA files:** Retained for 30 days
- **Test reports:** Available in workflow logs
- **Coverage reports:** Uploaded to Codecov (if configured)

## Environment Variables

The pipeline uses these environment variables:

```yaml
FLUTTER_VERSION: '3.24.0'           # Flutter SDK version
IOS_BUNDLE_ID: 'com.whatsappclone.app'  # iOS bundle identifier
ANDROID_PACKAGE_NAME: 'com.whatsappclone.app'  # Android package name
VERSION_CODE_OFFSET: 1000000        # Base version code for builds
```

## Troubleshooting

### Common Issues

1. **Android signing fails:**
   - Verify keystore password is correct
   - Ensure `key.properties` file path is correct
   - Check that keystore alias matches

2. **iOS code signing fails:**
   - Verify certificate and provisioning profile match
   - Check that team ID is correct in ExportOptions.plist
   - Ensure provisioning profile includes all devices

3. **App Store upload fails:**
   - Verify App Store Connect credentials
   - Check that bundle ID matches registered app
   - Ensure app version is incremented

4. **Tests fail:**
   - Check Flutter dependencies are up to date
   - Verify Android emulator can start
   - Ensure all required permissions are configured

### Debug Commands

Run these locally to debug issues:

```bash
# Test Flutter configuration
flutter doctor -v
flutter pub get
flutter analyze

# Test Android build
flutter build apk --debug
flutter build apk --release  # (requires signing setup)

# Test iOS build (macOS only)
flutter build ios --debug --no-codesign
flutter build ios --release  # (requires signing setup)

# Run tests
flutter test
flutter test integration_test/
```

## Security Considerations

- All secrets are stored securely in GitHub Secrets
- Keystore and certificates are only used during CI/CD
- Network security config prevents cleartext traffic
- ProGuard rules protect app code in release builds
- Temporary keychains are cleaned up after iOS builds

## Performance Monitoring

The pipeline includes performance testing:
- Flutter performance tests on emulator
- Integration test execution time tracking
- Build time optimization with caching
- Artifact size monitoring

For more information, see the [Flutter CI/CD documentation](https://docs.flutter.dev/deployment/cd).