import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studytodoapp/models/task.dart';
import 'package:studytodoapp/models/subject.dart';
import 'package:studytodoapp/blocs/tasks_bloc.dart';
import 'package:studytodoapp/blocs/subjects_bloc.dart';

/// Помощники для создания тестовых данных и виджетов

class TestHelpers {
  /// Создает тестовую задачу с базовыми параметрами
  static Task createTestTask({
    String? id,
    String? subjectId,
    String? title,
    String? description,
    DateTime? deadline,
    DateTime? plannedTime,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? 'test_task_id',
      subjectId: subjectId ?? 'test_subject_id',
      title: title ?? 'Тестовая задача',
      description: description,
      deadline: deadline ?? DateTime.now().add(const Duration(days: 7)),
      plannedTime: plannedTime,
      priority: priority ?? TaskPriority.medium,
      status: status ?? TaskStatus.pending,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Создает тестовый предмет с базовыми параметрами
  static Subject createTestSubject({
    String? id,
    String? name,
    Color? color,
    String? description,
    DateTime? createdAt,
  }) {
    return Subject(
      id: id ?? 'test_subject_id',
      name: name ?? 'Тестовый предмет',
      color: color ?? Colors.blue,
      description: description,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Создает список тестовых задач
  static List<Task> createTestTasks({int count = 3}) {
    return List.generate(count, (index) => createTestTask(
      id: 'task_$index',
      title: 'Задача $index',
      priority: TaskPriority.values[index % TaskPriority.values.length],
      status: TaskStatus.values[index % TaskStatus.values.length],
    ));
  }

  /// Создает список тестовых предметов
  static List<Subject> createTestSubjects({int count = 3}) {
    final colors = [Colors.blue, Colors.red, Colors.green, Colors.purple, Colors.orange];
    return List.generate(count, (index) => createTestSubject(
      id: 'subject_$index',
      name: 'Предмет $index',
      color: colors[index % colors.length],
      description: index % 2 == 0 ? 'Описание предмета $index' : null,
    ));
  }

  /// Создает MaterialApp для тестирования с BLoC провайдерами
  static Widget createTestApp({
    required Widget child,
    TasksBloc? tasksBloc,
    SubjectsBloc? subjectsBloc,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<TasksBloc>.value(value: tasksBloc ?? TasksBloc()),
          BlocProvider<SubjectsBloc>.value(value: subjectsBloc ?? SubjectsBloc()),
        ],
        child: child,
      ),
    );
  }

  /// Создает Scaffold для тестирования виджетов
  static Widget createTestScaffold(Widget child) {
    return Scaffold(
      body: child,
    );
  }

  /// Создает задачу с просроченным дедлайном
  static Task createOverdueTask({
    String? id,
    String? title,
    int daysOverdue = 1,
  }) {
    return createTestTask(
      id: id,
      title: title ?? 'Просроченная задача',
      deadline: DateTime.now().subtract(Duration(days: daysOverdue)),
      status: TaskStatus.overdue,
    );
  }

  /// Создает завершенную задачу
  static Task createCompletedTask({
    String? id,
    String? title,
  }) {
    return createTestTask(
      id: id,
      title: title ?? 'Завершенная задача',
      status: TaskStatus.completed,
    );
  }

  /// Создает задачу с высоким приоритетом
  static Task createHighPriorityTask({
    String? id,
    String? title,
  }) {
    return createTestTask(
      id: id,
      title: title ?? 'Важная задача',
      priority: TaskPriority.high,
    );
  }

  /// Создает задачу с планируемым временем выполнения
  static Task createTaskWithPlannedTime({
    String? id,
    String? title,
    DateTime? plannedTime,
  }) {
    return createTestTask(
      id: id,
      title: title ?? 'Запланированная задача',
      plannedTime: plannedTime ?? DateTime.now().add(const Duration(hours: 2)),
    );
  }

  /// Утилита для ожидания анимации
  static Future<void> waitForAnimation(WidgetTester tester, [Duration? duration]) async {
    await tester.pumpAndSettle(duration ?? const Duration(milliseconds: 300));
  }

  /// Утилита для поиска виджета по тексту с учетом регистра
  static Finder findTextIgnoreCase(String text) {
    return find.byWidgetPredicate(
      (Widget widget) => widget is Text && 
        widget.data?.toLowerCase().contains(text.toLowerCase()) == true,
    );
  }

  /// Проверяет наличие ошибки в снэкбаре
  static void expectErrorSnackBar(WidgetTester tester, String errorMessage) {
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(errorMessage), findsOneWidget);
  }

  /// Проверяет наличие успешного сообщения в снэкбаре
  static void expectSuccessSnackBar(WidgetTester tester, String successMessage) {
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(successMessage), findsOneWidget);
  }

  /// Имитирует долгое нажатие на виджет
  static Future<void> longPress(WidgetTester tester, Finder finder) async {
    await tester.longPress(finder);
    await waitForAnimation(tester);
  }

  /// Имитирует свайп по виджету
  static Future<void> swipe(WidgetTester tester, Finder finder, Offset offset) async {
    await tester.drag(finder, offset);
    await waitForAnimation(tester);
  }

  /// Создает моковые данные для тестирования аналитики
  static Map<String, dynamic> createAnalyticsTestData() {
    return {
      'totalTasks': 15,
      'completedTasks': 8,
      'overdueTasks': 2,
      'tasksBySubject': {
        'Математика': 5,
        'Физика': 4,
        'Химия': 3,
        'История': 2,
        'Литература': 1,
      },
      'tasksByPriority': {
        'high': 3,
        'medium': 7,
        'low': 5,
      },
      'completionRate': 0.53,
    };
  }

  /// Проверяет состояние загрузки
  static void expectLoadingState(WidgetTester tester) {
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  }

  /// Проверяет пустое состояние
  static void expectEmptyState(WidgetTester tester, [String? emptyMessage]) {
    if (emptyMessage != null) {
      expect(find.text(emptyMessage), findsOneWidget);
    }
    // Можно добавить проверку на специфичные виджеты пустого состояния
  }

  /// Проверяет состояние ошибки
  static void expectErrorState(WidgetTester tester, String errorMessage) {
    expect(find.text(errorMessage), findsOneWidget);
    // Можно добавить проверку на кнопку повтора
  }
}