import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../models/subject_windows.dart';
import '../services/database_service_windows.dart';

// Events
abstract class SubjectsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSubjects extends SubjectsEvent {}

class AddSubject extends SubjectsEvent {
  final Subject subject;
  AddSubject(this.subject);
  @override
  List<Object?> get props => [subject];
}

class UpdateSubject extends SubjectsEvent {
  final Subject subject;
  UpdateSubject(this.subject);
  @override
  List<Object?> get props => [subject];
}

class DeleteSubject extends SubjectsEvent {
  final String subjectId;
  DeleteSubject(this.subjectId);
  @override
  List<Object?> get props => [subjectId];
}

// States
abstract class SubjectsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubjectsInitial extends SubjectsState {}

class SubjectsLoading extends SubjectsState {}

class SubjectsLoaded extends SubjectsState {
  final List<Subject> subjects;

  SubjectsLoaded(this.subjects);

  @override
  List<Object?> get props => [subjects];
}

class SubjectsError extends SubjectsState {
  final String message;
  SubjectsError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class SubjectsBloc extends Bloc<SubjectsEvent, SubjectsState> {
  final DatabaseService _databaseService = DatabaseService();
  final Uuid _uuid = const Uuid();
  StreamSubscription<List<Subject>>? _subjectsSubscription;

  SubjectsBloc() : super(SubjectsInitial()) {
    on<LoadSubjects>(_onLoadSubjects);
    on<AddSubject>(_onAddSubject);
    on<UpdateSubject>(_onUpdateSubject);
    on<DeleteSubject>(_onDeleteSubject);
  }

  Future<void> _onLoadSubjects(LoadSubjects event, Emitter<SubjectsState> emit) async {
    emit(SubjectsLoading());

    try {
      // Подписываемся на изменения предметов
      _subjectsSubscription = _databaseService.subjectsStream.listen((subjects) {
        emit(SubjectsLoaded(subjects));
      });

      // Получаем предметы
      final subjects = await _databaseService.getSubjects();
      emit(SubjectsLoaded(subjects));
    } catch (e) {
      emit(SubjectsError('Ошибка загрузки предметов: $e'));
    }
  }

  Future<void> _onAddSubject(AddSubject event, Emitter<SubjectsState> emit) async {
    try {
      final subjectWithId = event.subject.copyWith(
        id: event.subject.id.isEmpty ? _uuid.v4() : event.subject.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.saveSubject(subjectWithId);

      // Состояние обновится через stream
    } catch (e) {
      emit(SubjectsError('Ошибка добавления предмета: $e'));
    }
  }

  Future<void> _onUpdateSubject(UpdateSubject event, Emitter<SubjectsState> emit) async {
    try {
      final updatedSubject = event.subject.copyWith(
        updatedAt: DateTime.now(),
      );

      await _databaseService.saveSubject(updatedSubject);

      // Состояние обновится через stream
    } catch (e) {
      emit(SubjectsError('Ошибка обновления предмета: $e'));
    }
  }

  Future<void> _onDeleteSubject(DeleteSubject event, Emitter<SubjectsState> emit) async {
    try {
      await _databaseService.deleteSubject(event.subjectId);

      // Состояние обновится через stream
    } catch (e) {
      emit(SubjectsError('Ошибка удаления предмета: $e'));
    }
  }

  // Вспомогательные методы
  Subject? getSubjectById(String subjectId) {
    if (state is SubjectsLoaded) {
      final subjects = (state as SubjectsLoaded).subjects;
      try {
        return subjects.firstWhere((subject) => subject.id == subjectId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  List<Subject> getAvailableSubjects() {
    if (state is SubjectsLoaded) {
      return (state as SubjectsLoaded).subjects
          .where((subject) => !subject.isDeleted)
          .toList();
    }
    return [];
  }

  bool canDeleteSubject(String subjectId) {
    // В реальном приложении здесь была бы проверка на наличие задач
    // Для упрощения пока возвращаем true
    return true;
  }

  @override
  Future<void> close() {
    _subjectsSubscription?.cancel();
    return super.close();
  }
}