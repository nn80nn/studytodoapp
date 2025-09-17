import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Текущий пользователь
  User? get currentUser => _auth.currentUser;
  
  // Stream изменений аутентификации
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Проверка аутентификации
  bool get isAuthenticated => currentUser != null;

  // Данные пользователя
  String? get userId => currentUser?.uid;
  String? get userEmail => currentUser?.email;
  String? get userName => currentUser?.displayName;
  String? get userPhotoUrl => currentUser?.photoURL;

  // Вход через Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Запрос аутентификации через Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // Пользователь отменил вход
      }

      // Получение деталей аутентификации
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Создание credential для Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Вход в Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      print('Пользователь вошел: ${userCredential.user?.displayName}');
      return userCredential;
      
    } catch (e) {
      print('Ошибка входа через Google: $e');
      return null;
    }
  }

  // Вход через email и пароль
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Пользователь вошел через email: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Ошибка Firebase Auth: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Общая ошибка входа через email: $e');
      rethrow;
    }
  }

  // Регистрация через email и пароль
  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Пользователь зарегистрирован: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Ошибка Firebase Auth: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Общая ошибка регистрации: $e');
      rethrow;
    }
  }

  // Сброс пароля
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Email для сброса пароля отправлен');
    } on FirebaseAuthException catch (e) {
      print('Ошибка Firebase Auth: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Общая ошибка сброса пароля: $e');
      rethrow;
    }
  }

  // Анонимный вход
  Future<UserCredential?> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      print('Анонимный вход выполнен');
      return userCredential;
    } catch (e) {
      print('Ошибка анонимного входа: $e');
      return null;
    }
  }

  // Выход из системы
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      print('Пользователь вышел из системы');
    } catch (e) {
      print('Ошибка выхода: $e');
    }
  }

  // Удаление аккаунта
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.delete();
        print('Аккаунт удален');
      }
    } catch (e) {
      print('Ошибка удаления аккаунта: $e');
      throw e;
    }
  }

  // Получение информации о пользователе
  Map<String, dynamic> getUserInfo() {
    final user = currentUser;
    if (user != null) {
      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'isAnonymous': user.isAnonymous,
        'emailVerified': user.emailVerified,
        'creationTime': user.metadata.creationTime?.toIso8601String(),
        'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
      };
    }
    return {};
  }
}