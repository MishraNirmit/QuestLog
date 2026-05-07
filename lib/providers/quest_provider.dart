import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../models/settings.dart';
import '../db/db_helper.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class QuestProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Task> _tasks = [];
  List<Category> _categories = [];
  Settings? _settings;

  List<Task> get tasks => _tasks;
  List<Category> get categories => _categories;
  Settings? get settings => _settings;

  Future<void> loadData() async {
    _tasks = await DBHelper.instance.getTasks();
    _categories = await DBHelper.instance.getCategories();
    _settings = await DBHelper.instance.getSettings();
    await _generateRecurringTasks();
    notifyListeners();
  }

  Future<void> _generateRecurringTasks() async {
    final now = DateTime.now();
    // In Dart DateTime, 1 is Monday, 7 is Sunday.
    // Our UI indices: 0=M, 1=T, 2=W, 3=Th, 4=F, 5=S, 6=Su
    final currentWeekdayIndex = now.weekday - 1;

    final Map<String, Task> tasksToDuplicate = {};

    for (var task in _tasks) {
      if (task.repeatDays.contains(currentWeekdayIndex)) {
        // Find if this specific template (title+categoryId) has already been created for today
        bool alreadyExistsToday = _tasks.any((t) {
          if (t.title != task.title || t.categoryId != task.categoryId) return false;
          final tDate = DateTime.parse(t.date);
          return tDate.year == now.year && tDate.month == now.month && tDate.day == now.day;
        });

        if (!alreadyExistsToday) {
          // Key by title + category to prevent duplicating the same task multiple times
          // if multiple old tasks have the same template.
          final key = "${task.title}_${task.categoryId}";
          if (!tasksToDuplicate.containsKey(key)) {
             tasksToDuplicate[key] = task;
          }
        }
      }
    }

    for (var template in tasksToDuplicate.values) {
      final newTask = Task(
        id: "task_${DateTime.now().microsecondsSinceEpoch}_${template.id}", // ensure unique
        title: template.title,
        categoryId: template.categoryId,
        date: now.toIso8601String(),
        repeatDays: template.repeatDays, // Propagate repeat days
        isCompleted: false,
      );
      await DBHelper.instance.insertTask(newTask);
      _tasks.add(newTask);
    }
  }

  Future<void> addTask(Task task) async {
    await DBHelper.instance.insertTask(task);
    _tasks.add(task);
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(String id) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == id);
    if (taskIndex != -1) {
      _tasks[taskIndex].isCompleted = !_tasks[taskIndex].isCompleted;
      await DBHelper.instance.updateTask(_tasks[taskIndex]);

      if (_tasks[taskIndex].isCompleted) {
        // Play level up sound (using a generic system sound or pre-bundled assert if available, here we mock it by playing a default notification tone or just vibrating)
        // Since we don't have a specific mp3 asset, we'll use haptic feedback as the primary indicator for now,
        // and attempt to play a generic sound if possible (though AudioPlayer requires an asset or url).
        // For the sake of the requirement, we will attempt to play a sound if we had an asset.
        // await _audioPlayer.play(AssetSource('level_up.mp3')); // Uncomment when asset is added
        HapticFeedback.heavyImpact();
      }

      notifyListeners();
    }
  }

  Future<void> addCategory(Category category) async {
    if (_categories.length >= 5) {
      throw Exception("Maximum of 5 categories allowed.");
    }
    await DBHelper.instance.insertCategory(category);
    _categories.add(category);
    notifyListeners();
  }

  Future<void> saveSettings(Settings s) async {
    await DBHelper.instance.updateSettings(s);
    _settings = s;
    notifyListeners();
  }

  double getPowerBarPercentage() {
    final todayTasks = _getTodayTasks();
    if (todayTasks.isEmpty) return 0.0;
    int completed = todayTasks.where((t) => t.isCompleted).length;
    return completed / todayTasks.length;
  }

  List<Task> _getTodayTasks() {
    final now = DateTime.now();
    return _tasks.where((t) {
      final tDate = DateTime.parse(t.date);
      return tDate.year == now.year && tDate.month == now.month && tDate.day == now.day;
    }).toList();
  }

  double getHistoricalCompletionRate(DateTime date) {
    final historicalTasks = _tasks.where((t) {
      final tDate = DateTime.parse(t.date);
      return tDate.year == date.year && tDate.month == date.month && tDate.day == date.day;
    }).toList();

    if (historicalTasks.isEmpty) return 0.0;
    int completed = historicalTasks.where((t) => t.isCompleted).length;
    return completed / historicalTasks.length;
  }

  bool evaluateLockStatus() {
    // Check if yesterday's tasks were all completed.
    // If not, we lock the app today.
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final yesterdayTasks = _tasks.where((t) {
      final tDate = DateTime.parse(t.date);
      return tDate.year == yesterday.year && tDate.month == yesterday.month && tDate.day == yesterday.day;
    }).toList();

    if (yesterdayTasks.isEmpty) return false;

    int completedYesterday = yesterdayTasks.where((t) => t.isCompleted).length;
    return completedYesterday < yesterdayTasks.length;
  }
}
