import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../models/task_windows.dart';
import '../services/database_service_windows.dart';

// Events
abstract class TasksEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTasks extends TasksEvent {}

class AddTask extends TasksEvent {
  final Task task;
  AddTask(this.task);
  @override
  List<Object?> get props => [task];
}

class UpdateTask extends TasksEvent {
  final Task task;
  UpdateTask(this.task);
  @override
  List<Object?> get props => [task];
}

class DeleteTask extends TasksEvent {
  final String taskId;
  DeleteTask(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class ToggleTaskStatus extends TasksEvent {
  final String taskId;
  ToggleTaskStatus(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class FilterTasks extends TasksEvent {
  final TaskStatus? statusFilter;
  final String? subjectFilter;
  final String? searchQuery;
  FilterTasks({this.statusFilter, this.subjectFilter, this.searchQuery});
  @override
  List<Object?> get props => [statusFilter, subjectFilter, searchQuery];
}

class SortTasks extends TasksEvent {
  final TaskSortBy sortBy;
  final bool ascending;
  SortTasks(this.sortBy, this.ascending);
  @override
  List<Object?> get props => [sortBy, ascending];
}

enum TaskSortBy {
  deadline,
  priority,
  title,
  createdAt,
  status,
}

// States
abstract class TasksState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TasksInitial extends TasksState {}

class TasksLoading extends TasksState {}

class TasksLoaded extends TasksState {
  final List<Task> tasks;
  final List<Task> filteredTasks;
  final TaskStatus? statusFilter;
  final String? subjectFilter;
  final String? searchQuery;
  final TaskSortBy sortBy;
  final bool ascending;

  TasksLoaded({
    required this.tasks,
    required this.filteredTasks,
    this.statusFilter,
    this.subjectFilter,
    this.searchQuery,
    this.sortBy = TaskSortBy.deadline,
    this.ascending = true,
  });

  @override
  List<Object?> get props => [
        tasks,
        filteredTasks,
        statusFilter,
        subjectFilter,
        searchQuery,
        sortBy,
        ascending,
      ];

  TasksLoaded copyWith({
    List<Task>? tasks,
    List<Task>? filteredTasks,
    TaskStatus? statusFilter,
    String? subjectFilter,
    String? searchQuery,
    TaskSortBy? sortBy,
    bool? ascending,
  }) {
    return TasksLoaded(
      tasks: tasks ?? this.tasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
      statusFilter: statusFilter ?? this.statusFilter,
      subjectFilter: subjectFilter ?? this.subjectFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }
}

class TasksError extends TasksState {
  final String message;
  TasksError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class TasksBloc extends Bloc<TasksEvent, TasksState> {
  final DatabaseService _databaseService = DatabaseService();
  final Uuid _uuid = const Uuid();
  StreamSubscription<List<Task>>? _tasksSubscription;

  TasksBloc() : super(TasksInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
    on<ToggleTaskStatus>(_onToggleTaskStatus);
    on<FilterTasks>(_onFilterTasks);
    on<SortTasks>(_onSortTasks);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TasksState> emit) async {
    emit(TasksLoading());

    try {
      // Подписываемся на изменения задач
      _tasksSubscription = _databaseService.tasksStream.listen((tasks) {
        if (state is TasksLoaded) {
          final currentState = state as TasksLoaded;
          final filteredTasks = _applyFiltersAndSort(
            tasks,
            statusFilter: currentState.statusFilter,
            subjectFilter: currentState.subjectFilter,
            searchQuery: currentState.searchQuery,
            sortBy: currentState.sortBy,
            ascending: currentState.ascending,
          );

          add(FilterTasks(
            statusFilter: currentState.statusFilter,
            subjectFilter: currentState.subjectFilter,
            searchQuery: currentState.searchQuery,
          ));
        }
      });

      // Получаем задачи
      final tasks = await _databaseService.getTasks();
      final filteredTasks = _applyFiltersAndSort(tasks);

      emit(TasksLoaded(
        tasks: tasks,
        filteredTasks: filteredTasks,
      ));
    } catch (e) {
      emit(TasksError('Ошибка загрузки задач: $e'));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TasksState> emit) async {
    try {
      final taskWithId = event.task.copyWith(
        id: event.task.id.isEmpty ? _uuid.v4() : event.task.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.saveTask(taskWithId);

      // Состояние обновится через stream
    } catch (e) {
      emit(TasksError('Ошибка добавления задачи: $e'));
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TasksState> emit) async {
    try {
      final updatedTask = event.task.copyWith(
        updatedAt: DateTime.now(),
      );

      await _databaseService.saveTask(updatedTask);

      // Состояние обновится через stream
    } catch (e) {
      emit(TasksError('Ошибка обновления задачи: $e'));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TasksState> emit) async {
    try {
      await _databaseService.deleteTask(event.taskId);

      // Состояние обновится через stream
    } catch (e) {
      emit(TasksError('Ошибка удаления задачи: $e'));
    }
  }

  Future<void> _onToggleTaskStatus(ToggleTaskStatus event, Emitter<TasksState> emit) async {
    try {
      if (state is TasksLoaded) {
        final currentState = state as TasksLoaded;
        final task = currentState.tasks.firstWhere((t) => t.id == event.taskId);

        TaskStatus newStatus;
        if (task.status == TaskStatus.completed) {
          newStatus = TaskStatus.pending;
        } else {
          newStatus = TaskStatus.completed;
        }

        final updatedTask = task.copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );

        if (newStatus == TaskStatus.completed) {
          await _databaseService.markTaskCompleted(event.taskId);
        } else {
          await _databaseService.saveTask(updatedTask);
        }

        // Состояние обновится через stream
      }
    } catch (e) {
      emit(TasksError('Ошибка изменения статуса задачи: $e'));
    }
  }

  void _onFilterTasks(FilterTasks event, Emitter<TasksState> emit) {
    if (state is TasksLoaded) {
      final currentState = state as TasksLoaded;
      final filteredTasks = _applyFiltersAndSort(
        currentState.tasks,
        statusFilter: event.statusFilter,
        subjectFilter: event.subjectFilter,
        searchQuery: event.searchQuery,
        sortBy: currentState.sortBy,
        ascending: currentState.ascending,
      );

      emit(currentState.copyWith(
        filteredTasks: filteredTasks,
        statusFilter: event.statusFilter,
        subjectFilter: event.subjectFilter,
        searchQuery: event.searchQuery,
      ));
    }
  }

  void _onSortTasks(SortTasks event, Emitter<TasksState> emit) {
    if (state is TasksLoaded) {
      final currentState = state as TasksLoaded;
      final filteredTasks = _applyFiltersAndSort(
        currentState.tasks,
        statusFilter: currentState.statusFilter,
        subjectFilter: currentState.subjectFilter,
        searchQuery: currentState.searchQuery,
        sortBy: event.sortBy,
        ascending: event.ascending,
      );

      emit(currentState.copyWith(
        filteredTasks: filteredTasks,
        sortBy: event.sortBy,
        ascending: event.ascending,
      ));
    }
  }

  List<Task> _applyFiltersAndSort(
    List<Task> tasks, {
    TaskStatus? statusFilter,
    String? subjectFilter,
    String? searchQuery,
    TaskSortBy sortBy = TaskSortBy.deadline,
    bool ascending = true,
  }) {
    var filtered = tasks.where((task) => !task.isDeleted).toList();

    // Фильтр по статусу
    if (statusFilter != null) {
      filtered = filtered.where((task) => task.status == statusFilter).toList();
    }

    // Фильтр по предмету
    if (subjectFilter != null && subjectFilter.isNotEmpty) {
      filtered = filtered.where((task) => task.subjectId == subjectFilter).toList();
    }

    // Поиск
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((task) {
        return task.title.toLowerCase().contains(query) ||
            (task.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Сортировка
    filtered.sort((a, b) {
      int comparison = 0;

      switch (sortBy) {
        case TaskSortBy.deadline:
          comparison = a.deadline.compareTo(b.deadline);
          break;
        case TaskSortBy.priority:
          comparison = b.priority.index.compareTo(a.priority.index); // Высокий приоритет первым
          break;
        case TaskSortBy.title:
          comparison = a.title.compareTo(b.title);
          break;
        case TaskSortBy.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case TaskSortBy.status:
          comparison = a.status.index.compareTo(b.status.index);
          break;
      }

      return ascending ? comparison : -comparison;
    });

    return filtered;
  }

  // Вспомогательные методы
  List<Task> getTasksBySubject(String subjectId) {
    if (state is TasksLoaded) {
      final currentState = state as TasksLoaded;
      return currentState.tasks
          .where((task) => task.subjectId == subjectId && !task.isDeleted)
          .toList();
    }
    return [];
  }

  List<Task> getOverdueTasks() {
    if (state is TasksLoaded) {
      final currentState = state as TasksLoaded;
      return currentState.tasks
          .where((task) => task.isOverdue && !task.isDeleted)
          .toList();
    }
    return [];
  }

  List<Task> getTodayTasks() {
    if (state is TasksLoaded) {
      final currentState = state as TasksLoaded;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      return currentState.tasks
          .where((task) =>
              task.deadline.isAfter(startOfDay) &&
              task.deadline.isBefore(endOfDay) &&
              !task.isDeleted)
          .toList();
    }
    return [];
  }

  @override
  Future<void> close() {
    _tasksSubscription?.cancel();
    return super.close();
  }
}