import 'package:flutter/material.dart';
import 'router/app_router.dart';

void main() {
  runApp(const EduTimeApp());
}

class EduTimeApp extends StatelessWidget {
  const EduTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EduTime',
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
