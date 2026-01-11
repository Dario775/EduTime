import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late int _dailyGoal;

  @override
  void initState() {
    super.initState();
    _daily Goal = storageService.getDailyGoal();
  }

  Future<void> _saveDailyGoal(int minutes) async {
    await storageService.setDailyGoal(minutes);
    setState(() {
      _dailyGoal = minutes;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meta guardada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Daily Goal Section
          const Text(
            'Meta Diaria',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuántos minutos quieres estudiar cada día',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          
          // Goal Cards
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [15, 30, 45, 60, 90, 120].map((minutes) {
              final isSelected = _dailyGoal == minutes;
              return _buildGoalCard(
                context,
                minutes,
                isSelected,
                () => _saveDailyGoal(minutes),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 20),
          
          // Custom Goal
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Meta personalizada'),
            subtitle: Text('Actualmente: $_dailyGoal minutos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCustomGoalDialog(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    int minutes,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: (MediaQuery.of(context).size.width - 64) / 3,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$minutes',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'min',
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomGoalDialog() async {
    final controller = TextEditingController(text: _dailyGoal.toString());
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Meta Personalizada'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Minutos',
            suffixText: 'min',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0 && value <= 1440) {
                Navigator.of(context).pop(value);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _saveDailyGoal(result);
    }
  }
}
