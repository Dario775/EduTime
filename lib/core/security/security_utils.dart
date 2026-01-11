import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Security utilities for app hardening
/// 
/// Provides:
/// - Root/jailbreak detection
/// - Emulator detection
/// - App tampering detection
/// - Debug detection
class SecurityUtils {
  SecurityUtils._();
  
  static const _channel = MethodChannel('com.edutime.app/security');
  
  /// Check if device is rooted/jailbroken
  static Future<bool> isDeviceRooted() async {
    if (kDebugMode) return false; // Skip in debug
    
    try {
      if (Platform.isAndroid) {
        return await _checkAndroidRoot();
      } else if (Platform.isIOS) {
        return await _checkiOSJailbreak();
      }
    } catch (e) {
      // Assume not rooted if check fails
      return false;
    }
    return false;
  }
  
  /// Check for Android root
  static Future<bool> _checkAndroidRoot() async {
    // Check for common root indicators
    final suPaths = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
      '/su/bin/su',
    ];
    
    for (final path in suPaths) {
      if (await File(path).exists()) {
        return true;
      }
    }
    
    // Check for Magisk
    if (await File('/sbin/.magisk').exists()) {
      return true;
    }
    
    // Try to execute su
    try {
      final result = await Process.run('su', ['-c', 'id']);
      if (result.exitCode == 0) {
        return true;
      }
    } catch (e) {
      // Expected to fail on non-rooted devices
    }
    
    return false;
  }
  
  /// Check for iOS jailbreak
  static Future<bool> _checkiOSJailbreak() async {
    final jailbreakPaths = [
      '/Applications/Cydia.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/private/var/lib/apt/',
    ];
    
    for (final path in jailbreakPaths) {
      if (await File(path).exists()) {
        return true;
      }
    }
    
    // Check if we can write outside sandbox
    try {
      final file = File('/private/test_jailbreak.txt');
      await file.writeAsString('test');
      await file.delete();
      return true; // If we can write here, device is jailbroken
    } catch (e) {
      // Expected to fail on non-jailbroken devices
    }
    
    return false;
  }
  
  /// Check if running on emulator
  static Future<bool> isEmulator() async {
    if (kDebugMode) return false; // Allow emulator in debug
    
    try {
      if (Platform.isAndroid) {
        return await _checkAndroidEmulator();
      } else if (Platform.isIOS) {
        return await _checkiOSSimulator();
      }
    } catch (e) {
      return false;
    }
    return false;
  }
  
  /// Check for Android emulator
  static Future<bool> _checkAndroidEmulator() async {
    try {
      final result = await _channel.invokeMethod<bool>('isEmulator');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
  
  /// Check for iOS simulator
  static Future<bool> _checkiOSSimulator() async {
    // Check for simulator environment
    final env = Platform.environment;
    if (env.containsKey('SIMULATOR_DEVICE_NAME')) {
      return true;
    }
    return false;
  }
  
  /// Check if app has been tampered
  static Future<bool> isAppTampered() async {
    if (kDebugMode) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('verifySignature');
      return !(result ?? true);
    } catch (e) {
      // If check fails, assume not tampered
      return false;
    }
  }
  
  /// Check if debugger is attached
  static bool isDebuggerAttached() {
    // Check for assert mode (debug builds)
    bool debugMode = false;
    assert(() {
      debugMode = true;
      return true;
    }());
    return debugMode;
  }
  
  /// Perform all security checks
  static Future<SecurityCheckResult> performSecurityCheck() async {
    final isRooted = await isDeviceRooted();
    final isEmulatorDevice = await isEmulator();
    final isTampered = await isAppTampered();
    final isDebugged = isDebuggerAttached();
    
    return SecurityCheckResult(
      isRooted: isRooted,
      isEmulator: isEmulatorDevice,
      isTampered: isTampered,
      isDebugged: isDebugged,
    );
  }
  
  /// Handle security violation
  static void handleSecurityViolation(SecurityCheckResult result) {
    if (result.hasViolation) {
      // Log the violation (in production, send to analytics)
      debugPrint('Security violation detected: ${result.violations}');
      
      // In production, you might want to:
      // - Disable sensitive features
      // - Show warning to user
      // - Terminate the app
    }
  }
}

/// Result of security checks
class SecurityCheckResult {
  final bool isRooted;
  final bool isEmulator;
  final bool isTampered;
  final bool isDebugged;
  
  const SecurityCheckResult({
    required this.isRooted,
    required this.isEmulator,
    required this.isTampered,
    required this.isDebugged,
  });
  
  /// Check if any security violation was detected
  bool get hasViolation => isRooted || isEmulator || isTampered || isDebugged;
  
  /// Get list of violations
  List<String> get violations {
    final v = <String>[];
    if (isRooted) v.add('ROOTED_DEVICE');
    if (isEmulator) v.add('EMULATOR');
    if (isTampered) v.add('TAMPERED_APP');
    if (isDebugged) v.add('DEBUGGER_ATTACHED');
    return v;
  }
}

/// Data encryption utilities
class DataEncryption {
  DataEncryption._();
  
  /// Encrypt sensitive data before storage
  static Future<String> encrypt(String data, String key) async {
    // Use platform-specific secure encryption
    // This is a placeholder - implement with EncryptionService
    throw UnimplementedError('Use EncryptionService for encryption');
  }
  
  /// Decrypt data
  static Future<String> decrypt(String encryptedData, String key) async {
    throw UnimplementedError('Use EncryptionService for decryption');
  }
}

/// Secure storage for sensitive data
class SecureDataStore {
  SecureDataStore._();
  
  static const _channel = MethodChannel('com.edutime.app/encryption');
  
  /// Store sensitive data securely
  static Future<void> store(String key, String value) async {
    await _channel.invokeMethod('storeKey', {
      'alias': key,
      'key': value.codeUnits,
    });
  }
  
  /// Retrieve sensitive data
  static Future<String?> retrieve(String key) async {
    try {
      final result = await _channel.invokeMethod<List<int>>('getKey', {
        'alias': key,
      });
      if (result != null) {
        return String.fromCharCodes(result);
      }
    } catch (e) {
      return null;
    }
    return null;
  }
  
  /// Delete sensitive data
  static Future<void> delete(String key) async {
    await _channel.invokeMethod('deleteKey', {'alias': key});
  }
}
