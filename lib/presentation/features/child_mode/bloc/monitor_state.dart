part of 'monitor_bloc.dart';

/// Monitor States
sealed class MonitorState extends Equatable {
  const MonitorState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state - monitoring not started
class MonitorInitial extends MonitorState {
  const MonitorInitial();
}

/// Loading state - starting/stopping monitoring
class MonitorLoading extends MonitorState {
  const MonitorLoading();
}

/// Permissions required before monitoring can start
class MonitorPermissionRequired extends MonitorState {
  final bool needsAccessibility;
  final bool needsOverlay;
  
  const MonitorPermissionRequired({
    required this.needsAccessibility,
    required this.needsOverlay,
  });
  
  @override
  List<Object?> get props => [needsAccessibility, needsOverlay];
}

/// Active monitoring state
class MonitorActive extends MonitorState {
  final String userId;
  final List<String> blockedApps;
  final List<String> whitelistedApps;
  final int currentBalance;
  final String? currentApp;
  final String? currentAppName;
  final bool isCurrentAppBlocked;
  final bool isOverlayVisible;
  final bool isBlockingEnabled;
  
  const MonitorActive({
    required this.userId,
    this.blockedApps = const [],
    this.whitelistedApps = const [],
    this.currentBalance = 0,
    this.currentApp,
    this.currentAppName,
    this.isCurrentAppBlocked = false,
    this.isOverlayVisible = false,
    this.isBlockingEnabled = true,
  });
  
  MonitorActive copyWith({
    String? userId,
    List<String>? blockedApps,
    List<String>? whitelistedApps,
    int? currentBalance,
    String? currentApp,
    String? currentAppName,
    bool? isCurrentAppBlocked,
    bool? isOverlayVisible,
    bool? isBlockingEnabled,
  }) {
    return MonitorActive(
      userId: userId ?? this.userId,
      blockedApps: blockedApps ?? this.blockedApps,
      whitelistedApps: whitelistedApps ?? this.whitelistedApps,
      currentBalance: currentBalance ?? this.currentBalance,
      currentApp: currentApp ?? this.currentApp,
      currentAppName: currentAppName ?? this.currentAppName,
      isCurrentAppBlocked: isCurrentAppBlocked ?? this.isCurrentAppBlocked,
      isOverlayVisible: isOverlayVisible ?? this.isOverlayVisible,
      isBlockingEnabled: isBlockingEnabled ?? this.isBlockingEnabled,
    );
  }
  
  /// Get formatted balance string
  String get formattedBalance {
    final hours = currentBalance ~/ 3600;
    final minutes = (currentBalance % 3600) ~/ 60;
    final seconds = currentBalance % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
  
  /// Check if balance is low (less than 5 minutes)
  bool get isBalanceLow => currentBalance < 300;
  
  /// Check if balance is critical (less than 1 minute)
  bool get isBalanceCritical => currentBalance < 60;
  
  @override
  List<Object?> get props => [
    userId,
    blockedApps,
    whitelistedApps,
    currentBalance,
    currentApp,
    currentAppName,
    isCurrentAppBlocked,
    isOverlayVisible,
    isBlockingEnabled,
  ];
}

/// Error state
class MonitorError extends MonitorState {
  final String message;
  
  const MonitorError({required this.message});
  
  @override
  List<Object?> get props => [message];
}
