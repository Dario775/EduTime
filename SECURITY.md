# EduTime Security Documentation

## Overview

EduTime implements multiple layers of security to protect:
- Child user data
- Parental control configurations  
- Time balance and transactions
- Device access and monitoring

## Security Layers

### 1. Transport Security (SSL Pinning)

**File**: `lib/core/network/ssl_pinning.dart`

- Certificate pinning for Firebase and custom APIs
- SHA-256 fingerprint validation
- Graceful fallback for development environments

**Updating Certificates**:
```dart
static const List<String> _pinnedCertificates = [
  'sha256/YOUR_NEW_CERTIFICATE_FINGERPRINT',
];
```

### 2. Code Obfuscation (ProGuard/R8)

**File**: `android/app/proguard-rules.pro`

Features:
- Removal of debug logs in release builds
- Class and package renaming
- Protection of critical services
- Preservation of reflection-based code

### 3. Device Security Checks

**File**: `lib/core/security/security_utils.dart`

Detects:
- Rooted/jailbroken devices
- Emulators
- App tampering
- Debugger attachment

### 4. Secure Data Storage

**Android Keystore Integration**:
- AES-256-GCM encryption
- Hardware-backed key storage (when available)
- Per-key master key protection

**File**: `android/app/src/main/kotlin/.../MainActivity.kt`

### 5. Anti-Cheat Validation

**Server-side** (`functions/src/modules/sync/syncOfflineActivity.ts`):
- Client hash verification (HMAC-SHA256)
- Timestamp consistency checks
- Overlap detection
- Rate limiting
- Batch idempotency

**Client Hash Generation**:
```
HMAC-SHA256(childId:packageName:duration:start:end, SECRET)
```

### 6. Authorization

**Firebase Auth** + **Custom Claims**:
- Role-based access (PARENT, CHILD)
- Family membership verification
- Wallet ownership checks

### 7. Firestore Security Rules

Required rules for production:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read their own profile
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId 
                   && !request.resource.data.diff(resource.data).changedKeys()
                      .hasAny(['role', 'familyId']);
    }
    
    // Wallets - owner and family parents can read
    match /wallets/{walletId} {
      allow read: if isOwnerOrParent(walletId);
      allow write: if false; // Only via Cloud Functions
    }
    
    // Families - members can read, parents can write settings
    match /families/{familyId} {
      allow read: if isFamilyMember(familyId);
      allow write: if isParentOfFamily(familyId);
    }
    
    // Helper functions
    function isFamilyMember(familyId) {
      let family = get(/databases/$(database)/documents/families/$(familyId));
      return request.auth.uid in family.data.parentUids 
          || request.auth.uid in family.data.childUids;
    }
    
    function isParentOfFamily(familyId) {
      let family = get(/databases/$(database)/documents/families/$(familyId));
      return request.auth.uid in family.data.parentUids;
    }
    
    function isOwnerOrParent(walletId) {
      if (request.auth.uid == walletId) return true;
      let user = get(/databases/$(database)/documents/users/$(walletId));
      if (user.data.familyId == null) return false;
      let family = get(/databases/$(database)/documents/families/$(user.data.familyId));
      return request.auth.uid in family.data.parentUids;
    }
  }
}
```

## Threat Model

| Threat | Mitigation |
|--------|------------|
| MITM Attack | SSL Pinning |
| Reverse Engineering | ProGuard obfuscation |
| Time Manipulation | Server-side timestamp validation |
| Rooted Device Bypass | Root detection + server-side checks |
| Unauthorized Data Access | Firebase Auth + Firestore rules |
| Replay Attacks | Batch ID idempotency |
| Rate Abuse | Server-side rate limiting |

## Security Testing

### Unit Tests
```bash
flutter test test/domain/usecases/calculate_credit_test.dart
```

### Integration Tests
```bash
flutter test integration_test/overlay_resilience_test.dart
```

### Manual Penetration Testing

1. **Proxy interception**: Verify SSL pinning blocks proxied requests
2. **Root bypass**: Test on rooted device with Magisk Hide
3. **Time manipulation**: Change device time and verify rejection
4. **APK tampering**: Resign APK and test signature verification

## Incident Response

### Suspected Compromise

1. Rotate Firebase Functions secrets immediately
2. Revoke affected user tokens
3. Analyze Firestore audit logs
4. Patch and redeploy

### Data Breach

1. Follow local data protection regulations
2. Notify affected users
3. Document incident thoroughly
4. Implement additional safeguards

## Compliance Notes

### COPPA (Children's Online Privacy)
- Parental consent required before data collection
- Minimal data collection principle
- Parent access to child's data

### GDPR (EU)
- Right to erasure via account deletion
- Data portability on request
- Clear privacy policy

## Contact

Security issues: security@edutime.app
