import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class ChildDashboard extends StatelessWidget {
  const ChildDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              '¡Hola, ${user?.name}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dashboard del Hijo',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              '(En construcción)',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
