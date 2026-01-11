import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Encryption Service using Android Keystore
/// 
/// Provides secure key generation and storage using the platform's
/// secure enclave (Android Keystore / iOS Keychain).
/// 
/// For Isar database encryption, a 256-bit AES key is generated
/// and stored securely using platform-specific secure storage.
class EncryptionService {
  static const String _keyAlias = 'edutime_isar_encryption_key';
  static const String _keyPrefsKey = 'encrypted_key_check';
  static const int _keyLengthBytes = 32; // 256 bits for AES-256
  
  // Platform channel for native secure storage
  static const MethodChannel _channel = MethodChannel(
    'com.edutime.app/encryption',
  );
  
  final SharedPreferences _prefs;
  Uint8List? _cachedKey;
  
  EncryptionService({required SharedPreferences prefs}) : _prefs = prefs;
  
  /// Get or generate the Isar encryption key
  /// 
  /// Returns a 32-byte key suitable for AES-256 encryption.
  /// The key is generated once and stored securely in the platform's
  /// secure storage (Android Keystore / iOS Keychain).
  Future<Uint8List> getOrCreateEncryptionKey() async {
    // Return cached key if available
    if (_cachedKey != null) {
      return _cachedKey!;
    }
    
    try {
      // Try to retrieve existing key from secure storage
      final existingKey = await _retrieveKeyFromSecureStorage();
      if (existingKey != null) {
        _cachedKey = existingKey;
        return existingKey;
      }
      
      // Generate new key if none exists
      final newKey = _generateSecureKey();
      await _storeKeyInSecureStorage(newKey);
      _cachedKey = newKey;
      
      // Mark that key has been generated
      await _prefs.setBool(_keyPrefsKey, true);
      
      return newKey;
    } catch (e) {
      // Fallback for platforms without secure storage (web, tests)
      debugPrint('EncryptionService: Using fallback key storage: $e');
      return _getFallbackKey();
    }
  }
  
  /// Check if an encryption key exists
  Future<bool> hasEncryptionKey() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'hasKey',
        {'alias': _keyAlias},
      );
      return result ?? false;
    } catch (e) {
      // Check fallback
      return _prefs.containsKey(_keyPrefsKey);
    }
  }
  
  /// Delete the encryption key (WARNING: data will be unrecoverable)
  Future<void> deleteEncryptionKey() async {
    try {
      await _channel.invokeMethod<void>(
        'deleteKey',
        {'alias': _keyAlias},
      );
    } catch (e) {
      debugPrint('EncryptionService: Error deleting key: $e');
    }
    
    _cachedKey = null;
    await _prefs.remove(_keyPrefsKey);
    await _prefs.remove('${_keyAlias}_fallback');
  }
  
  /// Generate a cryptographically secure random key
  Uint8List _generateSecureKey() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_keyLengthBytes, (_) => random.nextInt(256)),
    );
  }
  
  /// Retrieve key from Android Keystore / iOS Keychain
  Future<Uint8List?> _retrieveKeyFromSecureStorage() async {
    try {
      final result = await _channel.invokeMethod<Uint8List>(
        'getKey',
        {'alias': _keyAlias},
      );
      return result;
    } on PlatformException catch (e) {
      if (e.code == 'KEY_NOT_FOUND') {
        return null;
      }
      rethrow;
    }
  }
  
  /// Store key in Android Keystore / iOS Keychain
  Future<void> _storeKeyInSecureStorage(Uint8List key) async {
    await _channel.invokeMethod<void>(
      'storeKey',
      {
        'alias': _keyAlias,
        'key': key,
      },
    );
  }
  
  /// Fallback key storage for platforms without secure storage
  /// Uses SharedPreferences with base64 encoding (less secure)
  Future<Uint8List> _getFallbackKey() async {
    final fallbackKey = _prefs.getString('${_keyAlias}_fallback');
    
    if (fallbackKey != null) {
      _cachedKey = base64Decode(fallbackKey);
      return _cachedKey!;
    }
    
    // Generate and store new fallback key
    final newKey = _generateSecureKey();
    await _prefs.setString('${_keyAlias}_fallback', base64Encode(newKey));
    await _prefs.setBool(_keyPrefsKey, true);
    
    _cachedKey = newKey;
    return newKey;
  }
  
  /// Clear cached key from memory
  void clearCache() {
    _cachedKey = null;
  }
}

/// Extension to convert Uint8List to hex string for debugging
extension Uint8ListExtension on Uint8List {
  String toHexString() {
    return map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
