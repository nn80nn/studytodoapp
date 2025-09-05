import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/subject.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  SharedPreferences? _prefs;
  
  static const String _tasksKey = 'tasks';
  static const String _subjectsKey = 'subjects';
  static const String _userIdKey = 'current_user_id';

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // User ID
  String? get currentUserId => _prefs?.getString(_userIdKey);
  
  Future<void> setCurrentUserId(String? userId) async {
    if (userId != null) {
      await _prefs?.setString(_userIdKey, userId);
    } else {
      await _prefs?.remove(_userIdKey);
    }
  }

  // Tasks
  Future<List<Task>> getTasks([String? userId]) async {
    try {
      final String? tasksJson = _prefs?.getString(_getTasksKey(userId));
      if (tasksJson == null || tasksJson.isEmpty) return [];
      
      final List<dynamic> tasksList = json.decode(tasksJson);
      return tasksList.map((taskJson) => Task.fromJson(taskJson)).toList();
    } catch (e) {
      print('Error loading tasks from local storage: $e');
      return [];
    }
  }

  Future<void> saveTasks(List<Task> tasks, [String? userId]) async {
    try {
      final String tasksJson = json.encode(tasks.map((task) => task.toJson()).toList());
      await _prefs?.setString(_getTasksKey(userId), tasksJson);
    } catch (e) {
      print('Error saving tasks to local storage: $e');
    }
  }

  Future<void> addTask(Task task, [String? userId]) async {
    final tasks = await getTasks(userId);
    tasks.removeWhere((t) => t.id == task.id);
    tasks.add(task);
    await saveTasks(tasks, userId);
  }

  Future<void> updateTask(Task task, [String? userId]) async {
    final tasks = await getTasks(userId);
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      await saveTasks(tasks, userId);
    }
  }

  Future<void> deleteTask(String taskId, [String? userId]) async {
    final tasks = await getTasks(userId);
    tasks.removeWhere((t) => t.id == taskId);
    await saveTasks(tasks, userId);
  }

  // Subjects
  Future<List<Subject>> getSubjects([String? userId]) async {
    try {
      final String? subjectsJson = _prefs?.getString(_getSubjectsKey(userId));
      if (subjectsJson == null || subjectsJson.isEmpty) return [];
      
      final List<dynamic> subjectsList = json.decode(subjectsJson);
      return subjectsList.map((subjectJson) => Subject.fromJson(subjectJson)).toList();
    } catch (e) {
      print('Error loading subjects from local storage: $e');
      return [];
    }
  }

  Future<void> saveSubjects(List<Subject> subjects, [String? userId]) async {
    try {
      final String subjectsJson = json.encode(subjects.map((subject) => subject.toJson()).toList());
      await _prefs?.setString(_getSubjectsKey(userId), subjectsJson);
    } catch (e) {
      print('Error saving subjects to local storage: $e');
    }
  }

  Future<void> addSubject(Subject subject, [String? userId]) async {
    final subjects = await getSubjects(userId);
    subjects.removeWhere((s) => s.id == subject.id);
    subjects.add(subject);
    await saveSubjects(subjects, userId);
  }

  Future<void> updateSubject(Subject subject, [String? userId]) async {
    final subjects = await getSubjects(userId);
    final index = subjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      subjects[index] = subject;
      await saveSubjects(subjects, userId);
    }
  }

  Future<void> deleteSubject(String subjectId, [String? userId]) async {
    final subjects = await getSubjects(userId);
    subjects.removeWhere((s) => s.id == subjectId);
    await saveSubjects(subjects, userId);
  }

  // Очистка данных пользователя
  Future<void> clearUserData([String? userId]) async {
    await _prefs?.remove(_getTasksKey(userId));
    await _prefs?.remove(_getSubjectsKey(userId));
    if (userId == null) {
      await _prefs?.remove(_userIdKey);
    }
  }

  // Приватные методы
  String _getTasksKey([String? userId]) {
    return userId != null ? '${_tasksKey}_$userId' : _tasksKey;
  }

  String _getSubjectsKey([String? userId]) {
    return userId != null ? '${_subjectsKey}_$userId' : _subjectsKey;
  }

  // Миграция данных между анонимным и авторизованным пользователем
  Future<void> migrateDataToUser(String userId) async {
    try {
      // Получаем данные анонимного пользователя
      final anonymousTasks = await getTasks();
      final anonymousSubjects = await getSubjects();

      if (anonymousTasks.isNotEmpty || anonymousSubjects.isNotEmpty) {
        // Получаем существующие данные пользователя
        final userTasks = await getTasks(userId);
        final userSubjects = await getSubjects(userId);

        // Объединяем данные (новые имеют приоритет)
        final Map<String, Task> allTasks = {};
        for (final task in userTasks) {
          allTasks[task.id] = task;
        }
        for (final task in anonymousTasks) {
          allTasks[task.id] = task;
        }

        final Map<String, Subject> allSubjects = {};
        for (final subject in userSubjects) {
          allSubjects[subject.id] = subject;
        }
        for (final subject in anonymousSubjects) {
          allSubjects[subject.id] = subject;
        }

        // Сохраняем объединенные данные
        await saveTasks(allTasks.values.toList(), userId);
        await saveSubjects(allSubjects.values.toList(), userId);

        // Очищаем анонимные данные
        await clearUserData();
      }
    } catch (e) {
      print('Error migrating data to user: $e');
    }
  }
}