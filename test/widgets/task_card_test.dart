import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studytodoapp/models/task.dart';
import 'package:studytodoapp/models/subject.dart';

void main() {
  group('TaskCard Model Integration Tests', () {
    late Task testTask;
    late Subject testSubject;

    setUp(() {
      testSubject = Subject(
        id: 'subject1',
        name: 'Математика',
        color: Colors.blue,
        description: 'Тестовый предмет',
        createdAt: DateTime.now(),
      );

      testTask = Task(
        id: 'task1',
        subjectId: 'subject1',
        title: 'Тестовая задача',
        description: 'Описание задачи',
        deadline: DateTime.now().add(const Duration(days: 1)),
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
      );
    });

    testWidgets('should create task and subject models without errors', (WidgetTester tester) async {
      expect(testTask.title, 'Тестовая задача');
      expect(testSubject.name, 'Математика');
      expect(testTask.subjectId, testSubject.id);
    });

    testWidgets('should handle different task priorities', (WidgetTester tester) async {
      final priorities = [TaskPriority.low, TaskPriority.medium, TaskPriority.high];

      for (final priority in priorities) {
        final taskWithPriority = testTask.copyWith(priority: priority);
        expect(taskWithPriority.priority, priority);
        expect(taskWithPriority.title, testTask.title);
      }
    });

    testWidgets('should handle different task statuses', (WidgetTester tester) async {
      final statuses = [TaskStatus.pending, TaskStatus.completed, TaskStatus.overdue];

      for (final status in statuses) {
        final taskWithStatus = testTask.copyWith(status: status);
        expect(taskWithStatus.status, status);
        expect(taskWithStatus.title, testTask.title);
      }
    });

    testWidgets('should handle task without description', (WidgetTester tester) async {
      final taskWithoutDescription = Task(
        id: 'task2',
        subjectId: 'subject1',
        title: 'Задача без описания',
        deadline: DateTime.now().add(const Duration(days: 1)),
        priority: TaskPriority.low,
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
      );

      expect(taskWithoutDescription.description, isNull);
      expect(taskWithoutDescription.title, 'Задача без описания');
    });

    testWidgets('should handle subject color correctly', (WidgetTester tester) async {
      final coloredSubjects = [
        Subject(id: '1', name: 'Red', color: Colors.red, createdAt: DateTime.now()),
        Subject(id: '2', name: 'Blue', color: Colors.blue, createdAt: DateTime.now()),
        Subject(id: '3', name: 'Green', color: Colors.green, createdAt: DateTime.now()),
      ];

      expect(coloredSubjects[0].color, Colors.red);
      expect(coloredSubjects[1].color, Colors.blue);
      expect(coloredSubjects[2].color, Colors.green);
    });

    testWidgets('should handle completed task', (WidgetTester tester) async {
      final completedTask = testTask.copyWith(status: TaskStatus.completed);
      
      expect(completedTask.status, TaskStatus.completed);
      expect(completedTask.id, testTask.id);
    });

    testWidgets('should handle overdue task', (WidgetTester tester) async {
      final overdueTask = testTask.copyWith(
        status: TaskStatus.overdue,
        deadline: DateTime.now().subtract(const Duration(days: 1)),
      );
      
      expect(overdueTask.status, TaskStatus.overdue);
      expect(overdueTask.deadline.isBefore(DateTime.now()), true);
    });

    testWidgets('should handle task with planned time', (WidgetTester tester) async {
      final plannedTime = DateTime.now().add(const Duration(hours: 2));
      final taskWithPlannedTime = testTask.copyWith(plannedTime: plannedTime);
      
      expect(taskWithPlannedTime.plannedTime, plannedTime);
    });

    testWidgets('should handle edge cases', (WidgetTester tester) async {
      // Задача с очень длинным названием
      final longTitleTask = testTask.copyWith(
        title: 'Очень длинное название задачи, которое может не поместиться',
      );
      expect(longTitleTask.title.length, greaterThan(50));
      
      // Задача с очень длинным описанием
      final longDescTask = testTask.copyWith(
        description: 'Очень длинное описание задачи с множеством деталей и информации',
      );
      expect(longDescTask.description!.length, greaterThan(50));
    });

    testWidgets('should handle task serialization', (WidgetTester tester) async {
      final json = testTask.toJson();
      final deserializedTask = Task.fromJson(json);
      
      expect(deserializedTask.title, testTask.title);
      expect(deserializedTask.priority, testTask.priority);
      expect(deserializedTask.status, testTask.status);
    });

    testWidgets('should handle subject serialization', (WidgetTester tester) async {
      final json = testSubject.toJson();
      final deserializedSubject = Subject.fromJson(json);
      
      expect(deserializedSubject.name, testSubject.name);
      expect(deserializedSubject.color.value, testSubject.color.value);
    });
  });
}