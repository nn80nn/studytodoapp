import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/subject.dart';
import '../services/database_service.dart';

// Events
abstract class SubjectsEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadSubjects extends SubjectsEvent {}
class RefreshSubjects extends SubjectsEvent {}
class AddSubject extends SubjectsEvent {
  final Subject subject;
  AddSubject(this.subject);
  @override
  List<Object> get props => [subject];
}

class UpdateSubject extends SubjectsEvent {
  final Subject subject;
  UpdateSubject(this.subject);
  @override
  List<Object> get props => [subject];
}

class DeleteSubject extends SubjectsEvent {
  final String id;
  DeleteSubject(this.id);
  @override
  List<Object> get props => [id];
}

class StartSubjectsStream extends SubjectsEvent {}
class StopSubjectsStream extends SubjectsEvent {}
class SubjectsUpdated extends SubjectsEvent {
  final List<Subject> subjects;
  SubjectsUpdated(this.subjects);
  @override
  List<Object> get props => [subjects];
}

// States
abstract class SubjectsState extends Equatable {
  @override
  List<Object> get props => [];
}

class SubjectsInitial extends SubjectsState {}
class SubjectsLoading extends SubjectsState {}
class SubjectsLoaded extends SubjectsState {
  final List<Subject> subjects;
  final bool isRefreshing;
  SubjectsLoaded(this.subjects, {this.isRefreshing = false});
  @override
  List<Object> get props => [subjects, isRefreshing];
}

class SubjectAdding extends SubjectsState {}
class SubjectUpdating extends SubjectsState {}
class SubjectDeleting extends SubjectsState {}

class SubjectsError extends SubjectsState {
  final String message;
  SubjectsError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class SubjectsBloc extends Bloc<SubjectsEvent, SubjectsState> {
  final DatabaseService _databaseService = DatabaseService();
  
  StreamSubscription<List<Subject>>? _subjectsStreamSubscription;

  SubjectsBloc() : super(SubjectsInitial()) {
    on<LoadSubjects>(_onLoadSubjects);
    on<RefreshSubjects>(_onRefreshSubjects);
    on<AddSubject>(_onAddSubject);
    on<UpdateSubject>(_onUpdateSubject);
    on<DeleteSubject>(_onDeleteSubject);
    on<StartSubjectsStream>(_onStartSubjectsStream);
    on<StopSubjectsStream>(_onStopSubjectsStream);
    on<SubjectsUpdated>(_onSubjectsUpdated);
    
    // Автоматически начинаем стрим при создании BLoC
    add(StartSubjectsStream());
  }

  @override
  Future<void> close() {
    _subjectsStreamSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadSubjects(LoadSubjects event, Emitter<SubjectsState> emit) async {
    emit(SubjectsLoading());
    try {
      final subjects = await _databaseService.getSubjects();
      emit(SubjectsLoaded(subjects));
    } catch (e) {
      emit(SubjectsError(e.toString()));
    }
  }

  Future<void> _onRefreshSubjects(RefreshSubjects event, Emitter<SubjectsState> emit) async {
    final currentState = state;
    if (currentState is SubjectsLoaded) {
      emit(SubjectsLoaded(currentState.subjects, isRefreshing: true));
    }
    try {
      final subjects = await _databaseService.getSubjects();
      emit(SubjectsLoaded(subjects));
    } catch (e) {
      emit(SubjectsError(e.toString()));
    }
  }

  Future<void> _onAddSubject(AddSubject event, Emitter<SubjectsState> emit) async {
    try {
      await _databaseService.addSubject(event.subject);
      // Не нужно emit здесь - stream автоматически обновит состояние
    } catch (e) {
      emit(SubjectsError(e.toString()));
    }
  }

  Future<void> _onUpdateSubject(UpdateSubject event, Emitter<SubjectsState> emit) async {
    try {
      await _databaseService.updateSubject(event.subject);
      // Не нужно emit здесь - stream автоматически обновит состояние
    } catch (e) {
      emit(SubjectsError(e.toString()));
    }
  }

  Future<void> _onDeleteSubject(DeleteSubject event, Emitter<SubjectsState> emit) async {
    try {
      await _databaseService.deleteSubject(event.id);
      // Не нужно emit здесь - stream автоматически обновит состояние
    } catch (e) {
      emit(SubjectsError(e.toString()));
    }
  }

  void _onStartSubjectsStream(StartSubjectsStream event, Emitter<SubjectsState> emit) {
    emit(SubjectsLoading());
    
    _subjectsStreamSubscription?.cancel();
    _subjectsStreamSubscription = _databaseService.getSubjectsStream().listen(
      (subjects) {
        if (!isClosed) {
          add(SubjectsUpdated(subjects));
        }
      },
      onError: (error) {
        if (!isClosed && !emit.isDone) {
          emit(SubjectsError(error.toString()));
        }
      },
    );
  }

  void _onStopSubjectsStream(StopSubjectsStream event, Emitter<SubjectsState> emit) {
    _subjectsStreamSubscription?.cancel();
  }

  void _onSubjectsUpdated(SubjectsUpdated event, Emitter<SubjectsState> emit) {
    emit(SubjectsLoaded(event.subjects));
  }
}