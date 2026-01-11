part of 'monitor_bloc.dart';

/// Monitor Events
sealed class MonitorEvent extends Equatable {
  const MonitorEvent();
  
  @override
  List<Object?> get props => [];
}

/// Start monitoring with configuration
class MonitorStarted extends MonitorEvent {
  final String userId;
  final List<String> blockedApps;
  final List<String> whitelistedApps;
  final int initialBalance;
  
  const MonitorStarted({
    required this.userId,
    this.blockedApps = const [],
    this.whitelistedApps = const [],
    this.initialBalance = 0,
  });
  
  @override
  List<Object?> get props => [userId, blockedApps, whitelistedApps, initialBalance];
}

/// Stop monitoring
class MonitorStopped extends MonitorEvent {
  const MonitorStopped();
}

/// App usage detected by accessibility service
class AppUsageDetected extends MonitorEvent {
  final String packageName;
  final String appName;
  final bool isBlocked;
  
  const AppUsageDetected({
    required this.packageName,
    required this.appName,
    this.isBlocked = false,
  });
  
  @override
  List<Object?> get props => [packageName, appName, isBlocked];
}

/// Overlay visibility changed
class OverlayStateChanged extends MonitorEvent {
  final bool isVisible;
  
  const OverlayStateChanged({required this.isVisible});
  
  @override
  List<Object?> get props => [isVisible];
}

/// Time balance updated
class TimeBalanceUpdated extends MonitorEvent {
  final int balanceSeconds;
  
  const TimeBalanceUpdated({required this.balanceSeconds});
  
  @override
  List<Object?> get props => [balanceSeconds];
}

/// Request permissions
class MonitorPermissionRequested extends MonitorEvent {
  final bool requestAccessibility;
  final bool requestOverlay;
  
  const MonitorPermissionRequested({
    this.requestAccessibility = false,
    this.requestOverlay = false,
  });
  
  @override
  List<Object?> get props => [requestAccessibility, requestOverlay];
}

/// Toggle blocking mode
class BlockingModeToggled extends MonitorEvent {
  final bool isEnabled;
  
  const BlockingModeToggled({required this.isEnabled});
  
  @override
  List<Object?> get props => [isEnabled];
}

/// Update app whitelist
class AppWhitelistUpdated extends MonitorEvent {
  final List<String> blockedApps;
  final List<String> whitelistedApps;
  
  const AppWhitelistUpdated({
    required this.blockedApps,
    required this.whitelistedApps,
  });
  
  @override
  List<Object?> get props => [blockedApps, whitelistedApps];
}
