import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';
import 'sqlite_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SQLiteService _sqlite = SQLiteService();
  final Uuid _uuid = const Uuid();
  
  // Контроллеры для реал-тайм стримов
  StreamController<List<Task>>? _tasksStreamController;
  StreamController<List<Subject>>? _subjectsStreamController;
  StreamSubscription<QuerySnapshot>? _tasksSubscription;
  StreamSubscription<QuerySnapshot>? _subjectsSubscription;
  
  // Статус подключения
  bool _isOnline = true;
  bool _firebaseAvailable = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  Future<void> initialize() async {
    await _sqlite.database; // Инициализируем SQLite
    _setupConnectivityListener();
    await _enableOfflineSupport(); // Ждем инициализацию Firebase с таймаутом
    _checkFirebaseAvailability();

    // Инициализируем анонимного пользователя, если необходимо
    await _initializeCurrentUser();
  }

  Future<void> _initializeCurrentUser() async {
    // Пытаемся загрузить существующего пользователя
    final existingUserId = await _sqlite.getSetting('current_user_id');
    if (existingUserId != null) {
      _currentUserId = existingUserId;
      await _sqlite.ensureUserExists(existingUserId);
    } else {
      // Создаем нового анонимного пользователя
      await _initializeAnonymousUser();
    }
  }

  Future<void> _initializeAnonymousUser() async {
    final anonymousUserId = 'anonymous_${_uuid.v4()}';
    await _sqlite.ensureUserExists(anonymousUserId);
    setCurrentUser(anonymousUserId);
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  Future<void> _enableOfflineSupport() async {
    try {
      // Добавляем таймаут для Firebase операций
      await Future(() async {
        _firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        _firebaseAvailable = true;
      }).timeout(const Duration(seconds: 5)); // 5 секунд таймаут
    } catch (e) {
      print('Firebase not available: $e');
      _firebaseAvailable = false;
    }
  }

  void _checkFirebaseAvailability() {
    if (_firebaseAvailable && _isOnline) {
      // Тестируем подключение к Firebase
      _firestore.collection('test').limit(1).get(
        GetOptions(source: Source.server)
      ).timeout(const Duration(seconds: 5)).then((_) {
        _firebaseAvailable = true;
        print('Firebase available');
      }).catchError((e) {
        _firebaseAvailable = false;
        print('Firebase not available: $e');
      });
    }
  }

  // Subjects
  Future<List<Subject>> getSubjects() async {
    // Всегда загружаем из локального хранилища (SQLite)
    List<Subject> localSubjects = await _sqlite.getSubjects(currentUserId);
    
    // Запускаем синхронизацию в фоне, если доступен Firebase
    if (_firebaseAvailable && isAuthenticatedUser) {
      _syncSubjectsInBackground();
    }
    
    return localSubjects;
  }

  Stream<List<Subject>> getSubjectsStream() {
    _subjectsStreamController ??= StreamController<List<Subject>>.broadcast();
    
    // Загружаем и эмитим локальные данные сразу
    _loadAndEmitSubjects();
    
    // Если Firebase доступен, запускаем фоновую синхронизацию
    if (_firebaseAvailable && isAuthenticatedUser) {
      _setupSubjectsSync();
    }
    
    return _subjectsStreamController!.stream;
  }

  void _loadAndEmitSubjects() async {
    try {
      final subjects = await _sqlite.getSubjects(currentUserId);
      _subjectsStreamController?.add(subjects);
    } catch (e) {
      print('Error loading local subjects: $e');
      _subjectsStreamController?.add([]);
    }
  }

  void _syncSubjectsInBackground() async {
    try {
      await _syncSubjectsWithCloud();
    } catch (e) {
      print('Background subjects sync error: $e');
    }
  }

  void _setupSubjectsSync() {
    // Периодическая синхронизация каждые 2 минуты (уменьшена частота для избежания блокировок)
    Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_firebaseAvailable && isAuthenticatedUser) {
        _syncSubjectsInBackground();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _syncSubjectsWithCloud() async {
    if (!_firebaseAvailable || !isAuthenticatedUser) return;

    try {
      final userId = await getCurrentUserIdAsync();

      // Получаем время последней синхронизации
      final lastSyncTime = await _getLastSyncTime();

      // Получаем изменения из облака после последней синхронизации
      final cloudSubjects = await _getCloudSubjectsUpdatedAfter(lastSyncTime);
      final cloudDeletedSubjectIds = await _getCloudDeletedSubjectIdsAfter(lastSyncTime);

      // Получаем локальные изменения после последней синхронизации
      final localSubjects = await _sqlite.getSubjectsUpdatedAfter(userId, lastSyncTime);

      // Применяем алгоритм слияния (как в Steam Cloud)
      await _mergeSubjects(localSubjects, cloudSubjects);

      // Применяем удаления из облака
      for (final subjectId in cloudDeletedSubjectIds) {
        print('Applying cloud deletion locally: $subjectId');
        await _sqlite.deleteSubject(subjectId, userId);
      }

      // Обновляем время последней синхронизации
      await _updateLastSyncTime(DateTime.now());

      // Обновляем стрим
      _loadAndEmitSubjects();

    } catch (e) {
      print('Error syncing subjects with cloud: $e');
    }
  }

  Future<List<Subject>> _getCloudSubjectsUpdatedAfter(DateTime timestamp) async {
    final userId = await getCurrentUserIdAsync();
    final snapshot = await _firestore.collection('subjects')
        .where('userId', isEqualTo: userId)
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(timestamp))
        .orderBy('updatedAt', descending: false)
        .get(GetOptions(source: Source.server));

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Subject.fromJson({
        ...data,
        'id': doc.id,
      });
    }).where((subject) {
      // Фильтруем мягко удаленные предметы
      return !(subject.toJson()['is_deleted'] == true);
    }).toList();
  }

  Future<List<String>> _getCloudDeletedSubjectIdsAfter(DateTime timestamp) async {
    final userId = await getCurrentUserIdAsync();
    final snapshot = await _firestore.collection('subjects')
        .where('userId', isEqualTo: userId)
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(timestamp))
        .where('is_deleted', isEqualTo: true)
        .orderBy('updatedAt', descending: false)
        .get(GetOptions(source: Source.server));

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<void> _mergeSubjects(List<Subject> localSubjects, List<Subject> cloudSubjects) async {
    print('_mergeSubjects called with ${localSubjects.length} local subjects and ${cloudSubjects.length} cloud subjects');
    final userId = await getCurrentUserIdAsync();
    final Map<String, Subject> mergedSubjects = {};

    // Получаем время последней синхронизации
    final lastSyncTime = await _getLastSyncTime();
    print('Last sync time: $lastSyncTime');

    // Получаем ID предметов, удаленных локально после последней синхронизации
    final deletedSubjectIds = await _sqlite.getDeletedSubjectIdsAfter(userId, lastSyncTime);
    print('Deleted subject IDs since last sync: $deletedSubjectIds');

    // Добавляем локальные изменения
    for (final subject in localSubjects) {
      mergedSubjects[subject.id] = subject;
    }

    // Сравниваем с облачными и выбираем более новые
    for (final cloudSubject in cloudSubjects) {
      final localSubject = mergedSubjects[cloudSubject.id];

      if (localSubject == null) {
        // Проверяем, был ли этот предмет удален локально
        if (deletedSubjectIds.contains(cloudSubject.id)) {
          // Этот предмет был удален локально, не восстанавливаем его
          // и удаляем из облака
          print('Found deleted subject in cloud, removing from cloud: ${cloudSubject.id}');
          await _deleteSubjectFromCloud(cloudSubject.id);
          continue;
        }

        // Новый предмет из облака
        print('Adding new subject from cloud: ${cloudSubject.id}');
        mergedSubjects[cloudSubject.id] = cloudSubject;
        await _sqlite.insertOrUpdateSubject(cloudSubject, userId);
      } else {
        // Сравниваем время изменения
        final localTime = localSubject.updatedAt ?? localSubject.createdAt;
        final cloudTime = cloudSubject.updatedAt ?? cloudSubject.createdAt;

        if (cloudTime.isAfter(localTime)) {
          // Облачная версия новее
          print('Updating from cloud (cloud newer): ${cloudSubject.id}');
          mergedSubjects[cloudSubject.id] = cloudSubject;
          await _sqlite.insertOrUpdateSubject(cloudSubject, userId);
        } else if (localTime.isAfter(cloudTime)) {
          // Локальная версия новее, загружаем в облако
          print('Uploading to cloud (local newer): ${localSubject.id}');
          await _uploadSubjectToCloud(localSubject);
        }
      }
    }

    // Загружаем новые локальные предметы в облако
    for (final localSubject in localSubjects) {
      final hasInCloud = cloudSubjects.any((cs) => cs.id == localSubject.id);
      if (!hasInCloud) {
        print('Uploading new local subject to cloud: ${localSubject.id}');
        await _uploadSubjectToCloud(localSubject);
      }
    }
  }

  Future<void> _uploadSubjectToCloud(Subject subject) async {
    try {
      final userId = await getCurrentUserIdAsync();
      print('Uploading subject to cloud: ${subject.id} for user: $userId');
      await _firestore.collection('subjects').doc(subject.id).set({
        ...subject.toJson(),
        'userId': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
      print('Subject uploaded successfully: ${subject.id}');
    } catch (e) {
      print('Error uploading subject to cloud: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }



  Future<void> addSubject(Subject subject) async {
    // Новый предмет с меткой времени создания
    final newSubject = Subject(
      id: subject.id,
      name: subject.name,
      color: subject.color,
      description: subject.description,
      createdAt: subject.createdAt,
      updatedAt: DateTime.now(),
    );
    
    // Сохраняем в SQLite
    await _sqlite.insertOrUpdateSubject(newSubject, currentUserId);
    
    // Эмитим обновленные данные
    _loadAndEmitSubjects();
    
    // Запускаем фоновую синхронизацию
    if (_firebaseAvailable && isAuthenticatedUser) {
      _uploadSubjectToCloud(newSubject);
    }
  }


  Future<void> updateSubject(Subject subject) async {
    // Обновляем предмет с новой меткой времени
    final updatedSubject = Subject(
      id: subject.id,
      name: subject.name,
      color: subject.color,
      description: subject.description,
      createdAt: subject.createdAt,
      updatedAt: DateTime.now(),
    );
    
    // Обновляем в SQLite
    await _sqlite.updateSubject(updatedSubject, currentUserId);
    
    // Эмитим обновленные данные
    _loadAndEmitSubjects();
    
    // Запускаем фоновую синхронизацию
    if (_firebaseAvailable && isAuthenticatedUser) {
      _uploadSubjectToCloud(updatedSubject);
    }
  }

  Future<void> deleteSubject(String id) async {
    // Проверяем есть ли связанные задачи в локальной базе
    final tasks = await _sqlite.getTasks(currentUserId);
    final linkedTasks = tasks.where((task) => task.subjectId == id).toList();
    
    if (linkedTasks.isNotEmpty) {
      throw Exception('Нельзя удалить предмет, для которого есть задачи');
    }
    
    // Мягкое удаление (помечаем как удаленный)
    await _sqlite.deleteSubject(id, currentUserId);
    
    // Эмитим обновленные данные
    _loadAndEmitSubjects();
    
    // Мягкое удаление из облака
    if (_firebaseAvailable && isAuthenticatedUser) {
      await _deleteSubjectFromCloud(id);
    }
  }

  // Tasks
  Future<List<Task>> getTasks() async {
    // Всегда загружаем из локального хранилища (SQLite)
    List<Task> localTasks = await _sqlite.getTasks(currentUserId);
    
    // Запускаем синхронизацию в фоне, если доступен Firebase
    if (_firebaseAvailable && isAuthenticatedUser) {
      _syncTasksInBackground();
    }
    
    return localTasks;
  }

  Stream<List<Task>> getTasksStream() {
    _tasksStreamController ??= StreamController<List<Task>>.broadcast();
    
    // Загружаем и эмитим локальные данные сразу
    _loadAndEmitTasks();
    
    // Если Firebase доступен, запускаем фоновую синхронизацию
    if (_firebaseAvailable && isAuthenticatedUser) {
      _setupTasksSync();
    }
    
    return _tasksStreamController!.stream;
  }

  void _loadAndEmitTasks() async {
    try {
      final tasks = await _sqlite.getTasks(currentUserId);
      _tasksStreamController?.add(tasks);
    } catch (e) {
      print('Error loading local tasks: $e');
      _tasksStreamController?.add([]);
    }
  }

  void _syncTasksInBackground() async {
    try {
      await _syncTasksWithCloud();
    } catch (e) {
      print('Background tasks sync error: $e');
    }
  }

  void _setupTasksSync() {
    // Периодическая синхронизация каждые 2 минуты (уменьшена частота для избежания блокировок)
    Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_firebaseAvailable && isAuthenticatedUser) {
        _syncTasksInBackground();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _syncTasksWithCloud() async {
    if (!_firebaseAvailable || !isAuthenticatedUser) return;

    try {
      final userId = await getCurrentUserIdAsync();

      // Получаем время последней синхронизации
      final lastSyncTime = await _getLastSyncTime();

      // Получаем изменения из облака после последней синхронизации
      final cloudTasks = await _getCloudTasksUpdatedAfter(lastSyncTime);
      final cloudDeletedTaskIds = await _getCloudDeletedTaskIdsAfter(lastSyncTime);

      // Получаем локальные изменения после последней синхронизации
      final localTasks = await _sqlite.getTasksUpdatedAfter(userId, lastSyncTime);

      // Применяем алгоритм слияния (как в Steam Cloud)
      await _mergeTasks(localTasks, cloudTasks);

      // Применяем удаления из облака
      for (final taskId in cloudDeletedTaskIds) {
        print('Applying cloud deletion locally: $taskId');
        await _sqlite.deleteTask(taskId, userId);
      }

      // Обновляем время последней синхронизации
      await _updateLastSyncTime(DateTime.now());

      // Обновляем стрим
      _loadAndEmitTasks();

    } catch (e) {
      print('Error syncing tasks with cloud: $e');
    }
  }

  Future<List<Task>> _getCloudTasksUpdatedAfter(DateTime timestamp) async {
    final userId = await getCurrentUserIdAsync();
    final snapshot = await _firestore.collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(timestamp))
        .orderBy('updatedAt', descending: false)
        .get(GetOptions(source: Source.server));

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Task.fromJson({
        ...data,
        'id': doc.id,
      });
    }).where((task) {
      // Фильтруем мягко удаленные задачи
      return !(task.toJson()['is_deleted'] == true);
    }).toList();
  }

  Future<List<String>> _getCloudDeletedTaskIdsAfter(DateTime timestamp) async {
    final userId = await getCurrentUserIdAsync();
    final snapshot = await _firestore.collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(timestamp))
        .where('is_deleted', isEqualTo: true)
        .orderBy('updatedAt', descending: false)
        .get(GetOptions(source: Source.server));

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<void> _mergeTasks(List<Task> localTasks, List<Task> cloudTasks) async {
    print('_mergeTasks called with ${localTasks.length} local tasks and ${cloudTasks.length} cloud tasks');
    final userId = await getCurrentUserIdAsync();
    final Map<String, Task> mergedTasks = {};

    // Получаем время последней синхронизации
    final lastSyncTime = await _getLastSyncTime();
    print('Last sync time: $lastSyncTime');

    // Получаем ID задач, удаленных локально после последней синхронизации
    final deletedTaskIds = await _sqlite.getDeletedTaskIdsAfter(userId, lastSyncTime);
    print('Deleted task IDs since last sync: $deletedTaskIds');

    // Добавляем локальные изменения
    for (final task in localTasks) {
      mergedTasks[task.id] = task;
    }

    // Сравниваем с облачными и выбираем более новые
    for (final cloudTask in cloudTasks) {
      final localTask = mergedTasks[cloudTask.id];

      if (localTask == null) {
        // Проверяем, была ли эта задача удалена локально
        if (deletedTaskIds.contains(cloudTask.id)) {
          // Эта задача была удалена локально, не восстанавливаем её
          // и удаляем из облака
          print('Found deleted task in cloud, removing from cloud: ${cloudTask.id}');
          await _deleteTaskFromCloud(cloudTask.id);
          continue;
        }

        // Новая задача из облака
        print('Adding new task from cloud: ${cloudTask.id}');
        mergedTasks[cloudTask.id] = cloudTask;
        await _sqlite.insertOrUpdateTask(cloudTask, userId);
      } else {
        // Сравниваем время изменения
        final localTime = localTask.updatedAt ?? localTask.createdAt;
        final cloudTime = cloudTask.updatedAt ?? cloudTask.createdAt;

        if (cloudTime.isAfter(localTime)) {
          // Облачная версия новее
          print('Updating from cloud (cloud newer): ${cloudTask.id}');
          mergedTasks[cloudTask.id] = cloudTask;
          await _sqlite.insertOrUpdateTask(cloudTask, userId);
        } else if (localTime.isAfter(cloudTime)) {
          // Локальная версия новее, загружаем в облако
          print('Uploading to cloud (local newer): ${localTask.id}');
          await _uploadTaskToCloud(localTask);
        }
      }
    }
    
    // Загружаем новые локальные задачи в облако
    for (final localTask in localTasks) {
      final hasInCloud = cloudTasks.any((ct) => ct.id == localTask.id);
      if (!hasInCloud) {
        await _uploadTaskToCloud(localTask);
      }
    }
  }

  Future<void> _uploadTaskToCloud(Task task) async {
    try {
      final userId = await getCurrentUserIdAsync();
      print('Uploading task to cloud: ${task.id} for user: $userId');
      await _firestore.collection('tasks').doc(task.id).set({
        ...task.toJson(),
        'userId': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
      print('Task uploaded successfully: ${task.id}');
    } catch (e) {
      print('Error uploading task to cloud: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _deleteTaskFromCloud(String taskId) async {
    try {
      final userId = await getCurrentUserIdAsync();
      print('Soft deleting task from cloud: $taskId for user: $userId');
      await _firestore.collection('tasks').doc(taskId).update({
        'is_deleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
      print('Task soft deleted from cloud successfully: $taskId');
    } catch (e) {
      print('Error soft deleting task from cloud: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _deleteSubjectFromCloud(String subjectId) async {
    try {
      final userId = await getCurrentUserIdAsync();
      print('Soft deleting subject from cloud: $subjectId for user: $userId');
      await _firestore.collection('subjects').doc(subjectId).update({
        'is_deleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
      print('Subject soft deleted from cloud successfully: $subjectId');
    } catch (e) {
      print('Error soft deleting subject from cloud: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }



  // Получение задач по предмету
  Stream<List<Task>> getTasksBySubjectStream(String subjectId) {
    return Stream.fromFuture(_getTasksBySubject(subjectId));
  }

  Future<List<Task>> _getTasksBySubject(String subjectId) async {
    final allTasks = await _sqlite.getTasks(currentUserId);
    return allTasks.where((task) => task.subjectId == subjectId).toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
  }

  // Получение задач по статусу
  Stream<List<Task>> getTasksByStatusStream(TaskStatus status) {
    return Stream.fromFuture(_getTasksByStatus(status));
  }

  Future<List<Task>> _getTasksByStatus(TaskStatus status) async {
    final allTasks = await _sqlite.getTasks(currentUserId);
    return allTasks.where((task) => task.status == status).toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
  }

  Future<void> addTask(Task task) async {
    // Новая задача с меткой времени создания
    final newTask = Task(
      id: task.id,
      subjectId: task.subjectId,
      title: task.title,
      description: task.description,
      deadline: task.deadline,
      plannedTime: task.plannedTime,
      priority: task.priority,
      status: task.status,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
    );
    
    // Сохраняем в SQLite
    await _sqlite.insertOrUpdateTask(newTask, currentUserId);
    
    // Эмитим обновленные данные
    _loadAndEmitTasks();
    
    // Запускаем фоновую синхронизацию
    if (_firebaseAvailable && isAuthenticatedUser) {
      _uploadTaskToCloud(newTask);
    }
  }


  Future<void> updateTask(Task task) async {
    // Получаем старую задачу для проверки изменения статуса
    final oldTasks = await _sqlite.getTasks(currentUserId);
    final oldTask = oldTasks.firstWhere((t) => t.id == task.id, orElse: () => task);

    // Обновляем задачу с новой меткой времени
    final updatedTask = task.copyWith(
      updatedAt: DateTime.now(),
    );

    // Проверяем, была ли задача помечена как выполненная
    final wasCompleted = oldTask.status == TaskStatus.completed;
    final isNowCompleted = updatedTask.status == TaskStatus.completed;

    // Обновляем в SQLite
    await _sqlite.updateTask(updatedTask, currentUserId);

    // Если задача была отмечена как выполненная, увеличиваем счетчик
    if (!wasCompleted && isNowCompleted) {
      await _incrementTotalCompletedAllTime();
    }

    // Эмитим обновленные данные
    _loadAndEmitTasks();

    // Запускаем фоновую синхронизацию
    if (_firebaseAvailable && isAuthenticatedUser) {
      _uploadTaskToCloud(updatedTask);
    }
  }

  Future<void> _incrementTotalCompletedAllTime() async {
    try {
      final currentProfile = await getUserProfile(currentUserId);
      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(
          totalCompletedAllTime: currentProfile.totalCompletedAllTime + 1,
        );
        await saveUserProfile(updatedProfile);

        // Синхронизируем с Firebase если доступен
        if (_firebaseAvailable && isAuthenticatedUser) {
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .set(updatedProfile.toJson(), SetOptions(merge: true));
        }
      }
    } catch (e) {
      print('Error incrementing total completed tasks: $e');
    }
  }

  Future<void> deleteTask(String id) async {
    print('deleteTask called for task: $id');
    print('_firebaseAvailable: $_firebaseAvailable, isAuthenticatedUser: $isAuthenticatedUser');

    // Мягкое удаление (помечаем как удаленную)
    await _sqlite.deleteTask(id, currentUserId);

    // Эмитим обновленные данные
    _loadAndEmitTasks();

    // Удаляем из облака
    if (_firebaseAvailable && isAuthenticatedUser) {
      print('Attempting to delete task from cloud: $id');
      await _deleteTaskFromCloud(id);
    } else {
      print('Skipping cloud deletion - Firebase not available or user not authenticated');
    }
  }

  // Массовые операции
  Future<void> markMultipleTasksCompleted(List<String> taskIds) async {
    try {
      for (final taskId in taskIds) {
        final task = await _sqlite.getTask(taskId, currentUserId);
        if (task != null) {
          final updatedTask = task.copyWith(
            status: TaskStatus.completed,
            updatedAt: DateTime.now(),
          );
          await _sqlite.updateTask(updatedTask, currentUserId);
          
          // Синхронизируем с облаком если возможно
          if (_firebaseAvailable && isAuthenticatedUser) {
            _uploadTaskToCloud(updatedTask);
          }
        }
      }
      
      // Обновляем стрим
      _loadAndEmitTasks();
    } catch (e) {
      print('Error marking tasks completed: $e');
      rethrow;
    }
  }

  Future<void> deleteMultipleTasks(List<String> taskIds) async {
    try {
      for (final taskId in taskIds) {
        await _sqlite.deleteTask(taskId, currentUserId);

        // Удаляем из облака если возможно
        if (_firebaseAvailable && isAuthenticatedUser) {
          await _deleteTaskFromCloud(taskId);
        }
      }
      
      // Обновляем стрим
      _loadAndEmitTasks();
    } catch (e) {
      print('Error deleting multiple tasks: $e');
      rethrow;
    }
  }

  // Аналитика
  Future<Map<String, int>> getTasksAnalytics() async {
    try {
      // Используем SQLite для получения статистики
      return await _sqlite.getTaskStatistics(currentUserId);
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
      final tasks = await _sqlite.getTasks(currentUserId);
      final subjects = await _sqlite.getSubjects(currentUserId);
      
      final Map<String, int> result = {};
      final Map<String, String> subjectNames = {};
      
      // Получаем названия предметов
      for (final subject in subjects) {
        subjectNames[subject.id] = subject.name;
      }
      
      // Подсчитываем задачи по предметам
      for (final task in tasks) {
        final subjectName = subjectNames[task.subjectId] ?? 'Unknown';
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

  // Методы синхронизации для пользователя
  Future<void> forceSyncNow() async {
    print('forceSyncNow called - Firebase available: $_firebaseAvailable, Authenticated: $isAuthenticatedUser');

    if (!_firebaseAvailable || !isAuthenticatedUser) {
      throw Exception('Синхронизация недоступна. Войдите в аккаунт для синхронизации данных.');
    }

    try {
      print('Starting forced sync for user: $currentUserId');
      await _syncSubjectsWithCloud();
      print('Subjects sync completed');
      await _syncTasksWithCloud();
      print('Tasks sync completed');
      await _updateLastSyncTime(DateTime.now());
      print('Forced sync completed successfully');

      // Очищаем старые удаленные записи (раз в день при ручной синхронизации)
      await cleanupOldDeletedRecords();
      print('Cleanup of old deleted records completed');
    } catch (e) {
      print('Error during forced sync: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<bool> get canSync => Future.value(_firebaseAvailable && isAuthenticatedUser);
  
  Future<DateTime?> get lastSyncTime async {
    if (!isAuthenticatedUser) return null;
    
    try {
      return await _getLastSyncTime();
    } catch (e) {
      return null;
    }
  }

  // Миграция данных при авторизации
  Future<void> migrateToUser(String newUserId) async {
    if (_currentUserId == null || _currentUserId!.startsWith('anonymous')) {
      await _sqlite.migrateUserData(currentUserId, newUserId);
      setCurrentUser(newUserId);
      
      // Запускаем синхронизацию с облаком
      if (_firebaseAvailable) {
        await forceSyncNow();
      }
    }
  }

  // === USER PROFILE METHODS ===

  String? _currentUserId;

  void setCurrentUser(String? userId) {
    _currentUserId = userId;
    if (userId != null) {
      _sqlite.setSetting('current_user_id', userId);
    }
  }

  Future<DateTime> _getLastSyncTime() async {
    final userId = await getCurrentUserIdAsync();
    final timestampStr = await _sqlite.getSetting('last_sync_time', userId);
    if (timestampStr != null) {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(timestampStr));
    }
    return DateTime.fromMillisecondsSinceEpoch(0); // Начало эпохи для первой синхронизации
  }

  Future<void> _updateLastSyncTime(DateTime timestamp) async {
    final userId = await getCurrentUserIdAsync();
    await _sqlite.setSetting('last_sync_time', timestamp.millisecondsSinceEpoch.toString(), userId);
    await _sqlite.updateUserLastSync(userId, timestamp);
  }

  String get currentUserId {
    if (_currentUserId != null) return _currentUserId!;
    
    return 'anonymous';
  }

  Future<String> getCurrentUserIdAsync() async {
    print('getCurrentUserIdAsync called - _currentUserId: $_currentUserId, currentUserId: $currentUserId');

    if (_currentUserId != null) return _currentUserId!;

    // Пытаемся загрузить из настроек
    final userId = await _sqlite.getSetting('current_user_id');
    print('SQLite current_user_id setting: $userId');

    if (userId != null) {
      _currentUserId = userId;
      print('Setting _currentUserId to: $userId');
      return userId;
    }

    print('Returning anonymous user');
    return 'anonymous';
  }

  bool get isUserAuthenticated => _currentUserId != null && !_currentUserId!.startsWith('anonymous');
  
  bool get isAuthenticatedUser => isUserAuthenticated;

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

  // Кеш статистики пользователя
  Map<String, Map<String, int>>? _userStatsCache;
  DateTime? _statsCacheTime;
  static const Duration _statsCacheDuration = Duration(minutes: 5);

  // Получение статистики пользователя с кешированием
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      // Проверяем кеш
      final now = DateTime.now();
      if (_userStatsCache != null && 
          _statsCacheTime != null && 
          now.difference(_statsCacheTime!).compareTo(_statsCacheDuration) < 0 &&
          _userStatsCache!.containsKey(userId)) {
        return _userStatsCache![userId]!;
      }

      // Используем локальную SQLite базу данных в приоритете
      final taskStats = await _sqlite.getTaskStatistics(userId);
      final subjects = await _sqlite.getSubjects(userId);
      
      final stats = {
        'totalTasks': taskStats['total'] ?? 0,
        'completedTasks': taskStats['completed'] ?? 0,
        'totalSubjects': subjects.length,
      };

      // Кешируем результат
      _userStatsCache ??= {};
      _userStatsCache![userId] = stats;
      _statsCacheTime = now;
      
      return stats;
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'totalTasks': 0,
        'completedTasks': 0,
        'totalSubjects': 0,
      };
    }
  }

  // Очистка кеша статистики
  void clearStatsCache() {
    _userStatsCache = null;
    _statsCacheTime = null;
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
  // Очистка всех данных пользователя
  Future<void> clearAllUserData() async {
    try {
      print('Clearing all user data for user: $currentUserId');

      // Удаляем все задачи и предметы из локальной базы
      await _sqlite.clearAllUserData(currentUserId);

      // Удаляем из Firebase если доступен
      if (_firebaseAvailable && isAuthenticatedUser) {
        await _clearFirebaseData();
      }

      // Сбрасываем профиль пользователя (но сохраняем основную информацию)
      final currentProfile = await getUserProfile(currentUserId);
      if (currentProfile != null) {
        final resetProfile = currentProfile.copyWith(
          totalTasks: 0,
          completedTasks: 0,
          totalSubjects: 0,
          // НЕ сбрасываем totalCompletedAllTime - это счетчик за всё время
        );
        await saveUserProfile(resetProfile);

        if (_firebaseAvailable && isAuthenticatedUser) {
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .set(resetProfile.toJson(), SetOptions(merge: true));
        }
      }

      // Сбрасываем время последней синхронизации
      await _sqlite.setSetting('last_sync_time', null, currentUserId);

      // Обновляем потоки данных
      _loadAndEmitTasks();
      _loadAndEmitSubjects();

      print('All user data cleared successfully');
    } catch (e) {
      print('Error clearing user data: $e');
      rethrow;
    }
  }

  Future<void> _clearFirebaseData() async {
    try {
      // Удаляем все задачи пользователя из Firebase
      final tasksQuery = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: currentUserId)
          .get();

      final batch = _firestore.batch();
      for (final doc in tasksQuery.docs) {
        batch.delete(doc.reference);
      }

      // Удаляем все предметы пользователя из Firebase
      final subjectsQuery = await _firestore
          .collection('subjects')
          .where('userId', isEqualTo: currentUserId)
          .get();

      for (final doc in subjectsQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Firebase data cleared successfully');
    } catch (e) {
      print('Error clearing Firebase data: $e');
      throw e;
    }
  }

  void dispose() {
    _tasksStreamController?.close();
    _subjectsStreamController?.close();
    _tasksSubscription?.cancel();
    _subjectsSubscription?.cancel();
    _connectivitySubscription?.cancel();
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    try {
      if (dateTime is Timestamp) {
        return dateTime.toDate();
      } else if (dateTime is int) {
        // Проверка на разумные границы для предотвращения переполнения
        if (dateTime < 0 || dateTime > 4102444800000) { // 1 января 2100
          return DateTime.now();
        }
        return DateTime.fromMillisecondsSinceEpoch(dateTime);
      } else if (dateTime is String) {
        return DateTime.parse(dateTime);
      }
    } catch (e) {
      // В случае ошибки парсинга возвращаем текущее время
      return DateTime.now();
    }
    return DateTime.now();
  }

  // Очистка старых удаленных записей
  Future<void> cleanupOldDeletedTasksFromCloud({int daysToKeep = 14}) async {
    if (!_firebaseAvailable || !isAuthenticatedUser) return;

    try {
      final userId = await getCurrentUserIdAsync();
      final cutoffTime = DateTime.now().subtract(Duration(days: daysToKeep));
      print('Cleaning up old deleted tasks from cloud older than $cutoffTime');

      final snapshot = await _firestore.collection('tasks')
          .where('userId', isEqualTo: userId)
          .where('is_deleted', isEqualTo: true)
          .where('updatedAt', isLessThan: Timestamp.fromDate(cutoffTime))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
        print('Cleaned up ${snapshot.docs.length} old deleted tasks from cloud');
      }
    } catch (e) {
      print('Error cleaning up old deleted tasks from cloud: $e');
    }
  }

  Future<void> cleanupOldDeletedSubjectsFromCloud({int daysToKeep = 14}) async {
    if (!_firebaseAvailable || !isAuthenticatedUser) return;

    try {
      final userId = await getCurrentUserIdAsync();
      final cutoffTime = DateTime.now().subtract(Duration(days: daysToKeep));
      print('Cleaning up old deleted subjects from cloud older than $cutoffTime');

      final snapshot = await _firestore.collection('subjects')
          .where('userId', isEqualTo: userId)
          .where('is_deleted', isEqualTo: true)
          .where('updatedAt', isLessThan: Timestamp.fromDate(cutoffTime))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
        print('Cleaned up ${snapshot.docs.length} old deleted subjects from cloud');
      }
    } catch (e) {
      print('Error cleaning up old deleted subjects from cloud: $e');
    }
  }

  Future<void> cleanupOldDeletedRecords({int daysToKeep = 14}) async {
    final userId = await getCurrentUserIdAsync();

    // Очищаем локальные записи
    await _sqlite.cleanupOldDeletedRecords(userId, daysToKeep: daysToKeep);

    // Очищаем записи из облака
    await cleanupOldDeletedTasksFromCloud(daysToKeep: daysToKeep);
    await cleanupOldDeletedSubjectsFromCloud(daysToKeep: daysToKeep);
  }
}