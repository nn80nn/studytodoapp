import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { low, medium, high }
enum TaskStatus { pending, completed, overdue }

class Task {
  final String id;
  final String subjectId;
  final String title;
  final String? description;
  final DateTime deadline;
  final DateTime? plannedTime;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSyncAt;

  Task({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    required this.deadline,
    this.plannedTime,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.lastSyncAt,
  });

  Task copyWith({
    String? title,
    String? description,
    DateTime? deadline,
    DateTime? plannedTime,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? updatedAt,
    DateTime? lastSyncAt,
  }) {
    return Task(
      id: id,
      subjectId: subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      plannedTime: plannedTime ?? this.plannedTime,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject_id': subjectId,
    'title': title,
    'description': description,
    'deadline': deadline.millisecondsSinceEpoch,
    'planned_time': plannedTime?.millisecondsSinceEpoch,
    'priority': priority.index,
    'status': status.index,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt?.millisecondsSinceEpoch,
    'last_sync_at': lastSyncAt?.millisecondsSinceEpoch,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    subjectId: json['subjectId'] ?? json['subject_id'],
    title: json['title'],
    description: json['description'],
    deadline: _parseDateTime(json['deadline']),
    plannedTime: (json['plannedTime'] ?? json['planned_time']) != null 
        ? _parseDateTime(json['plannedTime'] ?? json['planned_time'])
        : null,
    priority: TaskPriority.values[json['priority'] ?? 1],
    status: TaskStatus.values[json['status'] ?? 0],
    createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    updatedAt: (json['updatedAt'] ?? json['updated_at']) != null ? _parseDateTime(json['updatedAt'] ?? json['updated_at']) : null,
    lastSyncAt: (json['lastSyncAt'] ?? json['last_sync_at']) != null ? _parseDateTime(json['lastSyncAt'] ?? json['last_sync_at']) : null,
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
}