import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';
import '../services/task_service.dart';
import '../models/study_category.dart';
import '../models/task_model.dart';

class TimerPage extends StatefulWidget {
  final StudyTask? task;
  const TimerPage({super.key, this.task});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  bool _isRunning = false;
  int _seconds = 0;
  Timer? _timer;
  StudyCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // If it's a task, maybe we want to preset something
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() {
      _isRunning = !_isRunning;
    });

    if (_isRunning) {
      _startTimer();
    } else {
      _pauseTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _seconds = 0;
    });
    _timer?.cancel();
  }

  Future<void> _finishSession() async {
    if (_seconds == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡No hay tiempo para guardar!')),
      );
      return;
    }

    _pauseTimer();

    // 1. Save standard study time (1:1 credits)
    await storageService.addStudyTime(
      _seconds,
      categoryId: _selectedCategory?.id,
    );

    // 2. Handle Task Completion
    int bonusCredits = 0;
    if (widget.task != null) {
      // Check if they studied at least 80% of the duration to count as completed
      final targetSeconds = widget.task!.durationMinutes * 60;
      if (_seconds >= targetSeconds * 0.8) {
        await taskService.updateTaskStatus(widget.task!.id, TaskStatus.completed);
        
        // Add bonus reward credits
        bonusCredits = widget.task!.rewardMinutes * 60;
        if (bonusCredits > 0) {
          await storageService.addStudyTime(bonusCredits);
        }
      }
    }

    if (!mounted) return;

    // Show success message
    final earnedTotal = (_seconds + bonusCredits) ~/ 60;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.task != null && bonusCredits > 0
              ? '¡Tarea cumplida! Ganaste $earnedTotal min de tiempo libre (incluye bono)'
              : '¡Genial! Ganaste ${_formatTime()} de créditos',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );

    // Reset and go back
    setState(() {
      _seconds = 0;
      _isRunning = false;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      context.pop(true); // Return completion status
    }
  }

  String _formatTime() {
    final hours = _seconds ~/ 3600;
    final minutes = (_seconds % 3600) ~/ 60;
    final secs = _seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer de Estudio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (_seconds > 0 && !_isRunning) {
              // Ask if they want to save
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('¿Guardar sesión?'),
                  content: const Text(
                    '¿Quieres guardar tu tiempo de estudio?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Descartar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              );

              if (result == true) {
                await _finishSession();
              } else if (mounted) {
                context.pop();
              }
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Task Info Header
            if (widget.task != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.primary),
                ),
                child: Column(
                  children: [
                    const Text('TRABAJANDO EN TAREA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(
                      widget.task!.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Objetivo: ${widget.task!.durationMinutes} min • Bonus: ${widget.task!.rewardMinutes} min',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),

            // Category Selector
            if (_seconds == 0 && !_isRunning && widget.task == null) ...[
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Categoría de estudio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: studyCategories.length,
                        itemBuilder: (context, index) {
                          final category = studyCategories[index];
                          final isSelected = _selectedCategory?.id == category.id;
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 90,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? category.color
                                      : category.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: category.color,
                                    width: isSelected ? 3 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      category.icon,
                                      color: isSelected
                                          ? Colors.white
                                          : category.color,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      category.name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Colors.white
                                            : category.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_selectedCategory != null) ...[
              // Show selected category when timer is running
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedCategory!.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedCategory!.color,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedCategory!.icon,
                        color: _selectedCategory!.color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedCategory!.name,
                        style: TextStyle(
                          color: _selectedCategory!.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Timer Display
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          ],
                        ),
                        border: Border.all(
                          color: _isRunning 
                              ? Colors.green 
                              : Theme.of(context).colorScheme.primary,
                          width: 8,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _formatTime(),
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: _isRunning 
                                ? Colors.green 
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Control Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Start/Pause Button
                        ElevatedButton(
                          onPressed: _toggleTimer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRunning 
                                ? Colors.orange 
                                : Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                          child: Row(
                            children: [
                              Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 28),
                              const SizedBox(width: 8),
                              Text(
                                _isRunning ? 'Pausar' : 'Iniciar',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Reset Button
                        IconButton(
                          onPressed: _resetTimer,
                          icon: const Icon(Icons.refresh),
                          iconSize: 32,
                          color: Theme.of(context).colorScheme.secondary,
                        ),if (_seconds > 0 && !_isRunning) ...[
                          const SizedBox(width: 16),
                          
                          // Finish Button
                          ElevatedButton(
                            onPressed: _finishSession,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Terminar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Info Card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Por cada minuto de estudio, ganas 1 minuto de tiempo libre 🎮',
                      style: TextStyle(
                        color: Colors.green[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
