import 'dart:async';
import 'dart:collection';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/subject.dart';

// Простой семафор для ограничения параллельных операций
class _Semaphore {
  final int maxCount;
  int _currentCount;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  _Semaphore(this.maxCount) : _currentCount = maxCount;

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    } else {
      final completer = Completer<void>();
      _waitQueue.add(completer);
      return completer.future;
    }
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      completer.complete();
    } else {
      _currentCount++;
    }
  }
}

class SQLiteService {
  static final SQLiteService _instance = SQLiteService._internal();
  factory SQLiteService() => _instance;
  SQLiteService._internal();

  static Database? _database;
  static Completer<Database>? _dbCompleter;
  static final _semaphore = _Semaphore(2); // До двух параллельных операций с БД

  // Прямая операция с базой данных (семафор временно отключен для отладки)
  Future<T> _safeDbOperation<T>(Future<T> Function(Database db) operation, [String? operationName]) async {
    final db = await database;
    return await operation(db);
  }
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Если база данных уже инициализируется, ждем ее завершения
    if (_dbCompleter != null && !_dbCompleter!.isCompleted) {
      return await _dbCompleter!.future;
    }
    
    // Создаем новый completer для этой инициализации
    _dbCompleter = Completer<Database>();
    
    try {
      _database = await _initDB();
      _dbCompleter!.complete(_database!);
      return _database!;
    } catch (e) {
      _dbCompleter!.completeError(e);
      _dbCompleter = null;
      rethrow;
    }
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'studytodo.db');
    
    return await openDatabase(
      path,
      version: 2, // Увеличиваем версию для пересоздания БД
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Таблица для пользователей (анонимные и авторизованные)
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL,
        last_sync_at INTEGER
      )
    ''');

    // Таблица для задач
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        subject_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        deadline INTEGER NOT NULL,
        planned_time INTEGER,
        priority INTEGER NOT NULL,
        status INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER,
        last_sync_at INTEGER,
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (subject_id) REFERENCES subjects (id)
      )
    ''');

    // Таблица для предметов
    await db.execute('''
      CREATE TABLE subjects (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        description TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER,
        last_sync_at INTEGER,
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Таблица для настроек
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT,
        user_id TEXT
      )
    ''');

    // Индексы для производительности
    await db.execute('CREATE INDEX idx_tasks_user_id ON tasks(user_id)');
    await db.execute('CREATE INDEX idx_tasks_subject_id ON tasks(subject_id)');
    await db.execute('CREATE INDEX idx_tasks_status ON tasks(status)');
    await db.execute('CREATE INDEX idx_tasks_updated_at ON tasks(updated_at)');
    await db.execute('CREATE INDEX idx_subjects_user_id ON subjects(user_id)');
    await db.execute('CREATE INDEX idx_subjects_updated_at ON subjects(updated_at)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Пересоздаём таблицы с исправленными именами столбцов
      await db.execute('DROP TABLE IF EXISTS tasks');
      await db.execute('DROP TABLE IF EXISTS subjects');
      await db.execute('DROP TABLE IF EXISTS settings');
      await db.execute('DROP TABLE IF EXISTS users');
      
      // Создаём таблицы заново
      await _createTables(db, newVersion);
    }
  }

  // Пользователи
  Future<void> ensureUserExists(String userId) async {
    return await _safeDbOperation<void>((db) async {
      final result = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (result.isEmpty) {
        await db.insert('users', {
          'id': userId,
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'last_sync_at': null,
        });
      }
    });
  }

  Future<void> updateUserLastSync(String userId, DateTime syncTime) async {
    return await _safeDbOperation<void>((db) async {
      await db.update(
        'users',
        {'last_sync_at': syncTime.millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [userId],
      );
    });
  }

  // Задачи
  Future<List<Task>> getTasks(String userId) async {
    return await _safeDbOperation<List<Task>>((db) async {
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        where: 'user_id = ? AND is_deleted = 0',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );

      return List.generate(maps.length, (i) {
        return Task.fromJson(maps[i]);
      });
    }, 'getTasks');
  }

  Future<Task?> getTask(String taskId, String userId) async {
    return await _safeDbOperation<Task?>((db) async {
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        where: 'id = ? AND user_id = ? AND is_deleted = 0',
        whereArgs: [taskId, userId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return Task.fromJson(maps.first);
      }
      return null;
    });
  }

  Future<void> insertOrUpdateTask(Task task, String userId) async {
    return await _safeDbOperation<void>((db) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final taskJson = task.toJson();
      final taskData = {
        'id': taskJson['id'],
        'subject_id': taskJson['subject_id'],
        'title': taskJson['title'],
        'description': taskJson['description'],
        'deadline': taskJson['deadline'],
        'planned_time': taskJson['planned_time'],
        'priority': taskJson['priority'],
        'status': taskJson['status'],
        'created_at': taskJson['created_at'],
        'updated_at': now,
        'last_sync_at': taskJson['last_sync_at'],
        'user_id': userId,
        'is_deleted': 0,
      };

      await db.insert(
        'tasks',
        taskData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> updateTask(Task task, String userId) async {
    return await _safeDbOperation<void>((db) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final taskJson = task.toJson();
      final taskData = {
        'id': taskJson['id'],
        'subject_id': taskJson['subject_id'],
        'title': taskJson['title'],
        'description': taskJson['description'],
        'deadline': taskJson['deadline'],
        'planned_time': taskJson['planned_time'],
        'priority': taskJson['priority'],
        'status': taskJson['status'],
        'created_at': taskJson['created_at'],
        'updated_at': now,
        'last_sync_at': taskJson['last_sync_at'],
      };

      await db.update(
        'tasks',
        taskData,
        where: 'id = ? AND user_id = ?',
        whereArgs: [task.id, userId],
      );
    });
  }

  Future<void> deleteTask(String taskId, String userId) async {
    return await _safeDbOperation<void>((db) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      await db.update(
        'tasks',
        {
          'is_deleted': 1,
          'updated_at': now,
        },
        where: 'id = ? AND user_id = ?',
        whereArgs: [taskId, userId],
      );
    });
  }

  Future<List<Task>> getTasksUpdatedAfter(String userId, DateTime timestamp) async {
    return await _safeDbOperation<List<Task>>((db) async {
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        where: 'user_id = ? AND updated_at > ?',
        whereArgs: [userId, timestamp.millisecondsSinceEpoch],
        orderBy: 'updated_at DESC',
      );

      return List.generate(maps.length, (i) {
        return Task.fromJson(maps[i]);
      });
    });
  }

  // Предметы
  Future<List<Subject>> getSubjects(String userId) async {
    return await _safeDbOperation<List<Subject>>((db) async {
      final List<Map<String, dynamic>> maps = await db.query(
        'subjects',
        where: 'user_id = ? AND is_deleted = 0',
        whereArgs: [userId],
        orderBy: 'created_at ASC',
      );

      return List.generate(maps.length, (i) {
        return Subject.fromJson(maps[i]);
      });
    }, 'getSubjects');
  }

  Future<Subject?> getSubject(String subjectId, String userId) async {
    return await _safeDbOperation<Subject?>((db) async {
      final List<Map<String, dynamic>> maps = await db.query(
        'subjects',
        where: 'id = ? AND user_id = ? AND is_deleted = 0',
        whereArgs: [subjectId, userId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return Subject.fromJson(maps.first);
      }
      return null;
    });
  }

  Future<void> insertOrUpdateSubject(Subject subject, String userId) async {
    return await _safeDbOperation<void>((db) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final subjectJson = subject.toJson();
      final subjectData = {
        'id': subjectJson['id'],
        'name': subjectJson['name'], 
        'color': subjectJson['color'],
        'description': subjectJson['description'],
        'created_at': subjectJson['created_at'],
        'updated_at': now,
        'last_sync_at': subjectJson['last_sync_at'],
        'user_id': userId,
        'is_deleted': 0,
      };

      await db.insert(
        'subjects',
        subjectData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> updateSubject(Subject subject, String userId) async {
    return await _safeDbOperation<void>((db) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final subjectJson = subject.toJson();
      final subjectData = {
        'id': subjectJson['id'],
        'name': subjectJson['name'],
        'color': subjectJson['color'],
        'description': subjectJson['description'],
        'created_at': subjectJson['created_at'],
        'updated_at': now,
        'last_sync_at': subjectJson['last_sync_at'],
      };

      await db.update(
        'subjects',
        subjectData,
        where: 'id = ? AND user_id = ?',
        whereArgs: [subject.id, userId],
      );
    });
  }

  Future<void> deleteSubject(String subjectId, String userId) async {
    return await _safeDbOperation<void>((db) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      await db.update(
        'subjects',
        {
          'is_deleted': 1,
          'updated_at': now,
        },
        where: 'id = ? AND user_id = ?',
        whereArgs: [subjectId, userId],
      );
    });
  }

  Future<List<Subject>> getSubjectsUpdatedAfter(String userId, DateTime timestamp) async {
    return await _safeDbOperation<List<Subject>>((db) async {
      final List<Map<String, dynamic>> maps = await db.query(
        'subjects',
        where: 'user_id = ? AND updated_at > ?',
        whereArgs: [userId, timestamp.millisecondsSinceEpoch],
        orderBy: 'updated_at DESC',
      );

      return List.generate(maps.length, (i) {
        return Subject.fromJson(maps[i]);
      });
    });
  }

  // Настройки
  Future<String?> getSetting(String key, [String? userId]) async {
    return await _safeDbOperation<String?>((db) async {
      String whereClause = 'key = ?';
      List<dynamic> whereArgs = [key];
      
      if (userId != null) {
        whereClause += ' AND user_id = ?';
        whereArgs.add(userId);
      } else {
        whereClause += ' AND user_id IS NULL';
      }
      
      final List<Map<String, dynamic>> maps = await db.query(
        'settings',
        where: whereClause,
        whereArgs: whereArgs,
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return maps.first['value'] as String?;
      }
      return null;
    });
  }

  Future<void> setSetting(String key, String? value, [String? userId]) async {
    return await _safeDbOperation<void>((db) async {
      await db.insert(
        'settings',
        {
          'key': key,
          'value': value,
          'user_id': userId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  // Очистка данных
  Future<void> clearUserData(String userId) async {
    return await _safeDbOperation<void>((db) async {
      await db.transaction((txn) async {
        await txn.delete('tasks', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('subjects', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('settings', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('users', where: 'id = ?', whereArgs: [userId]);
      });
    });
  }

  // Миграция данных между пользователями
  Future<void> migrateUserData(String fromUserId, String toUserId) async {
    return await _safeDbOperation<void>((db) async {
      await db.transaction((txn) async {
        // Обновляем задачи
        await txn.update(
          'tasks',
          {'user_id': toUserId, 'updated_at': DateTime.now().millisecondsSinceEpoch},
          where: 'user_id = ?',
          whereArgs: [fromUserId],
        );
        
        // Обновляем предметы
        await txn.update(
          'subjects',
          {'user_id': toUserId, 'updated_at': DateTime.now().millisecondsSinceEpoch},
          where: 'user_id = ?',
          whereArgs: [fromUserId],
        );
        
        // Обновляем настройки
        await txn.update(
          'settings',
          {'user_id': toUserId},
          where: 'user_id = ?',
          whereArgs: [fromUserId],
        );
        
        // Убеждаемся, что пользователь существует (внутри транзакции)
        final result = await txn.query(
          'users',
          where: 'id = ?',
          whereArgs: [toUserId],
          limit: 1,
        );

        if (result.isEmpty) {
          await txn.insert('users', {
            'id': toUserId,
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'last_sync_at': null,
          });
        }
        
        // Удаляем старого пользователя
        await txn.delete('users', where: 'id = ?', whereArgs: [fromUserId]);
      });
    });
  }

  // Получение статистики
  Future<Map<String, int>> getTaskStatistics(String userId) async {
    return await _safeDbOperation<Map<String, int>>((db) async {
      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as total,
          SUM(CASE WHEN status = ${TaskStatus.completed.index} THEN 1 ELSE 0 END) as completed,
          SUM(CASE WHEN status = ${TaskStatus.pending.index} THEN 1 ELSE 0 END) as pending,
          SUM(CASE WHEN status = ${TaskStatus.overdue.index} THEN 1 ELSE 0 END) as overdue
        FROM tasks 
        WHERE user_id = ? AND is_deleted = 0
      ''', [userId]);

      final row = result.first;
      return {
        'total': (row['total'] as int?) ?? 0,
        'completed': (row['completed'] as int?) ?? 0,
        'pending': (row['pending'] as int?) ?? 0,
        'overdue': (row['overdue'] as int?) ?? 0,
      };
    }, 'getTaskStatistics');
  }

  // Очистка всех данных пользователя
  Future<void> clearAllUserData(String userId) async {
    return await _safeDbOperation<void>((db) async {
      await db.transaction((txn) async {
        // Удаляем все задачи пользователя
        await txn.delete(
          'tasks',
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        // Удаляем все предметы пользователя
        await txn.delete(
          'subjects',
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        print('Cleared all data for user: $userId');
      });
    }, 'clearAllUserData');
  }

  // Закрытие БД
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}