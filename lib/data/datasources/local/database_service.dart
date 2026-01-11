import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../../../core/security/encryption_service.dart';
import 'schemas/wallet_schema.dart';
import 'schemas/user_profile_schema.dart';
import 'schemas/family_config_schema.dart';
import 'schemas/study_session_schema.dart';
import 'schemas/subject_schema.dart';

/// Database Service
/// 
/// Manages Isar database initialization with encryption.
/// Uses Android Keystore / iOS Keychain for secure key storage.
class DatabaseService {
  static DatabaseService? _instance;
  static Isar? _isar;
  
  final EncryptionService _encryptionService;
  
  DatabaseService._({required EncryptionService encryptionService})
      : _encryptionService = encryptionService;
  
  /// Get singleton instance
  static DatabaseService getInstance(EncryptionService encryptionService) {
    _instance ??= DatabaseService._(encryptionService: encryptionService);
    return _instance!;
  }
  
  /// Get Isar instance (throws if not initialized)
  Isar get isar {
    if (_isar == null) {
      throw StateError(
        'Database not initialized. Call initialize() first.',
      );
    }
    return _isar!;
  }
  
  /// Check if database is initialized
  bool get isInitialized => _isar != null;
  
  /// Initialize the encrypted Isar database
  /// 
  /// This should be called during app startup, after user authentication
  /// to ensure the encryption key is properly set up.
  Future<Isar> initialize() async {
    if (_isar != null) {
      return _isar!;
    }
    
    try {
      // Get the application documents directory
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = '${dir.path}/edutime_db';
      
      // Get or create encryption key from secure storage
      final encryptionKey = await _encryptionService.getOrCreateEncryptionKey();
      
      debugPrint('DatabaseService: Initializing encrypted Isar database...');
      
      // Open Isar with encryption
      _isar = await Isar.open(
        [
          WalletSchemaSchema,
          TransactionSchemaSchema,
          UserProfileSchemaSchema,
          FamilyConfigSchemaSchema,
          StudySessionSchemaSchema,
          SubjectSchemaSchema,
        ],
        directory: dbPath,
        name: 'edutime',
        encryptionKey: encryptionKey.toList(),
        inspector: kDebugMode, // Enable inspector in debug mode
      );
      
      debugPrint('DatabaseService: Database initialized successfully');
      
      return _isar!;
    } catch (e) {
      debugPrint('DatabaseService: Error initializing database: $e');
      rethrow;
    }
  }
  
  /// Close the database
  Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
      debugPrint('DatabaseService: Database closed');
    }
  }
  
  /// Clear all data (for logout or data reset)
  Future<void> clearAllData() async {
    if (_isar == null) return;
    
    await _isar!.writeTxn(() async {
      await _isar!.clear();
    });
    
    debugPrint('DatabaseService: All data cleared');
  }
  
  /// Delete database and encryption key (complete reset)
  Future<void> deleteDatabase() async {
    await close();
    await _encryptionService.deleteEncryptionKey();
    
    // Delete the database files
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/edutime_db';
    
    try {
      await Isar.getInstance('edutime')?.close(deleteFromDisk: true);
    } catch (e) {
      debugPrint('DatabaseService: Error deleting database files: $e');
    }
    
    debugPrint('DatabaseService: Database deleted completely');
  }
  
  /// Get database size in bytes
  Future<int> getDatabaseSize() async {
    if (_isar == null) return 0;
    
    // Sum up all collection sizes
    var totalSize = 0;
    totalSize += await _isar!.walletSchemas.getSize(
      includeIndexes: true,
      includeLinks: true,
    );
    totalSize += await _isar!.transactionSchemas.getSize(
      includeIndexes: true,
      includeLinks: true,
    );
    totalSize += await _isar!.userProfileSchemas.getSize(
      includeIndexes: true,
      includeLinks: true,
    );
    totalSize += await _isar!.familyConfigSchemas.getSize(
      includeIndexes: true,
      includeLinks: true,
    );
    totalSize += await _isar!.studySessionSchemas.getSize(
      includeIndexes: true,
      includeLinks: true,
    );
    totalSize += await _isar!.subjectSchemas.getSize(
      includeIndexes: true,
      includeLinks: true,
    );
    
    return totalSize;
  }
  
  /// Get formatted database size
  Future<String> getFormattedDatabaseSize() async {
    final bytes = await getDatabaseSize();
    
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
