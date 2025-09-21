import 'package:equatable/equatable.dart';

enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

enum TaskPriority {
  low,
  medium,
  high,
}

class Task extends Equatable {
  final String id;
  final String userId;
  final String subjectId;
  final String title;
  final String? description;
  final DateTime deadline;
  final int? plannedTime; // в минутах
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  const Task({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.title,
    this.description,
    required this.deadline,
    this.plannedTime,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        subjectId,
        title,
        description,
        deadline,
        plannedTime,
        priority,
        status,
        createdAt,
        updatedAt,
        isDeleted,
        deletedAt,
      ];

  Task copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? title,
    String? description,
    DateTime? deadline,
    int? plannedTime,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      plannedTime: plannedTime ?? this.plannedTime,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'subjectId': subjectId,
      'title': title,
      'description': description,
      'deadline': deadline.millisecondsSinceEpoch,
      'plannedTime': plannedTime,
      'priority': priority.index,
      'status': status.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isDeleted': isDeleted ? 1 : 0,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      userId: json['userId'] as String,
      subjectId: json['subjectId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      deadline: DateTime.fromMillisecondsSinceEpoch(json['deadline'] as int),
      plannedTime: json['plannedTime'] as int?,
      priority: TaskPriority.values[json['priority'] as int],
      status: TaskStatus.values[json['status'] as int],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
      isDeleted: (json['isDeleted'] as int) == 1,
      deletedAt: json['deletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['deletedAt'] as int)
          : null,
    );
  }

  // Для совместимости с Firebase (когда нужно)
  factory Task.fromFirestore(Map<String, dynamic> data) {
    return Task.fromJson(data);
  }

  Map<String, dynamic> toFirestore() {
    return toJson();
  }

  bool get isOverdue {
    return deadline.isBefore(DateTime.now()) && status != TaskStatus.completed;
  }

  String get statusText {
    switch (status) {
      case TaskStatus.pending:
        return 'Ожидает';
      case TaskStatus.inProgress:
        return 'В работе';
      case TaskStatus.completed:
        return 'Выполнена';
      case TaskStatus.cancelled:
        return 'Отменена';
    }
  }

  String get priorityText {
    switch (priority) {
      case TaskPriority.low:
        return 'Низкий';
      case TaskPriority.medium:
        return 'Средний';
      case TaskPriority.high:
        return 'Высокий';
    }
  }
}