import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class ChildDashboard extends StatefulWidget {
  const ChildDashboard({super.key});

  @override
  State<ChildDashboard> createState() => _ChildDashboardState();
}

class _ChildDashboardState extends State<ChildDashboard> {
  final _codeController = TextEditingController();
  bool _isLinking = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _linkWithParent() async {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El código debe tener 6 dígitos')),
      );
      return;
    }

    setState(() => _isLinking = true);

    final error = await authService.connectWithCode(_codeController.text);

    if (mounted) {
      setState(() => _isLinking = false);

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Vinculado exitosamente!')),
        );
        setState(() {}); // Refresh UI
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final isLinked = user?.linkedParentId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Espacio'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // User Header
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'H',
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hola, ${user?.name}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 32),

            if (!isLinked) _buildLinkSection() else _buildTaskSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.link_off, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Vincular con tus Padres',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pídele el código a tus padres para conectar tu cuenta y empezar a recibir tareas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Código de 6 dígitos',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.key),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLinking ? null : _linkWithParent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLinking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text('Conectar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskSection() {
    return Column(
      children: [
        // Status Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Cuenta vinculada correctamente',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Tasks Area (Placeholder)
        const Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          'No tienes tareas pendientes',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        const Text(
          '¡Eres libre de jugar!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
