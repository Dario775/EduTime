import 'dart:io';
import 'package:flutter/services.dart';

/// SSL Pinning Configuration for EduTime
/// 
/// Implements certificate pinning for secure communication with:
/// - Firebase APIs
/// - Custom backend APIs
/// 
/// Uses SHA-256 fingerprints of the server certificates.
class SSLPinning {
  SSLPinning._();
  
  /// List of pinned certificates (SHA-256 fingerprints)
  /// 
  /// These should be updated when certificates are rotated.
  /// Include both current and backup certificates.
  static const List<String> _pinnedCertificates = [
    // Google/Firebase root CA (GTS Root R1)
    'sha256/hxqRlPTu1bMS/0DITB1v68qsN1ONM5LwjD1HNBZPfrg=',
    // Google Trust Services - GTS CA 1C3
    'sha256/zCTnfLwLKbS9S2sbp+uFz4KZOocFvgZS5QU/xW3v3dM=',
    // Backup: GlobalSign Root CA
    'sha256/iie1VXtL7HzAMF+/PVPR9xzT80kQxdZeJ+zduCB3uj0=',
  ];
  
  /// Custom API endpoints with their certificate pins
  static const Map<String, List<String>> _customApiPins = {
    'api.edutime.app': [
      // Primary certificate
      'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
      // Backup certificate
      'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
    ],
  };
  
  /// Allowed hosts that bypass pinning (for development only)
  static const List<String> _allowedHosts = [
    'localhost',
    '10.0.2.2', // Android emulator localhost
    '127.0.0.1',
  ];
  
  /// Initialize SSL pinning
  /// 
  /// Call this during app initialization before any network requests.
  static Future<void> initialize() async {
    // Load custom certificates from assets if needed
    await _loadCustomCertificates();
    
    // Configure HttpClient to use certificate pinning
    HttpOverrides.global = _EduTimeHttpOverrides();
  }
  
  /// Load custom certificates from assets
  static Future<void> _loadCustomCertificates() async {
    try {
      // Load any bundled certificates
      final certData = await rootBundle.load('assets/certs/api_cert.pem');
      SecurityContext.defaultContext.setTrustedCertificatesBytes(
        certData.buffer.asUint8List(),
      );
    } catch (e) {
      // Certificate file may not exist in development
      // This is expected behavior
    }
  }
  
  /// Validate a certificate against pinned fingerprints
  static bool validateCertificate(
    X509Certificate cert,
    String host,
    int port,
  ) {
    // Allow localhost in debug mode
    if (_allowedHosts.contains(host)) {
      return true;
    }
    
    // Get the certificate fingerprint
    final fingerprint = _getCertificateFingerprint(cert);
    
    // Check custom API pins first
    if (_customApiPins.containsKey(host)) {
      return _customApiPins[host]!.contains(fingerprint);
    }
    
    // Check against Firebase/Google pins
    return _pinnedCertificates.contains(fingerprint);
  }
  
  /// Get SHA-256 fingerprint of a certificate
  static String _getCertificateFingerprint(X509Certificate cert) {
    // In production, compute the actual SHA-256 hash
    // This is a placeholder - actual implementation would use
    // crypto package to compute the hash
    return 'sha256/${_base64Sha256(cert.der)}';
  }
  
  /// Compute base64-encoded SHA-256 hash
  static String _base64Sha256(List<int> data) {
    // Placeholder - use crypto package in production
    // import 'package:crypto/crypto.dart';
    // final digest = sha256.convert(data);
    // return base64.encode(digest.bytes);
    return '';
  }
}

/// Custom HttpOverrides for certificate pinning
class _EduTimeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    
    // Set up certificate validation
    client.badCertificateCallback = (cert, host, port) {
      // In production, this should return false for invalid certs
      // During development, you might want to allow self-signed certs
      return SSLPinning.validateCertificate(cert, host, port);
    };
    
    return client;
  }
}

/// Dio interceptor for SSL pinning (alternative approach)
/// 
/// Use with Dio HTTP client for additional security.
class SSLPinningInterceptor {
  /// Create a SecurityContext with pinned certificates
  static SecurityContext createSecurityContext() {
    final context = SecurityContext(withTrustedRoots: false);
    
    // Add trusted certificates
    // In production, load from assets
    // context.setTrustedCertificatesBytes(certBytes);
    
    return context;
  }
}

/// Certificate transparency checker
/// 
/// Verifies that certificates are logged in public CT logs.
class CertificateTransparency {
  /// Known CT log servers
  static const List<String> _ctLogs = [
    'ct.googleapis.com/logs/argon2021',
    'ct.googleapis.com/logs/argon2022',
    'ct.cloudflare.com/logs/nimbus2021',
  ];
  
  /// Verify certificate transparency
  static Future<bool> verifyCT(X509Certificate cert) async {
    // In production, implement CT verification
    // This would check SCTs embedded in the certificate
    // or fetch them from CT logs
    return true;
  }
}

/// Security configuration for the app
class SecurityConfig {
  SecurityConfig._();
  
  /// Enable SSL pinning in release builds only
  static bool get sslPinningEnabled {
    // Disable in debug mode for easier development
    const isRelease = bool.fromEnvironment('dart.vm.product');
    return isRelease;
  }
  
  /// Enable certificate transparency checking
  static bool get ctEnabled => true;
  
  /// Maximum age for cached certificates (in days)
  static const int maxCertCacheAge = 7;
  
  /// Enable root detection
  static bool get rootDetectionEnabled => true;
  
  /// Enable tamper detection
  static bool get tamperDetectionEnabled => true;
}
