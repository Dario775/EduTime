import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

class TaskService {
  static const String _keyTasks = 'study_tasks';
  
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<StudyTask>> _getAllTasks() async {
    final tasksJson = _prefs.getString(_keyTasks);
    if (tasksJson == null) return [];
    
    try {
      final List<dynamic> list = json.decode(tasksJson) as List<dynamic>;
      return list.map((map) => StudyTask.fromMap(map as Map<String, dynamic>, map['id'] as String? ?? 'unknown')).toList();
    } catch (e) {
      print('Error getting all tasks: $e');
      return [];
    }
  }

  Future<void> _saveAllTasks(List<StudyTask> tasks) async {
    final list = tasks.map((t) => {...t.toMap(), 'id': t.id}).toList();
    await _prefs.setString(_keyTasks, json.encode(list));
  }

  // Create new task
  Future<void> createTask(StudyTask task) async {
    final tasks = await _getAllTasks();
    tasks.add(task);
    await _saveAllTasks(tasks);
  }

  // Get tasks for a specific child
  Future<List<StudyTask>> getTasksForChild(String childId) async {
    final tasks = await _getAllTasks();
    return tasks.where((t) => t.childId == childId).toList();
  }

  // Get tasks created by a specific parent
  Future<List<StudyTask>> getTasksByParent(String parentId) async {
    final tasks = await _getAllTasks();
    return tasks.where((t) => t.parentId == parentId).toList();
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final tasks = await _getAllTasks();
    final index = tasks.indexWhere((t) => t.id == taskId);
    
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(
        status: status,
        completedAt: status == TaskStatus.completed ? DateTime.now() : null,
      );
      await _saveAllTasks(tasks);
    }
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    final tasks = await _getAllTasks();
    tasks.removeWhere((t) => t.id == taskId);
    await _saveAllTasks(tasks);
  }
}

// Global instance
final taskService = TaskService();
