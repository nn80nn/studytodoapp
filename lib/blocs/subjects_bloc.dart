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

  SubjectsBloc() : super(SubjectsInitial()) {
    on<LoadSubjects>(_onLoadSubjects);
    on<RefreshSubjects>(_onRefreshSubjects);
    on<AddSubject>(_onAddSubject);
    on<UpdateSubject>(_onUpdateSubject);
    on<DeleteSubject>(_onDeleteSubject);
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
    // Оптимистичное обновление
    final currentState = state;
    if (currentState is SubjectsLoaded) {
      final updatedSubjects = List<Subject>.from(currentState.subjects)..add(event.subject);
      emit(SubjectsLoaded(updatedSubjects));
    }
    
    try {
      await _databaseService.addSubject(event.subject);
      final subjects = await _databaseService.getSubjects();
      emit(SubjectsLoaded(subjects));
    } catch (e) {
      if (currentState is SubjectsLoaded) {
        emit(SubjectsLoaded(currentState.subjects));
      }
      emit(SubjectsError(e.toString()));
    }
  }

  Future<void> _onUpdateSubject(UpdateSubject event, Emitter<SubjectsState> emit) async {
    // Оптимистичное обновление
    final currentState = state;
    if (currentState is SubjectsLoaded) {
      final updatedSubjects = currentState.subjects.map((subject) {
        return subject.id == event.subject.id ? event.subject : subject;
      }).toList();
      emit(SubjectsLoaded(updatedSubjects));
    }
    
    try {
      await _databaseService.updateSubject(event.subject);
      final subjects = await _databaseService.getSubjects();
      emit(SubjectsLoaded(subjects));
    } catch (e) {
      if (currentState is SubjectsLoaded) {
        emit(SubjectsLoaded(currentState.subjects));
      }
      emit(SubjectsError(e.toString()));
    }
  }

  Future<void> _onDeleteSubject(DeleteSubject event, Emitter<SubjectsState> emit) async {
    // Оптимистичное обновление
    final currentState = state;
    Subject? deletedSubject;
    if (currentState is SubjectsLoaded) {
      deletedSubject = currentState.subjects.firstWhere((subject) => subject.id == event.id);
      final updatedSubjects = currentState.subjects.where((subject) => subject.id != event.id).toList();
      emit(SubjectsLoaded(updatedSubjects));
    }
    
    try {
      await _databaseService.deleteSubject(event.id);
      final subjects = await _databaseService.getSubjects();
      emit(SubjectsLoaded(subjects));
    } catch (e) {
      if (currentState is SubjectsLoaded && deletedSubject != null) {
        emit(SubjectsLoaded(currentState.subjects));
      }
      emit(SubjectsError(e.toString()));
    }
  }
}