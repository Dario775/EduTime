import 'package:isar/isar.dart';

part 'wallet_schema.g.dart';

/// Wallet Isar Schema
/// 
/// Stores user's earned time balance locally.
/// Syncs bidirectionally with Firestore.
@collection
class WalletSchema {
  Id id = Isar.autoIncrement;
  
  /// User ID (matches Firebase Auth UID)
  @Index(unique: true)
  late String odexUserId;

  /// Current balance in seconds
  late int balanceSeconds;
  
  /// Total time earned since account creation (in seconds)
  late int lifetimeEarned;
  
  /// Total time spent since account creation (in seconds)
  late int lifetimeSpent;
  
  /// Last transaction timestamp (milliseconds since epoch)
  int? lastTransactionAt;
  
  /// Wallet creation timestamp (milliseconds since epoch)
  late int createdAt;
  
  /// Last update timestamp (milliseconds since epoch)
  late int updatedAt;
  
  /// Sync status with Firestore
  @enumerated
  late SyncStatus syncStatus;
  
  /// Last sync timestamp (milliseconds since epoch)
  int? lastSyncAt;
  
  /// Pending sync operations count
  late int pendingSyncOps;
  
  /// Create a new wallet with default values
  static WalletSchema createDefault(String odexUserId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return WalletSchema()
      ..odexUserId = odexUserId
      ..balanceSeconds = 0
      ..lifetimeEarned = 0
      ..lifetimeSpent = 0
      ..lastTransactionAt = null
      ..createdAt = now
      ..updatedAt = now
      ..syncStatus = SyncStatus.synced
      ..lastSyncAt = null
      ..pendingSyncOps = 0;
  }
  
  /// Get formatted balance string
  String get formattedBalance {
    final hours = balanceSeconds ~/ 3600;
    final minutes = (balanceSeconds % 3600) ~/ 60;
    final seconds = balanceSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
  
  /// Check if enough balance for spending
  bool canSpend(int amountSeconds) {
    return balanceSeconds >= amountSeconds && amountSeconds > 0;
  }
  
  /// Add earned time
  void addEarnings(int seconds) {
    balanceSeconds += seconds;
    lifetimeEarned += seconds;
    lastTransactionAt = DateTime.now().millisecondsSinceEpoch;
    updatedAt = DateTime.now().millisecondsSinceEpoch;
    syncStatus = SyncStatus.pendingUpload;
    pendingSyncOps++;
  }
  
  /// Spend time (returns false if insufficient balance)
  bool spend(int seconds) {
    if (!canSpend(seconds)) return false;
    
    balanceSeconds -= seconds;
    lifetimeSpent += seconds;
    lastTransactionAt = DateTime.now().millisecondsSinceEpoch;
    updatedAt = DateTime.now().millisecondsSinceEpoch;
    syncStatus = SyncStatus.pendingUpload;
    pendingSyncOps++;
    return true;
  }
}

/// Transaction Isar Schema
@collection
class TransactionSchema {
  Id id = Isar.autoIncrement;
  
  /// Firebase document ID (for sync)
  @Index()
  String? firestoreId;
  
  /// Associated wallet/user ID
  @Index()
  late String odexUserId;
  
  /// Transaction type
  @enumerated
  late TransactionType type;
  
  /// Amount in seconds (positive for earn, negative for spend)
  late int amountSeconds;
  
  /// Balance after this transaction
  late int balanceAfter;
  
  /// Description of the transaction
  late String description;
  
  /// Related session ID (if applicable)
  String? sessionId;
  
  /// Related subject ID (if applicable)
  String? subjectId;
  
  /// User who initiated the transaction (for adjustments)
  String? initiatedBy;
  
  /// Transaction timestamp (milliseconds since epoch)
  late int createdAt;
  
  /// Sync status
  @enumerated
  late SyncStatus syncStatus;
}

/// Transaction types enum
enum TransactionType {
  earn,
  spend,
  adjustment,
  bonus,
  penalty,
}

/// Sync status enum for offline-first architecture
enum SyncStatus {
  /// Fully synced with server
  synced,
  
  /// Has local changes pending upload
  pendingUpload,
  
  /// Has server changes pending download
  pendingDownload,
  
  /// Conflict detected (needs resolution)
  conflict,
  
  /// Sync error occurred
  error,
}
