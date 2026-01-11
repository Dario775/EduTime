import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '$seconds seg';
    }
    
    final minutes = seconds ~/ 60;
    if (minutes < 60) {
      return '$minutes min';
    }
    
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    
    if (hours < 24) {
      if (remainingMins == 0) {
        return '$hours h';
      }
      return '$hours h $remainingMins m';
    }
    
    final days = hours ~/ 24;
    final remainingHours = hours % 24;
    if (remainingHours == 0) {
      return '$days días';
    }
    return '$days d $remainingHours h';
  }

  @override
  Widget build(BuildContext context) {
    final totalTime = storageService.getTotalStudyTime();
    final credits = storageService.getTotalCredits();
    final streak = storageService.getCurrentStreak();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Estudiante',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  totalTime > 0 
                      ? 'Total: ${_formatTime(totalTime)} estudiados'
                      : 'Comenzá tu primera sesión',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Stats Cards
          _buildStatCard(
            context,
            'Tiempo Estudiado',
            _formatTime(totalTime),
            Icons.school,
            Colors.blue,
          ),
          
          const SizedBox(height: 16),
          
          _buildStatCard(
            context,
            'Créditos Disponibles',
            _formatTime(credits),
            Icons.star,
            Colors.amber,
          ),
          
          const SizedBox(height: 16),
          
          _buildStatCard(
            context,
            'Racha Actual',
            '$streak ${streak == 1 ? "día" : "días"}',
            Icons.local_fire_department,
            Colors.orange,
          ),
          
          const SizedBox(height: 40),
          
          // Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '¿Cómo funciona?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Por cada minuto que estudias, ganan 1 minuto de crédito\n'
                  '• Usa tus créditos para tiempo libre\n'
                  '• Mantén tu racha estudiando cada día',
                  style: TextStyle(
                    color: Colors.green[900],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Settings Section
          const Text(
            'Configuración',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildSettingTile(
            context,
            'Reiniciar Datos',
            Icons.restore,
            () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('⚠️ Confirmar'),
                  content: const Text(
                    '¿Estás seguro? Esto borrará todas tus estadísticas.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Borrar'),
                    ),
                  ],
                ),
              );

              if (result == true) {
                await storageService.reset();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Datos reiniciados'),
                    ),
                  );
                  context.pop();
                }
              }
            },
          ),
          
          const SizedBox(height: 8),
          
          _buildSettingTile(
            context,
            'Acerca de EduTime',
            Icons.info,
            () {
              showAboutDialog(
                context: context,
                applicationName: 'EduTime',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.access_time, size: 48),
                children: [
                  const Text(
                    'App de gestión de tiempo educativo.\n\n'
                    'Estudia para ganar tiempo libre.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}
