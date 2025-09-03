import 'package:flutter/material.dart';
import 'task.dart';
import 'subject.dart';

class TaskGroup {
  final Subject subject;
  final List<Task> tasks;
  
  TaskGroup({
    required this.subject,
    required this.tasks,
  });
  
  // Геттеры для статистики группы
  int get totalTasks => tasks.length;
  int get completedTasks => tasks.where((task) => task.status == TaskStatus.completed).length;
  int get pendingTasks => tasks.where((task) => task.status == TaskStatus.pending).length;
  int get overdueTasks => tasks.where((task) => 
      task.status == TaskStatus.overdue || 
      (task.status == TaskStatus.pending && task.deadline.isBefore(DateTime.now()))
  ).length;
  
  // Процент выполнения
  double get completionPercentage => totalTasks > 0 ? completedTasks / totalTasks : 0.0;
  
  // Сортировка задач по дедлайну (ближайшие сначала)
  List<Task> get sortedTasks {
    final sortedList = List<Task>.from(tasks);
    sortedList.sort((a, b) {
      // Сначала незавершенные, потом завершенные
      if (a.status == TaskStatus.completed && b.status != TaskStatus.completed) {
        return 1;
      }
      if (b.status == TaskStatus.completed && a.status != TaskStatus.completed) {
        return -1;
      }
      
      // Затем по дедлайну
      final deadlineComparison = a.deadline.compareTo(b.deadline);
      if (deadlineComparison != 0) {
        return deadlineComparison;
      }
      
      // Если дедлайн одинаковый, то по приоритету (высокий - первый)
      return b.priority.index.compareTo(a.priority.index);
    });
    return sortedList;
  }
  
  // Ближайший дедлайн среди незавершенных задач
  DateTime? get nearestDeadline {
    final pendingTasks = tasks.where((task) => task.status != TaskStatus.completed);
    if (pendingTasks.isEmpty) return null;
    
    return pendingTasks.reduce((a, b) => 
        a.deadline.isBefore(b.deadline) ? a : b).deadline;
  }
  
  // Есть ли просроченные задачи
  bool get hasOverdueTasks => overdueTasks > 0;
  
  // Цвет предмета
  Color get color => subject.color;
}