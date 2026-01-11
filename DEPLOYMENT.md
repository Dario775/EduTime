# EduTime Deployment Guide

## Pre-Deployment Checklist

### 1. Security Configuration

- [ ] **SSL Pinning**: Update certificate fingerprints in `lib/core/network/ssl_pinning.dart`
  - Get SHA-256 fingerprints from Firebase console
  - Include backup certificates for rotation
  
- [ ] **ProGuard**: Verify rules in `android/app/proguard-rules.pro`
  - Test release build thoroughly
  - Check that services (Accessibility, Overlay) work
  
- [ ] **Firebase Config**: Ensure `google-services.json` is production version
  - Verify package name matches
  - Check SHA-1/SHA-256 fingerprints
  
- [ ] **API Keys**: Remove or secure all debug API keys
  - Set `anticheat.secret` in Firebase Functions config

### 2. Build Configuration

#### Android Release Build

```bash
# Generate release keystore (if not exists)
keytool -genkey -v -keystore edutime-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias edutime

# Create key.properties
echo "storePassword=<password>" > android/key.properties
echo "keyPassword=<password>" >> android/key.properties
echo "keyAlias=edutime" >> android/key.properties
echo "storeFile=../edutime-release.jks" >> android/key.properties

# Build release APK
flutter build apk --release

# Build release App Bundle (for Play Store)
flutter build appbundle --release
```

#### iOS Release Build

```bash
# Install pods
cd ios && pod install && cd ..

# Build iOS release
flutter build ios --release

# Archive in Xcode for App Store submission
```

### 3. Firebase Functions Deployment

```bash
cd functions

# Install dependencies
npm install

# Build TypeScript
npm run build

# Set production secrets
firebase functions:config:set anticheat.secret="YOUR_PRODUCTION_SECRET"

# Deploy functions
firebase deploy --only functions
```

### 4. Firestore Security Rules

```bash
# Deploy security rules
firebase deploy --only firestore:rules

# Deploy storage rules (if applicable)
firebase deploy --only storage:rules
```

### 5. Testing Before Launch

#### Unit Tests
```bash
flutter test
```

#### Integration Tests
```bash
# Run on connected device
flutter test integration_test/overlay_resilience_test.dart
```

#### Manual Testing Checklist
- [ ] Test all permissions flow
- [ ] Verify overlay blocks apps correctly
- [ ] Test wallet transactions
- [ ] Verify FCM notifications work
- [ ] Test offline sync
- [ ] Force stop app and verify recovery
- [ ] Reboot device and verify auto-start

### 6. Play Store Submission

#### Required Assets
- [ ] App icon (512x512)
- [ ] Feature graphic (1024x500)
- [ ] Screenshots (phone & tablet)
- [ ] Privacy policy URL
- [ ] Terms of service URL

#### App Content
- [ ] Content rating questionnaire
- [ ] Data safety section
- [ ] Target audience declaration

#### Special Permissions Justification
For SYSTEM_ALERT_WINDOW:
> EduTime requires overlay permission to display time-out notifications 
> that block access to restricted apps when the child has exhausted their 
> screen time balance. This is core to the parental control functionality.

For BIND_ACCESSIBILITY_SERVICE:
> EduTime uses the Accessibility Service to detect which apps are being 
> used on the device, enabling parental monitoring and time management 
> features. No personal data is collected.

### 7. Post-Launch Monitoring

- [ ] Set up Firebase Crashlytics
- [ ] Configure Firebase Analytics events
- [ ] Set up alerting for function errors
- [ ] Monitor FCM delivery rates

## Environment Variables

### Flutter App
```
FIREBASE_PROJECT_ID=edutime-production
```

### Firebase Functions
```bash
firebase functions:config:set \
  anticheat.secret="[PRODUCTION_SECRET]" \
  app.environment="production"
```

## Rollback Procedure

If issues are detected post-launch:

1. **Disable new user registrations** (via Remote Config)
2. **Rollback Functions**: `firebase functions:delete [function_name]`
3. **Notify users** via FCM if critical
4. **Fix and redeploy** after thorough testing

## Support Contacts

- Technical Issues: [email]
- Play Store Support: [email]
- Firebase Support: console.firebase.google.com/support
