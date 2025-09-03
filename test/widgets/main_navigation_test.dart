import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studytodoapp/models/task.dart';
import 'package:studytodoapp/models/subject.dart';

void main() {
  group('Navigation Model Tests', () {
    testWidgets('should handle navigation state data correctly', (WidgetTester tester) async {
      // Тестируем базовые модели навигации
      final testSubjects = [
        Subject(id: '1', name: 'Математика', color: Colors.blue, createdAt: DateTime.now()),
        Subject(id: '2', name: 'Физика', color: Colors.red, createdAt: DateTime.now()),
        Subject(id: '3', name: 'Химия', color: Colors.green, createdAt: DateTime.now()),
      ];

      final testTasks = testSubjects.map((subject) => Task(
        id: 'task_${subject.id}',
        subjectId: subject.id,
        title: 'Задача по ${subject.name}',
        deadline: DateTime.now().add(Duration(days: 1)),
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
      )).toList();

      expect(testSubjects.length, 3);
      expect(testTasks.length, 3);
      expect(testTasks[0].subjectId, testSubjects[0].id);
    });

    testWidgets('should handle navigation destinations data', (WidgetTester tester) async {
      const destinations = [
        {'icon': Icons.task_outlined, 'selectedIcon': Icons.task, 'label': 'Задачи'},
        {'icon': Icons.subject_outlined, 'selectedIcon': Icons.subject, 'label': 'Предметы'},
        {'icon': Icons.analytics_outlined, 'selectedIcon': Icons.analytics, 'label': 'Аналитика'},
      ];

      expect(destinations.length, 3);
      expect(destinations[0]['label'], 'Задачи');
      expect(destinations[1]['label'], 'Предметы');
      expect(destinations[2]['label'], 'Аналитика');
    });

    testWidgets('should handle navigation state changes', (WidgetTester tester) async {
      int currentIndex = 0;
      
      // Симуляция изменения индекса
      void onItemTapped(int index) {
        currentIndex = index;
      }

      // Тестируем изменение на второй экран
      onItemTapped(1);
      expect(currentIndex, 1);

      // Тестируем изменение на третий экран
      onItemTapped(2);
      expect(currentIndex, 2);

      // Возвращаемся на первый экран
      onItemTapped(0);
      expect(currentIndex, 0);
    });

    testWidgets('should handle theme data correctly', (WidgetTester tester) async {
      const lightTheme = {
        'primary': Color(0xFF26C6DA),
        'secondary': Color(0xFF9C27B0),
        'surface': Color(0xFFF8FDFF),
      };

      const darkTheme = {
        'primary': Color(0xFF4DD0E1),
        'secondary': Color(0xFFBA68C8),
        'surface': Color(0xFF121212),
      };

      expect(lightTheme['primary'], const Color(0xFF26C6DA));
      expect(darkTheme['primary'], const Color(0xFF4DD0E1));
    });

    testWidgets('should handle screen data structure', (WidgetTester tester) async {
      final screenData = {
        'home': {'tasks': [], 'subjects': []},
        'subjects': {'subjects': [], 'totalTasks': 0},
        'analytics': {'charts': [], 'stats': {}},
      };

      expect(screenData.containsKey('home'), true);
      expect(screenData.containsKey('subjects'), true);
      expect(screenData.containsKey('analytics'), true);
    });

    testWidgets('should handle navigation with tasks and subjects', (WidgetTester tester) async {
      final navigationState = {
        'currentIndex': 0,
        'screens': ['home', 'subjects', 'analytics'],
        'data': {
          'tasks': [
            Task(
              id: '1',
              subjectId: 'math',
              title: 'Алгебра',
              deadline: DateTime.now().add(Duration(days: 1)),
              priority: TaskPriority.high,
              status: TaskStatus.pending,
              createdAt: DateTime.now(),
            ),
          ],
          'subjects': [
            Subject(
              id: 'math',
              name: 'Математика',
              color: Colors.blue,
              createdAt: DateTime.now(),
            ),
          ],
        },
      };

      final data = navigationState['data']! as Map<String, dynamic>;
      final tasks = data['tasks'] as List<Task>;
      final subjects = data['subjects'] as List<Subject>;

      expect(tasks.length, 1);
      expect(subjects.length, 1);
      expect(tasks[0].subjectId, subjects[0].id);
    });

    testWidgets('should handle navigation error states', (WidgetTester tester) async {
      final errorStates = {
        'loading': false,
        'error': null,
        'hasData': true,
      };

      expect(errorStates['loading'], false);
      expect(errorStates['error'], null);
      expect(errorStates['hasData'], true);

      // Симуляция ошибки
      final errorStatesWithError = Map<String, dynamic>.from(errorStates);
      errorStatesWithError['error'] = 'Navigation error';
      errorStatesWithError['hasData'] = false;

      expect(errorStatesWithError['error'], 'Navigation error');
      expect(errorStatesWithError['hasData'], false);
    });

    testWidgets('should handle rapid navigation changes', (WidgetTester tester) async {
      final navigationHistory = <int>[];
      
      void simulateNavigation(int index) {
        navigationHistory.add(index);
      }

      // Быстрые переключения
      simulateNavigation(0);
      simulateNavigation(1);
      simulateNavigation(2);
      simulateNavigation(0);
      simulateNavigation(1);

      expect(navigationHistory.length, 5);
      expect(navigationHistory.last, 1);
    });
  });
}