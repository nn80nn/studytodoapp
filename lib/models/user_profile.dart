import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  
  // Статистика пользователя
  final int totalTasks;
  final int completedTasks;
  final int totalSubjects;

  // Счетчик всех выполненных задач за всё время (включая удалённые)
  final int totalCompletedAllTime;
  
  // Настройки AI
  final String? geminiApiKey;

  UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.isAnonymous = false,
    required this.createdAt,
    required this.lastLoginAt,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.totalSubjects = 0,
    this.totalCompletedAllTime = 0,
    this.geminiApiKey,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoURL': photoURL,
    'isAnonymous': isAnonymous,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'lastLoginAt': lastLoginAt.millisecondsSinceEpoch,
    'totalTasks': totalTasks,
    'completedTasks': completedTasks,
    'totalSubjects': totalSubjects,
    'totalCompletedAllTime': totalCompletedAllTime,
    'geminiApiKey': geminiApiKey,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    uid: json['uid'],
    email: json['email'],
    displayName: json['displayName'],
    photoURL: json['photoURL'],
    isAnonymous: json['isAnonymous'] ?? false,
    createdAt: _parseDateTime(json['createdAt']),
    lastLoginAt: _parseDateTime(json['lastLoginAt']),
    totalTasks: json['totalTasks'] ?? 0,
    completedTasks: json['completedTasks'] ?? 0,
    totalSubjects: json['totalSubjects'] ?? 0,
    totalCompletedAllTime: json['totalCompletedAllTime'] ?? 0,
    geminiApiKey: json['geminiApiKey'],
  );

  static DateTime _parseDateTime(dynamic dateTime) {
    try {
      if (dateTime is Timestamp) {
        return dateTime.toDate();
      } else if (dateTime is int) {
        // Проверка на разумные границы для предотвращения переполнения
        if (dateTime < 0 || dateTime > 4102444800000) { // 1 января 2100
          return DateTime.now();
        }
        return DateTime.fromMillisecondsSinceEpoch(dateTime);
      } else if (dateTime is String) {
        return DateTime.parse(dateTime);
      }
    } catch (e) {
      // В случае ошибки парсинга возвращаем текущее время
      return DateTime.now();
    }
    return DateTime.now();
  }

  UserProfile copyWith({
    String? email,
    String? displayName,
    String? photoURL,
    bool? isAnonymous,
    DateTime? lastLoginAt,
    int? totalTasks,
    int? completedTasks,
    int? totalSubjects,
    int? totalCompletedAllTime,
    String? geminiApiKey,
  }) {
    return UserProfile(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      totalSubjects: totalSubjects ?? this.totalSubjects,
      totalCompletedAllTime: totalCompletedAllTime ?? this.totalCompletedAllTime,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
    );
  }

  // Вычисляемые поля
  double get completionRate => totalTasks > 0 ? completedTasks / totalTasks : 0.0;
  int get pendingTasks => totalTasks - completedTasks;
  
  String get displayNameOrEmail => displayName ?? email ?? 'Пользователь';
  
  bool get hasProfileImage => photoURL != null && photoURL!.isNotEmpty;
  bool get hasGeminiApiKey => geminiApiKey != null && geminiApiKey!.isNotEmpty;
}