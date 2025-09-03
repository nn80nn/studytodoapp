import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/task.dart';
import '../models/subject.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Контроллеры для реал-тайм стримов
  StreamController<List<Task>>? _tasksStreamController;
  StreamController<List<Subject>>? _subjectsStreamController;
  StreamSubscription<QuerySnapshot>? _tasksSubscription;
  StreamSubscription<QuerySnapshot>? _subjectsSubscription;
  
  // Статус подключения
  bool _isOnline = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  void initialize() {
    _setupConnectivityListener();
    _enableOfflineSupport();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  void _enableOfflineSupport() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Subjects
  Future<List<Subject>> getSubjects() async {
    try {
      final snapshot = await _firestore.collection('subjects')
          .orderBy('createdAt', descending: false)
          .get(GetOptions(source: _isOnline ? Source.serverAndCache : Source.cache));
      return snapshot.docs.map((doc) => Subject.fromJson({
        ...doc.data(),
        'id': doc.id,
      })).toList();
    } catch (e) {
      print('Error getting subjects: $e');
      return [];
    }
  }

  Stream<List<Subject>> getSubjectsStream() {
    return _firestore.collection('subjects')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Subject.fromJson({
          ...doc.data(),
          'id': doc.id,
        })).toList());
  }

  Future<void> addSubject(Subject subject) async {
    try {
      await _firestore.collection('subjects').doc(subject.id).set({
        ...subject.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding subject: $e');
      rethrow;
    }
  }

  Future<void> updateSubject(Subject subject) async {
    try {
      await _firestore.collection('subjects').doc(subject.id).update({
        ...subject.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating subject: $e');
      rethrow;
    }
  }

  Future<void> deleteSubject(String id) async {
    try {
      // Проверяем есть ли связанные задачи
      final tasksQuery = await _firestore.collection('tasks')
          .where('subjectId', isEqualTo: id)
          .limit(1)
          .get();
      
      if (tasksQuery.docs.isNotEmpty) {
        throw Exception('Нельзя удалить предмет, для которого есть задачи');
      }
      
      await _firestore.collection('subjects').doc(id).delete();
    } catch (e) {
      print('Error deleting subject: $e');
      rethrow;
    }
  }

  // Tasks
  Future<List<Task>> getTasks() async {
    try {
      final snapshot = await _firestore.collection('tasks')
          .orderBy('createdAt', descending: true)
          .get(GetOptions(source: _isOnline ? Source.serverAndCache : Source.cache));
      return snapshot.docs.map((doc) => Task.fromJson({
        ...doc.data(),
        'id': doc.id,
      })).toList();
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }

  Stream<List<Task>> getTasksStream() {
    return _firestore.collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Task.fromJson({
          ...doc.data(),
          'id': doc.id,
        })).toList());
  }

  // Получение задач по предмету
  Stream<List<Task>> getTasksBySubjectStream(String subjectId) {
    return _firestore.collection('tasks')
        .where('subjectId', isEqualTo: subjectId)
        .orderBy('deadline', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Task.fromJson({
          ...doc.data(),
          'id': doc.id,
        })).toList());
  }

  // Получение задач по статусу
  Stream<List<Task>> getTasksByStatusStream(TaskStatus status) {
    return _firestore.collection('tasks')
        .where('status', isEqualTo: status.index)
        .orderBy('deadline', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Task.fromJson({
          ...doc.data(),
          'id': doc.id,
        })).toList());
  }

  Future<void> addTask(Task task) async {
    try {
      await _firestore.collection('tasks').doc(task.id).set({
        ...task.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding task: $e');
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _firestore.collection('tasks').doc(task.id).update({
        ...task.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _firestore.collection('tasks').doc(id).delete();
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }

  // Массовые операции
  Future<void> markMultipleTasksCompleted(List<String> taskIds) async {
    try {
      final batch = _firestore.batch();
      
      for (final taskId in taskIds) {
        final taskRef = _firestore.collection('tasks').doc(taskId);
        batch.update(taskRef, {
          'status': TaskStatus.completed.index,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      print('Error marking tasks completed: $e');
      rethrow;
    }
  }

  Future<void> deleteMultipleTasks(List<String> taskIds) async {
    try {
      final batch = _firestore.batch();
      
      for (final taskId in taskIds) {
        final taskRef = _firestore.collection('tasks').doc(taskId);
        batch.delete(taskRef);
      }
      
      await batch.commit();
    } catch (e) {
      print('Error deleting multiple tasks: $e');
      rethrow;
    }
  }

  // Аналитика
  Future<Map<String, int>> getTasksAnalytics() async {
    try {
      final snapshot = await _firestore.collection('tasks').get();
      
      int total = snapshot.docs.length;
      int completed = 0;
      int pending = 0;
      int overdue = 0;
      
      final now = DateTime.now();
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = TaskStatus.values[data['status'] ?? 0];
        final deadline = DateTime.fromMillisecondsSinceEpoch(data['deadline']);
        
        switch (status) {
          case TaskStatus.completed:
            completed++;
            break;
          case TaskStatus.pending:
            if (deadline.isBefore(now)) {
              overdue++;
            } else {
              pending++;
            }
            break;
          case TaskStatus.overdue:
            overdue++;
            break;
        }
      }
      
      return {
        'total': total,
        'completed': completed,
        'pending': pending,
        'overdue': overdue,
      };
    } catch (e) {
      print('Error getting tasks analytics: $e');
      return {
        'total': 0,
        'completed': 0,
        'pending': 0,
        'overdue': 0,
      };
    }
  }

  Future<Map<String, int>> getTasksBySubjectAnalytics() async {
    try {
      final tasksSnapshot = await _firestore.collection('tasks').get();
      final subjectsSnapshot = await _firestore.collection('subjects').get();
      
      final Map<String, int> result = {};
      final Map<String, String> subjectNames = {};
      
      // Получаем названия предметов
      for (final doc in subjectsSnapshot.docs) {
        final data = doc.data();
        subjectNames[doc.id] = data['name'] ?? 'Unknown';
      }
      
      // Подсчитываем задачи по предметам
      for (final doc in tasksSnapshot.docs) {
        final data = doc.data();
        final subjectId = data['subjectId'] as String;
        final subjectName = subjectNames[subjectId] ?? 'Unknown';
        
        result[subjectName] = (result[subjectName] ?? 0) + 1;
      }
      
      return result;
    } catch (e) {
      print('Error getting tasks by subject analytics: $e');
      return {};
    }
  }

  // Статус подключения
  bool get isOnline => _isOnline;

  // Очистка ресурсов
  void dispose() {
    _tasksStreamController?.close();
    _subjectsStreamController?.close();
    _tasksSubscription?.cancel();
    _subjectsSubscription?.cancel();
    _connectivitySubscription?.cancel();
  }
}