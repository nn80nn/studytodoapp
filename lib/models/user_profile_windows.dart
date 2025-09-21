import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final int totalTasks;
  final int completedTasks;
  final int totalSubjects;
  final int totalCompletedAllTime; // All-time completed tasks counter
  final String? geminiApiKey;

  const UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    required this.isAnonymous,
    required this.createdAt,
    required this.lastLoginAt,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.totalSubjects = 0,
    this.totalCompletedAllTime = 0,
    this.geminiApiKey,
  });

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        photoURL,
        isAnonymous,
        createdAt,
        lastLoginAt,
        totalTasks,
        completedTasks,
        totalSubjects,
        totalCompletedAllTime,
        geminiApiKey,
      ];

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    int? totalTasks,
    int? completedTasks,
    int? totalSubjects,
    int? totalCompletedAllTime,
    String? geminiApiKey,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      totalSubjects: totalSubjects ?? this.totalSubjects,
      totalCompletedAllTime: totalCompletedAllTime ?? this.totalCompletedAllTime,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      lastLoginAt: DateTime.fromMillisecondsSinceEpoch(json['lastLoginAt'] as int),
      totalTasks: json['totalTasks'] as int? ?? 0,
      completedTasks: json['completedTasks'] as int? ?? 0,
      totalSubjects: json['totalSubjects'] as int? ?? 0,
      totalCompletedAllTime: json['totalCompletedAllTime'] as int? ?? 0,
      geminiApiKey: json['geminiApiKey'] as String?,
    );
  }

  // Для совместимости с Firebase (когда нужно)
  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile.fromJson(data);
  }

  Map<String, dynamic> toFirestore() {
    return toJson();
  }

  double get completionRate {
    if (totalTasks == 0) return 0.0;
    return completedTasks / totalTasks;
  }

  String get completionPercentage {
    return '${(completionRate * 100).round()}%';
  }

  bool get hasGeminiApiKey => geminiApiKey != null && geminiApiKey!.isNotEmpty;

  String get displayText {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (email != null && email!.isNotEmpty) {
      return email!;
    }
    return isAnonymous ? 'Анонимный пользователь' : 'Пользователь';
  }

  // Создание анонимного пользователя для Windows
  factory UserProfile.createAnonymous(String uid) {
    final now = DateTime.now();
    return UserProfile(
      uid: uid,
      isAnonymous: true,
      createdAt: now,
      lastLoginAt: now,
      displayName: 'Windows User',
    );
  }

  // Создание пользователя с email для Windows (SQLite only)
  factory UserProfile.createLocal({
    required String uid,
    required String email,
    String? displayName,
  }) {
    final now = DateTime.now();
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? email.split('@')[0],
      isAnonymous: false,
      createdAt: now,
      lastLoginAt: now,
    );
  }
}