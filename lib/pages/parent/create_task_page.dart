import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/task_model.dart';
import '../../services/apps_service.dart';
import '../../services/task_service.dart';
import '../../services/auth_service.dart';

class CreateTaskPage extends StatefulWidget {
  final AppUser child;

  const CreateTaskPage({super.key, required this.child});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _rewardController = TextEditingController();
  
  List<AppInfo> _availableApps = [];
  List<String> _selectedApps = [];
  bool _isLoadingApps = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await appsService.getInstalledApps();
    if (mounted) {
      setState(() {
        _availableApps = apps;
        _isLoadingApps = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    if (_titleController.text.isEmpty || _durationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa título y duración')),
      );
      return;
    }

    final task = StudyTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      durationMinutes: int.tryParse(_durationController.text) ?? 30,
      parentId: authService.currentUser!.uid,
      childId: widget.child.uid,
      createdAt: DateTime.now(),
      rewardMinutes: int.tryParse(_rewardController.text) ?? 0,
      allowedApps: _selectedApps,
    );

    await taskService.createTask(task);
    
    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarea creada exitosamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tarea para ${widget.child.name}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Task Info
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título de la Tarea',
                hintText: 'Ej: Estudiar Matemáticas',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duración',
                      suffixText: 'min',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _rewardController,
                    decoration: const InputDecoration(
                      labelText: 'Recompensa',
                      suffixText: 'min',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Apps Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Apps Permitidas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedApps.isNotEmpty)
                  Text(
                    '${_selectedApps.length} seleccionadas',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Selecciona las apps que el hijo puede usar para esta tarea',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 16),

            // Apps List
            if (_isLoadingApps)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_availableApps.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No se encontraron apps instaladas'),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableApps.length,
                  itemBuilder: (context, index) {
                    final app = _availableApps[index];
                    final isSelected = _selectedApps.contains(app.packageName);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedApps.add(app.packageName);
                          } else {
                            _selectedApps.remove(app.packageName);
                          }
                        });
                      },
                      title: Text(app.appName),
                      subtitle: Text(
                        app.packageName,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      secondary: const Icon(Icons.apps),
                    );
                  },
                ),
              ),

            const SizedBox(height: 32),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Crear Tarea',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
