import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/task_windows.dart' as windows_task;
import '../models/subject_windows.dart' as windows_subject;
import '../models/user_profile_windows.dart';
import 'sqlite_service_windows.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final SQLiteService _sqlite = SQLiteService();
  final Uuid _uuid = const Uuid();

  // Контроллеры для реал-тайм стримов
  StreamController<List<windows_task.Task>>? _tasksStreamController;
  StreamController<List<windows_subject.Subject>>? _subjectsStreamController;
  StreamController<UserProfile?>? _userStreamController;

  String? _currentUserId;

  Future<void> initialize() async {
    await _sqlite.database; // Инициализируем SQLite
    await _initializeCurrentUser();
  }

  Future<void> _initializeCurrentUser() async {
    // Пытаемся загрузить существующего пользователя
    final existingUserId = await _sqlite.getSetting('current_user_id');
    if (existingUserId != null) {
      _currentUserId = existingUserId;
      await _sqlite.ensureUserExists(existingUserId);
    } else {
      // Создаем нового анонимного пользователя для Windows
      await _initializeWindowsUser();
    }
  }

  Future<void> _initializeWindowsUser() async {
    final userId = _uuid.v4();
    _currentUserId = userId;

    // Создаем профиль пользователя Windows
    final userProfile = UserProfile.createAnonymous(userId);

    // Сохраняем в SQLite
    await _sqlite.saveUserProfile(userProfile);
    await _sqlite.saveSetting('current_user_id', userId);

    print('Создан пользователь Windows: $userId');
  }

  // Пользователи
  String? get currentUserId => _currentUserId;

  Future<UserProfile?> getCurrentUserProfile() async {
    if (_currentUserId == null) return null;
    return await _sqlite.getUserProfile(_currentUserId!);
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _sqlite.saveUserProfile(profile);
    _userStreamController?.add(profile);
  }

  Stream<UserProfile?> get userStream {
    _userStreamController ??= StreamController<UserProfile?>.broadcast();
    return _userStreamController!.stream;
  }

  // Создание локального аккаунта для Windows
  Future<UserProfile> createLocalAccount({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final userId = _uuid.v4();
    _currentUserId = userId;

    final userProfile = UserProfile.createLocal(
      uid: userId,
      email: email,
      displayName: displayName,
    );

    await _sqlite.saveUserProfile(userProfile);
    await _sqlite.saveSetting('current_user_id', userId);
    await _sqlite.saveSetting('user_email', email);

    // Для безопасности пароль сохраним хешированным (упрощенно)
    await _sqlite.saveSetting('user_password_hash', password.hashCode.toString());

    _userStreamController?.add(userProfile);
    return userProfile;
  }

  // Вход в локальный аккаунт
  Future<UserProfile?> signInLocal({
    required String email,
    required String password,
  }) async {
    final savedEmail = await _sqlite.getSetting('user_email');
    final savedPasswordHash = await _sqlite.getSetting('user_password_hash');

    if (savedEmail == email && savedPasswordHash == password.hashCode.toString()) {
      final userId = await _sqlite.getSetting('current_user_id');
      if (userId != null) {
        _currentUserId = userId;
        final profile = await _sqlite.getUserProfile(userId);
        if (profile != null) {
          final updatedProfile = profile.copyWith(lastLoginAt: DateTime.now());
          await updateUserProfile(updatedProfile);
          return updatedProfile;
        }
      }
    }
    return null;
  }

  // Выход из аккаунта
  Future<void> signOut() async {
    _currentUserId = null;
    await _sqlite.saveSetting('current_user_id', '');
    _userStreamController?.add(null);

    // Создаем нового анонимного пользователя
    await _initializeWindowsUser();
  }

  // Задачи
  Future<List<windows_task.Task>> getTasks() async {
    if (_currentUserId == null) return [];
    return await _sqlite.getTasks(_currentUserId!);
  }

  Future<void> saveTask(windows_task.Task task) async {
    await _sqlite.saveTask(task);
    _notifyTasksChanged();
    await _updateUserStats();
  }

  Future<void> deleteTask(String taskId) async {
    await _sqlite.deleteTask(taskId);
    _notifyTasksChanged();
    await _updateUserStats();
  }

  Future<void> markTaskCompleted(String taskId) async {
    await _sqlite.markTaskCompleted(taskId);
    await _incrementTotalCompletedAllTime();
    _notifyTasksChanged();
    await _updateUserStats();
  }

  Stream<List<windows_task.Task>> get tasksStream {
    _tasksStreamController ??= StreamController<List<windows_task.Task>>.broadcast();
    return _tasksStreamController!.stream;
  }

  void _notifyTasksChanged() async {
    if (_currentUserId != null) {
      final tasks = await getTasks();
      _tasksStreamController?.add(tasks);
    }
  }

  // Предметы
  Future<List<windows_subject.Subject>> getSubjects() async {
    if (_currentUserId == null) return [];
    return await _sqlite.getSubjects(_currentUserId!);
  }

  Future<void> saveSubject(windows_subject.Subject subject) async {
    await _sqlite.saveSubject(subject);
    _notifySubjectsChanged();
    await _updateUserStats();
  }

  Future<void> deleteSubject(String subjectId) async {
    await _sqlite.deleteSubject(subjectId);
    _notifySubjectsChanged();
    await _updateUserStats();
  }

  Stream<List<windows_subject.Subject>> get subjectsStream {
    _subjectsStreamController ??= StreamController<List<windows_subject.Subject>>.broadcast();
    return _subjectsStreamController!.stream;
  }

  void _notifySubjectsChanged() async {
    if (_currentUserId != null) {
      final subjects = await getSubjects();
      _subjectsStreamController?.add(subjects);
    }
  }

  // Статистика
  Future<void> _updateUserStats() async {
    if (_currentUserId == null) return;

    final profile = await getCurrentUserProfile();
    if (profile == null) return;

    final tasks = await getTasks();
    final subjects = await getSubjects();

    final totalTasks = tasks.where((t) => !t.isDeleted).length;
    final completedTasks = tasks.where((t) => !t.isDeleted && t.status == windows_task.TaskStatus.completed).length;
    final totalSubjects = subjects.where((s) => !s.isDeleted).length;

    final updatedProfile = profile.copyWith(
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      totalSubjects: totalSubjects,
    );

    await updateUserProfile(updatedProfile);
  }

  Future<void> _incrementTotalCompletedAllTime() async {
    if (_currentUserId == null) return;

    final profile = await getCurrentUserProfile();
    if (profile != null) {
      final updatedProfile = profile.copyWith(
        totalCompletedAllTime: profile.totalCompletedAllTime + 1,
      );
      await updateUserProfile(updatedProfile);
    }
  }

  // Очистка данных
  Future<void> clearAllUserData() async {
    if (_currentUserId == null) return;

    final profile = await getCurrentUserProfile();
    if (profile == null) return;

    // Удаляем все задачи и предметы
    await _sqlite.clearUserData(_currentUserId!);

    // Сохраняем только статистику всех времен
    final clearedProfile = profile.copyWith(
      totalTasks: 0,
      completedTasks: 0,
      totalSubjects: 0,
      // totalCompletedAllTime остается неизменным!
    );

    await updateUserProfile(clearedProfile);

    // Уведомляем об изменениях
    _notifyTasksChanged();
    _notifySubjectsChanged();
  }

  // Создание демо данных для тестирования
  Future<void> createDemoData() async {
    if (_currentUserId == null) return;

    // Создаем предметы
    final subjects = [
      windows_subject.Subject(
        id: _uuid.v4(),
        userId: _currentUserId!,
        name: 'Математика',
        color: windows_subject.Subject.predefinedColors[0].value,
        description: 'Высшая математика и алгебра',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      windows_subject.Subject(
        id: _uuid.v4(),
        userId: _currentUserId!,
        name: 'Физика',
        color: windows_subject.Subject.predefinedColors[1].value,
        description: 'Общая и теоретическая физика',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      windows_subject.Subject(
        id: _uuid.v4(),
        userId: _currentUserId!,
        name: 'Программирование',
        color: windows_subject.Subject.predefinedColors[2].value,
        description: 'Разработка приложений',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final subject in subjects) {
      await saveSubject(subject);
    }

    // Создаем задачи
    final now = DateTime.now();
    final tasks = [
      windows_task.Task(
        id: _uuid.v4(),
        userId: _currentUserId!,
        subjectId: subjects[0].id,
        title: 'Решить интегралы',
        description: 'Упражнения 1-15 из главы 8',
        deadline: now.add(const Duration(days: 2)),
        plannedTime: 120,
        priority: windows_task.TaskPriority.high,
        status: windows_task.TaskStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
      windows_task.Task(
        id: _uuid.v4(),
        userId: _currentUserId!,
        subjectId: subjects[1].id,
        title: 'Лабораторная работа по оптике',
        description: 'Измерение показателя преломления',
        deadline: now.add(const Duration(days: 5)),
        plannedTime: 180,
        priority: windows_task.TaskPriority.medium,
        status: windows_task.TaskStatus.inProgress,
        createdAt: now,
        updatedAt: now,
      ),
      windows_task.Task(
        id: _uuid.v4(),
        userId: _currentUserId!,
        subjectId: subjects[2].id,
        title: 'Создать Flutter приложение',
        description: 'Разработать StudyToDo для Windows',
        deadline: now.add(const Duration(days: 1)),
        plannedTime: 480,
        priority: windows_task.TaskPriority.high,
        status: windows_task.TaskStatus.completed,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now,
      ),
    ];

    for (final task in tasks) {
      await saveTask(task);
    }

    print('Созданы демо данные: ${subjects.length} предметов, ${tasks.length} задач');
  }

  // Очистка ресурсов
  void dispose() {
    _tasksStreamController?.close();
    _subjectsStreamController?.close();
    _userStreamController?.close();
  }
}