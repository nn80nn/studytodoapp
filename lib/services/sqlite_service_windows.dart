import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_windows.dart';
import '../models/subject_windows.dart';
import '../models/user_profile_windows.dart';

class SQLiteService {
  static final SQLiteService _instance = SQLiteService._internal();
  factory SQLiteService() => _instance;
  SQLiteService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'studytodo_windows.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // User profiles table
    await db.execute('''
      CREATE TABLE user_profiles (
        uid TEXT PRIMARY KEY,
        email TEXT,
        displayName TEXT,
        photoURL TEXT,
        isAnonymous INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        lastLoginAt INTEGER NOT NULL,
        totalTasks INTEGER NOT NULL DEFAULT 0,
        completedTasks INTEGER NOT NULL DEFAULT 0,
        totalSubjects INTEGER NOT NULL DEFAULT 0,
        totalCompletedAllTime INTEGER NOT NULL DEFAULT 0,
        geminiApiKey TEXT
      )
    ''');

    // Tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        subjectId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        deadline INTEGER NOT NULL,
        plannedTime INTEGER,
        priority INTEGER NOT NULL,
        status INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Subjects table
    await db.execute('''
      CREATE TABLE subjects (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        description TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        userId TEXT
      )
    ''');
  }

  // User Profile Methods
  Future<void> saveUserProfile(UserProfile profile) async {
    final db = await database;
    await db.insert(
      'user_profiles',
      profile.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final db = await database;
    final maps = await db.query(
      'user_profiles',
      where: 'uid = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return UserProfile.fromJson(maps.first);
    }
    return null;
  }

  // Settings Methods
  Future<void> saveSetting(String key, String value, [String? userId]) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'key': key,
        'value': value,
        'userId': userId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key, [String? userId]) async {
    final db = await database;
    final maps = await db.query(
      'settings',
      where: userId != null ? 'key = ? AND userId = ?' : 'key = ?',
      whereArgs: userId != null ? [key, userId] : [key],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  // Task Methods
  Future<List<Task>> getTasks(String userId) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'deadline ASC',
    );

    return maps.map((map) => Task.fromJson(map)).toList();
  }

  Future<void> saveTask(Task task) async {
    final db = await database;
    await db.insert(
      'tasks',
      task.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTask(String taskId) async {
    final db = await database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> markTaskCompleted(String taskId) async {
    final db = await database;
    await db.update(
      'tasks',
      {
        'status': TaskStatus.completed.index,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // Subject Methods
  Future<List<Subject>> getSubjects(String userId) async {
    final db = await database;
    final maps = await db.query(
      'subjects',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Subject.fromJson(map)).toList();
  }

  Future<void> saveSubject(Subject subject) async {
    final db = await database;
    await db.insert(
      'subjects',
      subject.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSubject(String subjectId) async {
    final db = await database;
    await db.delete(
      'subjects',
      where: 'id = ?',
      whereArgs: [subjectId],
    );
  }

  // Clear all user data
  Future<void> clearUserData(String userId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('tasks', where: 'userId = ?', whereArgs: [userId]);
      await txn.delete('subjects', where: 'userId = ?', whereArgs: [userId]);
      await txn.delete('user_profiles', where: 'uid = ?', whereArgs: [userId]);
      await txn.delete('settings', where: 'userId = ?', whereArgs: [userId]);
    });
  }

  // Ensure user exists
  Future<void> ensureUserExists(String userId) async {
    final profile = await getUserProfile(userId);
    if (profile == null) {
      final newProfile = UserProfile(
        uid: userId,
        email: null,
        displayName: 'Anonymous User',
        photoURL: null,
        isAnonymous: true,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        totalTasks: 0,
        completedTasks: 0,
        totalSubjects: 0,
        totalCompletedAllTime: 0,
        geminiApiKey: null,
      );
      await saveUserProfile(newProfile);
    }
  }

  // Database cleanup
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}