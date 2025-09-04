import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

// Events
abstract class TasksEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadTasks extends TasksEvent {}
class RefreshTasks extends TasksEvent {}
class AddTask extends TasksEvent {
  final Task task;
  AddTask(this.task);
  @override
  List<Object> get props => [task];
}

class UpdateTask extends TasksEvent {
  final Task task;
  UpdateTask(this.task);
  @override
  List<Object> get props => [task];
}

class DeleteTask extends TasksEvent {
  final String id;
  DeleteTask(this.id);
  @override
  List<Object> get props => [id];
}

class CompleteTask extends TasksEvent {
  final String id;
  CompleteTask(this.id);
  @override
  List<Object> get props => [id];
}

class UnCompleteTask extends TasksEvent {
  final String id;
  UnCompleteTask(this.id);
  @override
  List<Object> get props => [id];
}

class StartTasksStream extends TasksEvent {}
class StopTasksStream extends TasksEvent {}
class TasksUpdated extends TasksEvent {
  final List<Task> tasks;
  TasksUpdated(this.tasks);
  @override
  List<Object> get props => [tasks];
}

// States
abstract class TasksState extends Equatable {
  @override
  List<Object> get props => [];
}

class TasksInitial extends TasksState {}
class TasksLoading extends TasksState {}
class TasksLoaded extends TasksState {
  final List<Task> tasks;
  final bool isRefreshing;
  TasksLoaded(this.tasks, {this.isRefreshing = false});
  @override
  List<Object> get props => [tasks, isRefreshing];
}

class TaskAdding extends TasksState {}
class TaskUpdating extends TasksState {}
class TaskDeleting extends TasksState {}

class TasksError extends TasksState {
  final String message;
  TasksError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class TasksBloc extends Bloc<TasksEvent, TasksState> {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  
  StreamSubscription<List<Task>>? _tasksStreamSubscription;

  TasksBloc() : super(TasksInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<RefreshTasks>(_onRefreshTasks);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
    on<CompleteTask>(_onCompleteTask);
    on<UnCompleteTask>(_onUnCompleteTask);
    on<StartTasksStream>(_onStartTasksStream);
    on<StopTasksStream>(_onStopTasksStream);
    on<TasksUpdated>(_onTasksUpdated);
    
    // Автоматически начинаем стрим при создании BLoC
    add(StartTasksStream());
  }

  @override
  Future<void> close() {
    _tasksStreamSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TasksState> emit) async {
    emit(TasksLoading());
    try {
      final tasks = await _databaseService.getTasks();
      emit(TasksLoaded(tasks));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onRefreshTasks(RefreshTasks event, Emitter<TasksState> emit) async {
    final currentState = state;
    if (currentState is TasksLoaded) {
      emit(TasksLoaded(currentState.tasks, isRefreshing: true));
    }
    try {
      final tasks = await _databaseService.getTasks();
      emit(TasksLoaded(tasks));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TasksState> emit) async {
    // Оптимистичное обновление - сначала обновляем UI
    final currentState = state;
    if (currentState is TasksLoaded) {
      final updatedTasks = List<Task>.from(currentState.tasks)..add(event.task);
      emit(TasksLoaded(updatedTasks));
    }
    
    try {
      await _databaseService.addTask(event.task);
      await _notificationService.scheduleTaskReminder(event.task);
      // Получаем свежие данные из базы
      final tasks = await _databaseService.getTasks();
      emit(TasksLoaded(tasks));
    } catch (e) {
      // При ошибке откатываем к предыдущему состоянию
      if (currentState is TasksLoaded) {
        emit(TasksLoaded(currentState.tasks));
      }
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TasksState> emit) async {
    // Оптимистичное обновление
    final currentState = state;
    if (currentState is TasksLoaded) {
      final updatedTasks = currentState.tasks.map((task) {
        return task.id == event.task.id ? event.task : task;
      }).toList();
      emit(TasksLoaded(updatedTasks));
    }
    
    try {
      await _databaseService.updateTask(event.task);
      final tasks = await _databaseService.getTasks();
      emit(TasksLoaded(tasks));
    } catch (e) {
      if (currentState is TasksLoaded) {
        emit(TasksLoaded(currentState.tasks));
      }
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TasksState> emit) async {
    // Оптимистичное обновление
    final currentState = state;
    Task? deletedTask;
    if (currentState is TasksLoaded) {
      deletedTask = currentState.tasks.firstWhere((task) => task.id == event.id);
      final updatedTasks = currentState.tasks.where((task) => task.id != event.id).toList();
      emit(TasksLoaded(updatedTasks));
    }
    
    try {
      await _databaseService.deleteTask(event.id);
      final tasks = await _databaseService.getTasks();
      emit(TasksLoaded(tasks));
    } catch (e) {
      // При ошибке возвращаем удаленную задачу
      if (currentState is TasksLoaded && deletedTask != null) {
        emit(TasksLoaded(currentState.tasks));
      }
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onCompleteTask(CompleteTask event, Emitter<TasksState> emit) async {
    // Оптимистичное обновление
    final currentState = state;
    Task? originalTask;
    if (currentState is TasksLoaded) {
      originalTask = currentState.tasks.firstWhere((t) => t.id == event.id);
      final updatedTask = originalTask.copyWith(status: TaskStatus.completed);
      final updatedTasks = currentState.tasks.map((task) {
        return task.id == event.id ? updatedTask : task;
      }).toList();
      emit(TasksLoaded(updatedTasks));
    }
    
    try {
      if (originalTask != null) {
        final updatedTask = originalTask.copyWith(status: TaskStatus.completed);
        await _databaseService.updateTask(updatedTask);
        final tasks = await _databaseService.getTasks();
        emit(TasksLoaded(tasks));
      }
    } catch (e) {
      if (currentState is TasksLoaded) {
        emit(TasksLoaded(currentState.tasks));
      }
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onUnCompleteTask(UnCompleteTask event, Emitter<TasksState> emit) async {
    // Оптимистичное обновление
    final currentState = state;
    Task? originalTask;
    if (currentState is TasksLoaded) {
      originalTask = currentState.tasks.firstWhere((t) => t.id == event.id);
      final updatedTask = originalTask.copyWith(status: TaskStatus.pending);
      final updatedTasks = currentState.tasks.map((task) {
        return task.id == event.id ? updatedTask : task;
      }).toList();
      emit(TasksLoaded(updatedTasks));
    }
    
    try {
      if (originalTask != null) {
        final updatedTask = originalTask.copyWith(status: TaskStatus.pending);
        await _databaseService.updateTask(updatedTask);
        final tasks = await _databaseService.getTasks();
        emit(TasksLoaded(tasks));
      }
    } catch (e) {
      if (currentState is TasksLoaded) {
        emit(TasksLoaded(currentState.tasks));
      }
      emit(TasksError(e.toString()));
    }
  }

  void _onStartTasksStream(StartTasksStream event, Emitter<TasksState> emit) {
    emit(TasksLoading());
    
    _tasksStreamSubscription?.cancel();
    _tasksStreamSubscription = _databaseService.getTasksStream().listen(
      (tasks) {
        add(TasksUpdated(tasks));
      },
      onError: (error) {
        emit(TasksError(error.toString()));
      },
    );
  }

  void _onStopTasksStream(StopTasksStream event, Emitter<TasksState> emit) {
    _tasksStreamSubscription?.cancel();
  }

  void _onTasksUpdated(TasksUpdated event, Emitter<TasksState> emit) {
    emit(TasksLoaded(event.tasks));
  }
}