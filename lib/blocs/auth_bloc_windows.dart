import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/user_profile_windows.dart';
import '../services/database_service_windows.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitialize extends AuthEvent {}

class AuthSignInLocal extends AuthEvent {
  final String email;
  final String password;
  AuthSignInLocal(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class AuthCreateLocalAccount extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;
  AuthCreateLocalAccount(this.email, this.password, this.displayName);
  @override
  List<Object?> get props => [email, password, displayName];
}

class AuthSignInAnonymously extends AuthEvent {}

class AuthSignOut extends AuthEvent {}

class AuthUpdateProfile extends AuthEvent {
  final UserProfile profile;
  AuthUpdateProfile(this.profile);
  @override
  List<Object?> get props => [profile];
}

class AuthUserChanged extends AuthEvent {
  final UserProfile? user;
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
  final UserProfile user;
  AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final DatabaseService _databaseService = DatabaseService();
  StreamSubscription<UserProfile?>? _userSubscription;

  AuthBloc() : super(AuthInitial()) {
    on<AuthInitialize>(_onInitialize);
    on<AuthSignInLocal>(_onSignInLocal);
    on<AuthCreateLocalAccount>(_onCreateLocalAccount);
    on<AuthSignInAnonymously>(_onSignInAnonymously);
    on<AuthSignOut>(_onSignOut);
    on<AuthUpdateProfile>(_onUpdateProfile);
    on<AuthUserChanged>(_onUserChanged);

    // Запускаем инициализацию
    add(AuthInitialize());
  }

  Future<void> _onInitialize(AuthInitialize event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      await _databaseService.initialize();

      // Подписываемся на изменения пользователя
      _userSubscription = _databaseService.userStream.listen((user) {
        add(AuthUserChanged(user));
      });

      // Получаем текущего пользователя
      final currentUser = await _databaseService.getCurrentUserProfile();

      if (currentUser != null) {
        emit(AuthAuthenticated(currentUser));
      } else {
        // Создаем анонимного пользователя
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Ошибка инициализации: $e'));
    }
  }

  Future<void> _onSignInLocal(AuthSignInLocal event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final user = await _databaseService.signInLocal(
        email: event.email,
        password: event.password,
      );

      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthError('Неверный email или пароль'));
      }
    } catch (e) {
      emit(AuthError('Ошибка входа: $e'));
    }
  }

  Future<void> _onCreateLocalAccount(AuthCreateLocalAccount event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final user = await _databaseService.createLocalAccount(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError('Ошибка создания аккаунта: $e'));
    }
  }

  Future<void> _onSignInAnonymously(AuthSignInAnonymously event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final currentUser = await _databaseService.getCurrentUserProfile();
      if (currentUser != null) {
        emit(AuthAuthenticated(currentUser));
      } else {
        emit(AuthError('Не удалось создать анонимного пользователя'));
      }
    } catch (e) {
      emit(AuthError('Ошибка анонимного входа: $e'));
    }
  }

  Future<void> _onSignOut(AuthSignOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      await _databaseService.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Ошибка выхода: $e'));
    }
  }

  Future<void> _onUpdateProfile(AuthUpdateProfile event, Emitter<AuthState> emit) async {
    try {
      await _databaseService.updateUserProfile(event.profile);
      emit(AuthAuthenticated(event.profile));
    } catch (e) {
      emit(AuthError('Ошибка обновления профиля: $e'));
    }
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(AuthAuthenticated(event.user!));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    _databaseService.dispose();
    return super.close();
  }
}