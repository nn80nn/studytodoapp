import '../models/task.dart';
import '../models/subject.dart';
import '../models/task_group.dart';

class TaskGrouper {
  /// Группирует задачи по предметам и сортирует по дедлайну
  static List<TaskGroup> groupTasksBySubject(
    List<Task> tasks, 
    List<Subject> subjects,
  ) {
    // Создаем Map для группировки
    final Map<String, List<Task>> taskGroups = {};
    
    // Группируем задачи по subjectId
    for (final task in tasks) {
      if (!taskGroups.containsKey(task.subjectId)) {
        taskGroups[task.subjectId] = [];
      }
      taskGroups[task.subjectId]!.add(task);
    }
    
    // Создаем список TaskGroup
    final List<TaskGroup> groups = [];
    
    for (final subject in subjects) {
      final subjectTasks = taskGroups[subject.id] ?? [];
      if (subjectTasks.isNotEmpty) {
        groups.add(TaskGroup(
          subject: subject,
          tasks: subjectTasks,
        ));
      }
    }
    
    // Сортируем группы по приоритету:
    // 1. Группы с просроченными задачами
    // 2. Группы с ближайшими дедлайнами
    // 3. Группы с наибольшим количеством незавершенных задач
    groups.sort((a, b) {
      // Сначала группы с просроченными задачами
      if (a.hasOverdueTasks && !b.hasOverdueTasks) return -1;
      if (!a.hasOverdueTasks && b.hasOverdueTasks) return 1;
      
      // Затем по ближайшему дедлайну
      final aNearestDeadline = a.nearestDeadline;
      final bNearestDeadline = b.nearestDeadline;
      
      if (aNearestDeadline != null && bNearestDeadline != null) {
        final deadlineComparison = aNearestDeadline.compareTo(bNearestDeadline);
        if (deadlineComparison != 0) return deadlineComparison;
      } else if (aNearestDeadline != null) {
        return -1;
      } else if (bNearestDeadline != null) {
        return 1;
      }
      
      // Затем по количеству незавершенных задач
      return b.pendingTasks.compareTo(a.pendingTasks);
    });
    
    return groups;
  }
  
  /// Получает все задачи из групп, отсортированные по дедлайну
  static List<Task> getAllTasksSorted(List<TaskGroup> groups) {
    final List<Task> allTasks = [];
    
    for (final group in groups) {
      allTasks.addAll(group.sortedTasks);
    }
    
    return allTasks;
  }
  
  /// Фильтрует задачи по статусу
  static List<TaskGroup> filterTaskGroupsByStatus(
    List<TaskGroup> groups, 
    TaskStatus status,
  ) {
    return groups.map((group) {
      final filteredTasks = group.tasks.where((task) => task.status == status).toList();
      return TaskGroup(
        subject: group.subject,
        tasks: filteredTasks,
      );
    }).where((group) => group.tasks.isNotEmpty).toList();
  }
  
  /// Получает статистику по всем группам
  static Map<String, int> getOverallStats(List<TaskGroup> groups) {
    int totalTasks = 0;
    int completedTasks = 0;
    int pendingTasks = 0;
    int overdueTasks = 0;
    
    for (final group in groups) {
      totalTasks += group.totalTasks;
      completedTasks += group.completedTasks;
      pendingTasks += group.pendingTasks;
      overdueTasks += group.overdueTasks;
    }
    
    return {
      'total': totalTasks,
      'completed': completedTasks,
      'pending': pendingTasks,
      'overdue': overdueTasks,
    };
  }
}