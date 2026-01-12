import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/task_service.dart';
import 'services/app_monitoring_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await storageService.init();
  await notificationService.init();
  await authService.init();
  await taskService.init();
  await appMonitoringService.init();

  
  // Schedule daily reminder if enabled
  if (notificationService.areNotificationsEnabled()) {
    await notificationService.scheduleDailyReminder();
  }
  
  runApp(const EduTimeApp());
}

class EduTimeApp extends StatelessWidget {
  const EduTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EduTime - Control Parental',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          secondary: const Color(0xFF8B5CF6),
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
