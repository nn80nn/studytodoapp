import 'package:flutter_test/flutter_test.dart';
import 'package:studytodoapp/models/task.dart';

void main() {
  group('Task Model Tests', () {
    final DateTime testDeadline = DateTime(2024, 3, 15);
    final DateTime testCreatedAt = DateTime(2024, 3, 1);
    final DateTime testPlannedTime = DateTime(2024, 3, 14, 10, 30);

    Task createTestTask() {
      return Task(
        id: 'test_id',
        subjectId: 'subject_1',
        title: 'Тестовая задача',
        description: 'Описание тестовой задачи',
        deadline: testDeadline,
        plannedTime: testPlannedTime,
        priority: TaskPriority.high,
        status: TaskStatus.pending,
        createdAt: testCreatedAt,
      );
    }

    test('should create Task with required fields only', () {
      final task = Task(
        id: 'test_id',
        subjectId: 'subject_1',
        title: 'Минимальная задача',
        deadline: testDeadline,
        createdAt: testCreatedAt,
      );

      expect(task.id, 'test_id');
      expect(task.subjectId, 'subject_1');
      expect(task.title, 'Минимальная задача');
      expect(task.description, isNull);
      expect(task.deadline, testDeadline);
      expect(task.plannedTime, isNull);
      expect(task.priority, TaskPriority.medium);
      expect(task.status, TaskStatus.pending);
      expect(task.createdAt, testCreatedAt);
    });

    test('should create Task with all fields', () {
      final task = createTestTask();

      expect(task.id, 'test_id');
      expect(task.subjectId, 'subject_1');
      expect(task.title, 'Тестовая задача');
      expect(task.description, 'Описание тестовой задачи');
      expect(task.deadline, testDeadline);
      expect(task.plannedTime, testPlannedTime);
      expect(task.priority, TaskPriority.high);
      expect(task.status, TaskStatus.pending);
      expect(task.createdAt, testCreatedAt);
    });

    test('should create copy with modified fields', () {
      final originalTask = createTestTask();
      final modifiedTask = originalTask.copyWith(
        title: 'Измененная задача',
        status: TaskStatus.completed,
        priority: TaskPriority.low,
      );

      expect(modifiedTask.id, originalTask.id);
      expect(modifiedTask.subjectId, originalTask.subjectId);
      expect(modifiedTask.title, 'Измененная задача');
      expect(modifiedTask.description, originalTask.description);
      expect(modifiedTask.deadline, originalTask.deadline);
      expect(modifiedTask.plannedTime, originalTask.plannedTime);
      expect(modifiedTask.priority, TaskPriority.low);
      expect(modifiedTask.status, TaskStatus.completed);
      expect(modifiedTask.createdAt, originalTask.createdAt);
    });

    test('should convert to JSON correctly', () {
      final task = createTestTask();
      final json = task.toJson();

      expect(json['id'], 'test_id');
      expect(json['subjectId'], 'subject_1');
      expect(json['title'], 'Тестовая задача');
      expect(json['description'], 'Описание тестовой задачи');
      expect(json['deadline'], testDeadline.millisecondsSinceEpoch);
      expect(json['plannedTime'], testPlannedTime.millisecondsSinceEpoch);
      expect(json['priority'], TaskPriority.high.index);
      expect(json['status'], TaskStatus.pending.index);
      expect(json['createdAt'], testCreatedAt.millisecondsSinceEpoch);
    });

    test('should convert to JSON with null values', () {
      final task = Task(
        id: 'test_id',
        subjectId: 'subject_1',
        title: 'Задача без описания',
        deadline: testDeadline,
        createdAt: testCreatedAt,
      );
      final json = task.toJson();

      expect(json['description'], isNull);
      expect(json['plannedTime'], isNull);
      expect(json['priority'], TaskPriority.medium.index);
      expect(json['status'], TaskStatus.pending.index);
    });

    test('should create Task from JSON correctly', () {
      final json = {
        'id': 'test_id',
        'subjectId': 'subject_1',
        'title': 'Тестовая задача',
        'description': 'Описание тестовой задачи',
        'deadline': testDeadline.millisecondsSinceEpoch,
        'plannedTime': testPlannedTime.millisecondsSinceEpoch,
        'priority': TaskPriority.high.index,
        'status': TaskStatus.completed.index,
        'createdAt': testCreatedAt.millisecondsSinceEpoch,
      };

      final task = Task.fromJson(json);

      expect(task.id, 'test_id');
      expect(task.subjectId, 'subject_1');
      expect(task.title, 'Тестовая задача');
      expect(task.description, 'Описание тестовой задачи');
      expect(task.deadline, testDeadline);
      expect(task.plannedTime, testPlannedTime);
      expect(task.priority, TaskPriority.high);
      expect(task.status, TaskStatus.completed);
      expect(task.createdAt, testCreatedAt);
    });

    test('should create Task from JSON with null values', () {
      final json = {
        'id': 'test_id',
        'subjectId': 'subject_1',
        'title': 'Задача без описания',
        'description': null,
        'deadline': testDeadline.millisecondsSinceEpoch,
        'plannedTime': null,
        'createdAt': testCreatedAt.millisecondsSinceEpoch,
      };

      final task = Task.fromJson(json);

      expect(task.description, isNull);
      expect(task.plannedTime, isNull);
      expect(task.priority, TaskPriority.medium);
      expect(task.status, TaskStatus.pending);
    });

    test('should handle invalid priority index in JSON', () {
      final json = {
        'id': 'test_id',
        'subjectId': 'subject_1',
        'title': 'Задача',
        'deadline': testDeadline.millisecondsSinceEpoch,
        'priority': 999,
        'createdAt': testCreatedAt.millisecondsSinceEpoch,
      };

      expect(() => Task.fromJson(json), throwsRangeError);
    });

    test('should handle invalid status index in JSON', () {
      final json = {
        'id': 'test_id',
        'subjectId': 'subject_1',
        'title': 'Задача',
        'deadline': testDeadline.millisecondsSinceEpoch,
        'status': 999,
        'createdAt': testCreatedAt.millisecondsSinceEpoch,
      };

      expect(() => Task.fromJson(json), throwsRangeError);
    });
  });

  group('TaskPriority Tests', () {
    test('should have correct values', () {
      expect(TaskPriority.values, [TaskPriority.low, TaskPriority.medium, TaskPriority.high]);
      expect(TaskPriority.low.index, 0);
      expect(TaskPriority.medium.index, 1);
      expect(TaskPriority.high.index, 2);
    });
  });

  group('TaskStatus Tests', () {
    test('should have correct values', () {
      expect(TaskStatus.values, [TaskStatus.pending, TaskStatus.completed, TaskStatus.overdue]);
      expect(TaskStatus.pending.index, 0);
      expect(TaskStatus.completed.index, 1);
      expect(TaskStatus.overdue.index, 2);
    });
  });
}