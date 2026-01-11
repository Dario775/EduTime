import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

part 'monitor_event.dart';
part 'monitor_state.dart';

/// MonitorBloc - Manages app usage monitoring state
/// 
/// Communicates with native Android services via MethodChannel
/// to track app usage and manage the blocking overlay.
class MonitorBloc extends Bloc<MonitorEvent, MonitorState> {
  static const MethodChannel _channel = MethodChannel('com.edutime.app/monitor');
  static const EventChannel _eventChannel = EventChannel('com.edutime.app/monitor_events');
  
  MonitorBloc() : super(const MonitorInitial()) {
    on<MonitorStarted>(_onStarted);
    on<MonitorStopped>(_onStopped);
    on<AppUsageDetected>(_onAppUsageDetected);
    on<OverlayStateChanged>(_onOverlayStateChanged);
    on<TimeBalanceUpdated>(_onTimeBalanceUpdated);
    on<MonitorPermissionRequested>(_onPermissionRequested);
    on<BlockingModeToggled>(_onBlockingModeToggled);
    on<AppWhitelistUpdated>(_onAppWhitelistUpdated);
    
    _setupEventListener();
  }
  
  /// Set up listener for native events
  void _setupEventListener() {
    _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final eventType = event['type'] as String?;
        
        switch (eventType) {
          case 'APP_OPENED':
            add(AppUsageDetected(
              packageName: event['packageName'] as String,
              appName: event['appName'] as String? ?? 'Unknown',
              isBlocked: event['isBlocked'] as bool? ?? false,
            ));
            break;
          case 'OVERLAY_SHOWN':
            add(const OverlayStateChanged(isVisible: true));
            break;
          case 'OVERLAY_HIDDEN':
            add(const OverlayStateChanged(isVisible: false));
            break;
          case 'BALANCE_UPDATED':
            add(TimeBalanceUpdated(
              balanceSeconds: event['balanceSeconds'] as int,
            ));
            break;
        }
      }
    });
  }
  
  Future<void> _onStarted(
    MonitorStarted event,
    Emitter<MonitorState> emit,
  ) async {
    emit(const MonitorLoading());
    
    try {
      // Check permissions first
      final hasAccessibility = await _checkAccessibilityPermission();
      final hasOverlay = await _checkOverlayPermission();
      
      if (!hasAccessibility || !hasOverlay) {
        emit(MonitorPermissionRequired(
          needsAccessibility: !hasAccessibility,
          needsOverlay: !hasOverlay,
        ));
        return;
      }
      
      // Start the monitoring service
      final result = await _channel.invokeMethod<bool>('startMonitoring', {
        'userId': event.userId,
        'blockedApps': event.blockedApps,
        'whitelistedApps': event.whitelistedApps,
      });
      
      if (result == true) {
        emit(MonitorActive(
          userId: event.userId,
          blockedApps: event.blockedApps,
          whitelistedApps: event.whitelistedApps,
          currentBalance: event.initialBalance,
        ));
      } else {
        emit(const MonitorError(message: 'Failed to start monitoring service'));
      }
    } on PlatformException catch (e) {
      emit(MonitorError(message: e.message ?? 'Platform error'));
    }
  }
  
  Future<void> _onStopped(
    MonitorStopped event,
    Emitter<MonitorState> emit,
  ) async {
    try {
      await _channel.invokeMethod<void>('stopMonitoring');
      emit(const MonitorInitial());
    } on PlatformException catch (e) {
      emit(MonitorError(message: e.message ?? 'Failed to stop monitoring'));
    }
  }
  
  Future<void> _onAppUsageDetected(
    AppUsageDetected event,
    Emitter<MonitorState> emit,
  ) async {
    final currentState = state;
    if (currentState is MonitorActive) {
      emit(currentState.copyWith(
        currentApp: event.packageName,
        currentAppName: event.appName,
        isCurrentAppBlocked: event.isBlocked,
      ));
    }
  }
  
  Future<void> _onOverlayStateChanged(
    OverlayStateChanged event,
    Emitter<MonitorState> emit,
  ) async {
    final currentState = state;
    if (currentState is MonitorActive) {
      emit(currentState.copyWith(isOverlayVisible: event.isVisible));
    }
  }
  
  Future<void> _onTimeBalanceUpdated(
    TimeBalanceUpdated event,
    Emitter<MonitorState> emit,
  ) async {
    final currentState = state;
    if (currentState is MonitorActive) {
      emit(currentState.copyWith(currentBalance: event.balanceSeconds));
      
      // Notify native side of balance update
      await _channel.invokeMethod<void>('updateBalance', {
        'balanceSeconds': event.balanceSeconds,
      });
    }
  }
  
  Future<void> _onPermissionRequested(
    MonitorPermissionRequested event,
    Emitter<MonitorState> emit,
  ) async {
    try {
      if (event.requestAccessibility) {
        await _channel.invokeMethod<void>('requestAccessibilityPermission');
      }
      if (event.requestOverlay) {
        await _channel.invokeMethod<void>('requestOverlayPermission');
      }
      
      // Re-check permissions after request
      await Future.delayed(const Duration(milliseconds: 500));
      final hasAccessibility = await _checkAccessibilityPermission();
      final hasOverlay = await _checkOverlayPermission();
      
      if (!hasAccessibility || !hasOverlay) {
        emit(MonitorPermissionRequired(
          needsAccessibility: !hasAccessibility,
          needsOverlay: !hasOverlay,
        ));
      }
    } on PlatformException catch (e) {
      emit(MonitorError(message: e.message ?? 'Permission request failed'));
    }
  }
  
  Future<void> _onBlockingModeToggled(
    BlockingModeToggled event,
    Emitter<MonitorState> emit,
  ) async {
    final currentState = state;
    if (currentState is MonitorActive) {
      try {
        await _channel.invokeMethod<void>('setBlockingEnabled', {
          'enabled': event.isEnabled,
        });
        emit(currentState.copyWith(isBlockingEnabled: event.isEnabled));
      } on PlatformException catch (e) {
        emit(MonitorError(message: e.message ?? 'Failed to toggle blocking'));
      }
    }
  }
  
  Future<void> _onAppWhitelistUpdated(
    AppWhitelistUpdated event,
    Emitter<MonitorState> emit,
  ) async {
    final currentState = state;
    if (currentState is MonitorActive) {
      try {
        await _channel.invokeMethod<void>('updateWhitelist', {
          'blockedApps': event.blockedApps,
          'whitelistedApps': event.whitelistedApps,
        });
        emit(currentState.copyWith(
          blockedApps: event.blockedApps,
          whitelistedApps: event.whitelistedApps,
        ));
      } on PlatformException catch (e) {
        emit(MonitorError(message: e.message ?? 'Failed to update whitelist'));
      }
    }
  }
  
  // ============ Helper Methods ============
  
  Future<bool> _checkAccessibilityPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkAccessibilityPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> _checkOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkOverlayPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
  
  /// Show the blocking overlay manually
  Future<void> showOverlay({
    required String message,
    required int remainingSeconds,
  }) async {
    await _channel.invokeMethod<void>('showOverlay', {
      'message': message,
      'remainingSeconds': remainingSeconds,
    });
  }
  
  /// Hide the blocking overlay
  Future<void> hideOverlay() async {
    await _channel.invokeMethod<void>('hideOverlay');
  }
  
  /// Get list of installed apps
  Future<List<AppInfo>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod<List>('getInstalledApps');
      if (result == null) return [];
      
      return result.map((app) => AppInfo(
        packageName: app['packageName'] as String,
        appName: app['appName'] as String,
        isSystemApp: app['isSystemApp'] as bool? ?? false,
      )).toList();
    } catch (e) {
      return [];
    }
  }
}

/// App info model
class AppInfo {
  final String packageName;
  final String appName;
  final bool isSystemApp;
  
  const AppInfo({
    required this.packageName,
    required this.appName,
    this.isSystemApp = false,
  });
}
