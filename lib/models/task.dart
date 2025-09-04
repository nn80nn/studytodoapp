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
  });

  Task copyWith({
    String? title,
    String? description,
    DateTime? deadline,
    DateTime? plannedTime,
    TaskPriority? priority,
    TaskStatus? status,
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
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'title': title,
    'description': description,
    'deadline': deadline.millisecondsSinceEpoch,
    'plannedTime': plannedTime?.millisecondsSinceEpoch,
    'priority': priority.index,
    'status': status.index,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    subjectId: json['subjectId'],
    title: json['title'],
    description: json['description'],
    deadline: _parseDateTime(json['deadline']),
    plannedTime: json['plannedTime'] != null 
        ? _parseDateTime(json['plannedTime'])
        : null,
    priority: TaskPriority.values[json['priority'] ?? 1],
    status: TaskStatus.values[json['status'] ?? 0],
    createdAt: _parseDateTime(json['createdAt']),
  );

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime is Timestamp) {
      return dateTime.toDate();
    } else if (dateTime is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateTime);
    } else if (dateTime is String) {
      return DateTime.parse(dateTime);
    }
    return DateTime.now();
  }
}