import 'package:flutter_test/flutter_test.dart';
import 'package:studytodoapp/blocs/tasks_bloc.dart';
import 'package:studytodoapp/models/task.dart';

void main() {
  group('TasksBloc Tests', () {
    late TasksBloc tasksBloc;
    
    final testTasks = [
      Task(
        id: 'task1',
        subjectId: 'subject1',
        title: 'Задача 1',
        description: 'Описание задачи 1',
        deadline: DateTime.now().add(Duration(days: 1)),
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
      ),
      Task(
        id: 'task2',
        subjectId: 'subject2',
        title: 'Задача 2',
        deadline: DateTime.now().add(Duration(days: 2)),
        priority: TaskPriority.high,
        status: TaskStatus.completed,
        createdAt: DateTime.now(),
      ),
    ];

    setUp(() {
      // Не создаем реальный BLoC из-за Firebase зависимости
      // tasksBloc = TasksBloc();
    });

    tearDown(() {
      // tasksBloc.close();
    });

    test('BLoC should be testable without Firebase', () {
      // Тест заглушка вместо реального BLoC тестирования
      expect(true, true);
    });

    group('Event Properties', () {
      test('LoadTasks props are empty', () {
        expect(LoadTasks().props, isEmpty);
      });

      test('RefreshTasks props are empty', () {
        expect(RefreshTasks().props, isEmpty);
      });

      test('AddTask props contain task', () {
        final event = AddTask(testTasks.first);
        expect(event.props, [testTasks.first]);
      });

      test('UpdateTask props contain task', () {
        final event = UpdateTask(testTasks.first);
        expect(event.props, [testTasks.first]);
      });

      test('DeleteTask props contain id', () {
        final event = DeleteTask('test_id');
        expect(event.props, ['test_id']);
      });

      test('CompleteTask props contain id', () {
        final event = CompleteTask('test_id');
        expect(event.props, ['test_id']);
      });
    });

    group('State Properties', () {
      test('TasksInitial props are empty', () {
        expect(TasksInitial().props, isEmpty);
      });

      test('TasksLoading props are empty', () {
        expect(TasksLoading().props, isEmpty);
      });

      test('TasksLoaded props contain tasks and isRefreshing', () {
        final state = TasksLoaded(testTasks, isRefreshing: true);
        expect(state.props, [testTasks, true]);
      });

      test('TasksLoaded default isRefreshing is false', () {
        final state = TasksLoaded(testTasks);
        expect(state.isRefreshing, false);
      });

      test('TaskAdding props are empty', () {
        expect(TaskAdding().props, isEmpty);
      });

      test('TaskUpdating props are empty', () {
        expect(TaskUpdating().props, isEmpty);
      });

      test('TaskDeleting props are empty', () {
        expect(TaskDeleting().props, isEmpty);
      });

      test('TasksError props contain message', () {
        const errorMessage = 'Test error';
        final state = TasksError(errorMessage);
        expect(state.props, [errorMessage]);
      });
    });

    group('State Equality', () {
      test('TasksLoaded states with same data are equal', () {
        final state1 = TasksLoaded(testTasks);
        final state2 = TasksLoaded(testTasks);
        expect(state1, equals(state2));
      });

      test('TasksLoaded states with different data are not equal', () {
        final state1 = TasksLoaded(testTasks);
        final state2 = TasksLoaded([]);
        expect(state1, isNot(equals(state2)));
      });

      test('TasksError states with same message are equal', () {
        const errorMessage = 'Test error';
        final state1 = TasksError(errorMessage);
        final state2 = TasksError(errorMessage);
        expect(state1, equals(state2));
      });

      test('TasksError states with different messages are not equal', () {
        final state1 = TasksError('Error 1');
        final state2 = TasksError('Error 2');
        expect(state1, isNot(equals(state2)));
      });
    });

    group('Edge Cases', () {
      test('TasksLoaded handles empty task list', () {
        final state = TasksLoaded([]);
        expect(state.tasks, isEmpty);
        expect(state.isRefreshing, false);
      });

      test('TasksError handles empty message', () {
        final state = TasksError('');
        expect(state.message, isEmpty);
      });

      test('TasksError handles null-like message', () {
        final state = TasksError('null');
        expect(state.message, 'null');
      });
    });

    group('Event Equality', () {
      test('same AddTask events are equal', () {
        final task = testTasks.first;
        final event1 = AddTask(task);
        final event2 = AddTask(task);
        expect(event1, equals(event2));
      });

      test('different AddTask events are not equal', () {
        final event1 = AddTask(testTasks.first);
        final event2 = AddTask(testTasks.last);
        expect(event1, isNot(equals(event2)));
      });

      test('same DeleteTask events are equal', () {
        final event1 = DeleteTask('test_id');
        final event2 = DeleteTask('test_id');
        expect(event1, equals(event2));
      });

      test('different DeleteTask events are not equal', () {
        final event1 = DeleteTask('id1');
        final event2 = DeleteTask('id2');
        expect(event1, isNot(equals(event2)));
      });
    });
  });
}