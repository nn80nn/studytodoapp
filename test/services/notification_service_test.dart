import 'package:flutter_test/flutter_test.dart';
import 'package:studytodoapp/services/notification_service.dart';
import 'package:studytodoapp/models/task.dart';

void main() {
  group('NotificationService Tests', () {
    late NotificationService notificationService;

    setUp(() {
      notificationService = NotificationService();
    });

    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = NotificationService();
        final instance2 = NotificationService();
        
        expect(identical(instance1, instance2), true);
      });
    });

    group('Initialize', () {
      test('should initialize without throwing exception', () async {
        await expectLater(notificationService.initialize(), completes);
      });

      test('should initialize multiple times without error', () async {
        await notificationService.initialize();
        await expectLater(notificationService.initialize(), completes);
      });
    });

    group('Task Reminder', () {
      test('should schedule task reminder without throwing exception', () async {
        final testTask = Task(
          id: 'test_id',
          subjectId: 'subject_id',
          title: 'Тестовая задача',
          description: 'Описание задачи',
          deadline: DateTime.now().add(Duration(days: 1)),
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        );

        await expectLater(
          notificationService.scheduleTaskReminder(testTask), 
          completes
        );
      });

      test('should handle task with null description', () async {
        final testTask = Task(
          id: 'test_id',
          subjectId: 'subject_id',
          title: 'Задача без описания',
          deadline: DateTime.now().add(Duration(days: 1)),
          priority: TaskPriority.low,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        );

        await expectLater(
          notificationService.scheduleTaskReminder(testTask), 
          completes
        );
      });

      test('should handle task with past deadline', () async {
        final testTask = Task(
          id: 'test_id',
          subjectId: 'subject_id',
          title: 'Просроченная задача',
          deadline: DateTime.now().subtract(Duration(days: 1)),
          priority: TaskPriority.high,
          status: TaskStatus.overdue,
          createdAt: DateTime.now().subtract(Duration(days: 2)),
        );

        await expectLater(
          notificationService.scheduleTaskReminder(testTask), 
          completes
        );
      });

      test('should handle tasks with different priorities', () async {
        final priorities = [TaskPriority.low, TaskPriority.medium, TaskPriority.high];

        for (final priority in priorities) {
          final testTask = Task(
            id: 'test_id_${priority.index}',
            subjectId: 'subject_id',
            title: 'Задача с приоритетом ${priority.name}',
            deadline: DateTime.now().add(Duration(days: 1)),
            priority: priority,
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
          );

          await expectLater(
            notificationService.scheduleTaskReminder(testTask), 
            completes
          );
        }
      });

      test('should handle tasks with different statuses', () async {
        final statuses = [TaskStatus.pending, TaskStatus.completed, TaskStatus.overdue];

        for (final status in statuses) {
          final testTask = Task(
            id: 'test_id_${status.index}',
            subjectId: 'subject_id',
            title: 'Задача со статусом ${status.name}',
            deadline: DateTime.now().add(Duration(days: 1)),
            priority: TaskPriority.medium,
            status: status,
            createdAt: DateTime.now(),
          );

          await expectLater(
            notificationService.scheduleTaskReminder(testTask), 
            completes
          );
        }
      });
    });

    group('Motivational Notification', () {
      test('should schedule motivational notification without throwing exception', () async {
        await expectLater(
          notificationService.scheduleMotivationalNotification(), 
          completes
        );
      });

      test('should schedule multiple motivational notifications', () async {
        for (int i = 0; i < 3; i++) {
          await expectLater(
            notificationService.scheduleMotivationalNotification(), 
            completes
          );
        }
      });
    });

    group('Service State', () {
      test('should work correctly after initialization', () async {
        await notificationService.initialize();

        final testTask = Task(
          id: 'test_id',
          subjectId: 'subject_id',
          title: 'Задача после инициализации',
          deadline: DateTime.now().add(Duration(hours: 2)),
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        );

        await expectLater(
          notificationService.scheduleTaskReminder(testTask), 
          completes
        );

        await expectLater(
          notificationService.scheduleMotivationalNotification(), 
          completes
        );
      });
    });

    group('Error Resistance', () {
      test('should handle rapid successive calls', () async {
        final testTask = Task(
          id: 'rapid_test',
          subjectId: 'subject_id',
          title: 'Быстрая задача',
          deadline: DateTime.now().add(Duration(minutes: 30)),
          priority: TaskPriority.high,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        );

        // Быстро вызываем несколько раз подряд
        final futures = List.generate(5, (index) => 
          notificationService.scheduleTaskReminder(testTask)
        );

        await expectLater(Future.wait(futures), completes);
      });
    });
  });
}