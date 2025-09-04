import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitialize extends AuthEvent {}

class AuthSignInWithGoogle extends AuthEvent {}

class AuthSignInAnonymously extends AuthEvent {}

class AuthSignOut extends AuthEvent {}

class AuthDeleteAccount extends AuthEvent {}

class AuthUserChanged extends AuthEvent {
  final User? user;
  AuthUserChanged(this.user);
  @override
  List<Object?> get props => [user];
}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserProfile userProfile;
  AuthAuthenticated(this.userProfile);
  @override
  List<Object> get props => [userProfile];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  
  StreamSubscription<User?>? _authStateSubscription;

  AuthBloc() : super(AuthInitial()) {
    on<AuthInitialize>(_onInitialize);
    on<AuthSignInWithGoogle>(_onSignInWithGoogle);
    on<AuthSignInAnonymously>(_onSignInAnonymously);
    on<AuthSignOut>(_onSignOut);
    on<AuthDeleteAccount>(_onDeleteAccount);
    on<AuthUserChanged>(_onUserChanged);
    
    // Автоматическая инициализация
    add(AuthInitialize());
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }

  void _onInitialize(AuthInitialize event, Emitter<AuthState> emit) {
    emit(AuthLoading());
    
    // Подписка на изменения аутентификации
    _authStateSubscription?.cancel();
    _authStateSubscription = _authService.authStateChanges.listen(
      (user) => add(AuthUserChanged(user)),
    );
  }

  Future<void> _onSignInWithGoogle(AuthSignInWithGoogle event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential == null) {
        emit(AuthUnauthenticated());
      }
      // AuthUserChanged будет вызван автоматически через stream
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignInAnonymously(AuthSignInAnonymously event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.signInAnonymously();
      // AuthUserChanged будет вызван автоматически через stream
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignOut(AuthSignOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.signOut();
      // AuthUserChanged будет вызван автоматически через stream
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onDeleteAccount(AuthDeleteAccount event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final currentState = state;
      if (currentState is AuthAuthenticated) {
        // Удаляем данные пользователя из Firestore
        await _databaseService.deleteUserData(currentState.userProfile.uid);
        
        // Удаляем аккаунт
        await _authService.deleteAccount();
      }
      // AuthUserChanged будет вызван автоматически через stream
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) async {
    final user = event.user;
    
    if (user == null) {
      _databaseService.setCurrentUser(null);
      emit(AuthUnauthenticated());
    } else {
      try {
        // Устанавливаем текущего пользователя в DatabaseService
        _databaseService.setCurrentUser(user.uid);
        
        // Создаем или обновляем профиль пользователя
        UserProfile userProfile = await _createOrUpdateUserProfile(user);
        emit(AuthAuthenticated(userProfile));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    }
  }

  Future<UserProfile> _createOrUpdateUserProfile(User user) async {
    // Получаем статистику пользователя
    final stats = await _databaseService.getUserStats(user.uid);
    
    final userProfile = UserProfile(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      isAnonymous: user.isAnonymous,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: DateTime.now(),
      totalTasks: stats['totalTasks'] ?? 0,
      completedTasks: stats['completedTasks'] ?? 0,
      totalSubjects: stats['totalSubjects'] ?? 0,
    );

    // Сохраняем/обновляем профиль в Firestore
    await _databaseService.saveUserProfile(userProfile);
    
    return userProfile;
  }
}