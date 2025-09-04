import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/task.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';

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
    if (!isUserAuthenticated) return [];
    
    try {
      final snapshot = await _firestore.collection('subjects')
          .where('userId', isEqualTo: currentUserId)
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
        .map((snapshot) => snapshot.docs.map((doc) {
          try {
            return Subject.fromJson({
              ...doc.data(),
              'id': doc.id,
            });
          } catch (e) {
            print('Error parsing subject ${doc.id}: $e');
            // Return a fallback subject with current timestamp
            return Subject(
              id: doc.id,
              name: doc.data()['name'] ?? 'Unknown Subject',
              color: const Color(0xFF26C6DA),
              description: doc.data()['description'],
              createdAt: DateTime.now(),
            );
          }
        }).toList())
        .handleError((error) {
          print('Error in subjects stream: $error');
          return <Subject>[];
        });
  }

  Future<void> addSubject(Subject subject) async {
    if (!isUserAuthenticated) return;
    
    try {
      await _firestore.collection('subjects').doc(subject.id).set({
        ...subject.toJson(),
        'userId': currentUserId,
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
    if (!isUserAuthenticated) return [];
    
    try {
      final snapshot = await _firestore.collection('tasks')
          .where('userId', isEqualTo: currentUserId)
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
    if (!isUserAuthenticated) {
      return Stream.value([]);
    }
    
    return _firestore.collection('tasks')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Task.fromJson({
          ...doc.data(),
          'id': doc.id,
        })).toList());
  }

  // Получение задач по предмету
  Stream<List<Task>> getTasksBySubjectStream(String subjectId) {
    if (!isUserAuthenticated) {
      return Stream.value([]);
    }
    
    return _firestore.collection('tasks')
        .where('userId', isEqualTo: currentUserId)
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
    if (!isUserAuthenticated) {
      return Stream.value([]);
    }
    
    return _firestore.collection('tasks')
        .where('userId', isEqualTo: currentUserId)
        .where('status', isEqualTo: status.index)
        .orderBy('deadline', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Task.fromJson({
          ...doc.data(),
          'id': doc.id,
        })).toList());
  }

  Future<void> addTask(Task task) async {
    if (!isUserAuthenticated) return;
    
    try {
      await _firestore.collection('tasks').doc(task.id).set({
        ...task.toJson(),
        'userId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding task: $e');
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    if (!isUserAuthenticated) return;
    
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
    if (!isUserAuthenticated) return;
    
    try {
      await _firestore.collection('tasks').doc(id).delete();
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }

  // Массовые операции
  Future<void> markMultipleTasksCompleted(List<String> taskIds) async {
    if (!isUserAuthenticated) return;
    
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
    if (!isUserAuthenticated) return;
    
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
    if (!isUserAuthenticated) {
      return {
        'total': 0,
        'completed': 0,
        'pending': 0,
        'overdue': 0,
      };
    }
    
    try {
      final snapshot = await _firestore.collection('tasks')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
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
    if (!isUserAuthenticated) {
      return {};
    }
    
    try {
      final tasksSnapshot = await _firestore.collection('tasks')
          .where('userId', isEqualTo: currentUserId)
          .get();
      final subjectsSnapshot = await _firestore.collection('subjects')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
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

  // === USER PROFILE METHODS ===

  String? _currentUserId;

  void setCurrentUser(String? userId) {
    _currentUserId = userId;
  }

  String get currentUserId => _currentUserId ?? '';

  bool get isUserAuthenticated => _currentUserId != null;

  // Сохранение/обновление профиля пользователя
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .set(profile.toJson(), SetOptions(merge: true));
      print('User profile saved: ${profile.uid}');
    } catch (e) {
      print('Error saving user profile: $e');
      throw e;
    }
  }

  // Получение профиля пользователя
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromJson({
          ...doc.data()!,
          'uid': doc.id,
        });
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Получение статистики пользователя
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .get();

      final subjectsSnapshot = await _firestore
          .collection('subjects')
          .where('userId', isEqualTo: userId)
          .get();

      final totalTasks = tasksSnapshot.docs.length;
      final completedTasks = tasksSnapshot.docs
          .where((doc) => doc.data()['status'] == TaskStatus.completed.index)
          .length;

      return {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'totalSubjects': subjectsSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'totalTasks': 0,
        'completedTasks': 0,
        'totalSubjects': 0,
      };
    }
  }

  // Удаление всех данных пользователя
  Future<void> deleteUserData(String userId) async {
    try {
      final batch = _firestore.batch();

      // Удаляем профиль
      batch.delete(_firestore.collection('users').doc(userId));

      // Удаляем задачи
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Удаляем предметы
      final subjectsSnapshot = await _firestore
          .collection('subjects')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in subjectsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('User data deleted: $userId');
    } catch (e) {
      print('Error deleting user data: $e');
      throw e;
    }
  }

  // Очистка ресурсов
  void dispose() {
    _tasksStreamController?.close();
    _subjectsStreamController?.close();
    _tasksSubscription?.cancel();
    _subjectsSubscription?.cancel();
    _connectivitySubscription?.cancel();
  }
}