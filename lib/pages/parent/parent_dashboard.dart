import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../models/user_model.dart';
import '../../models/task_model.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  List<AppUser> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final user = authService.currentUser;
    if (user != null) {
      final children = await authService.getChildren(user.uid);
      if (mounted) {
        setState(() {
          _children = children;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showConnectionCode() async {
    final code = await authService.generateConnectionCode();
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vincular Hijo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pídele a tu hijo que ingrese este código en su dispositivo:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                code,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Este código es válido mientras mantengas esta sesión activa.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copiar'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Código copiado al portapapeles')),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChildren,
          ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            child: Text(user?.name.substring(0, 1).toUpperCase() ?? 'P'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hola, ${user?.name}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('Administra el tiempo de tus hijos'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Overall Statistics
                  if (_children.isNotEmpty) _buildOverallStatistics(),

                  const SizedBox(height: 24),

                  // Children Section with Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mis Hijos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _showConnectionCode,
                        icon: const Icon(Icons.add),
                        label: const Text('Vincular'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (_children.isEmpty)
                    _buildEmptyState()
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _children.length,
                      itemBuilder: (context, index) {
                        final child = _children[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(child.name.substring(0, 1).toUpperCase()),
                            ),
                            title: Text(child.name),
                            subtitle: Text(child.email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add_task),
                                  onPressed: () => _showCreateTaskDialog(child),
                                  tooltip: 'Asignar Tarea',
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () {
                              _showChildTasks(child);
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _showCreateTaskDialog(AppUser child) async {
    final titleController = TextEditingController();
    final durationController = TextEditingController();
    final rewardController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tarea para ${child.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Materia / Título',
                hintText: 'Ej: Matemáticas, Lectura',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: durationController,
              decoration: const InputDecoration(
                labelText: 'Duración (minutos)',
                suffixText: 'min',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rewardController,
              decoration: const InputDecoration(
                labelText: 'Recompensa (tiempo libre)',
                suffixText: 'min',
                helperText: 'Minutos de ocio regalados al terminar',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || durationController.text.isEmpty) return;

              final task = StudyTask(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleController.text,
                durationMinutes: int.tryParse(durationController.text) ?? 30,
                parentId: authService.currentUser!.uid,
                childId: child.uid,
                createdAt: DateTime.now(),
                rewardMinutes: int.tryParse(rewardController.text) ?? 0,
              );

              await taskService.createTask(task);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tarea asignada exitosamente')),
                );
              }
            },
            child: const Text('Asignar'),
          ),
        ],
      ),
    );
  }

  void _showChildTasks(AppUser child) async {
    final tasks = await taskService.getTasksForChild(child.uid);
    
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Tareas de ${child.name}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            if (tasks.isEmpty)
              const Expanded(child: Center(child: Text('No hay tareas asignadas')))
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ListTile(
                      leading: Icon(
                        task.status == TaskStatus.completed
                            ? Icons.check_circle
                            : Icons.pending_actions,
                        color: task.status == TaskStatus.completed ? Colors.green : Colors.orange,
                      ),
                      title: Text(task.title),
                      subtitle: Text('${task.durationMinutes} min • Recompensa: ${task.rewardMinutes} min'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          await taskService.deleteTask(task.id);
                          Navigator.pop(context);
                          _showChildTasks(child); // Reload
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStatistics() {
    return FutureBuilder<Map<String, int>>(
      future: _calculateOverallStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas Generales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.assignment,
                    title: 'Tareas Totales',
                    value: '${stats['totalTasks']}',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle,
                    title: 'Completadas',
                    value: '${stats['completedTasks']}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.schedule,
                    title: 'Tiempo Estudiado',
                    value: '${stats['totalStudyMinutes']} min',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.star,
                    title: 'Créditos Ganados',
                    value: '${stats['totalRewardMinutes']} min',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>> _calculateOverallStats() async {
    int totalTasks = 0;
    int completedTasks = 0;
    int totalStudyMinutes = 0;
    int totalRewardMinutes = 0;

    for (final child in _children) {
      final stats = await taskService.getChildStatistics(child.uid);
      totalTasks += stats['totalTasks'] as int;
      completedTasks += stats['completedTasks'] as int;
      totalStudyMinutes += stats['totalStudyMinutes'] as int;
      totalRewardMinutes += stats['totalRewardMinutes'] as int;
    }

    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'totalStudyMinutes': totalStudyMinutes,
      'totalRewardMinutes': totalRewardMinutes,
    };
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.child_care, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tienes hijos vinculados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón "Vincular" para generar un código y agregarlos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
