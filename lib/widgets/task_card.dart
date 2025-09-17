import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/task.dart';
import '../models/subject.dart';
import '../blocs/tasks_bloc.dart';
import 'edit_task_dialog.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final Subject subject;
  final VoidCallback? onCompleted;
  final VoidCallback? onDeleted;

  const TaskCard({
    Key? key,
    required this.task,
    required this.subject,
    this.onCompleted,
    this.onDeleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = task.status == TaskStatus.completed;
    final isOverdue = task.status == TaskStatus.overdue || 
        (task.status == TaskStatus.pending && task.deadline.isBefore(DateTime.now()));
    
    // Определяем цвет карточки в зависимости от статуса
    Color cardColor = subject.color.withOpacity(0.05);
    Color borderColor = subject.color.withOpacity(0.2);
    
    if (isCompleted) {
      cardColor = Colors.green.withOpacity(0.1);
      borderColor = Colors.green.withOpacity(0.3);
    } else if (isOverdue) {
      cardColor = Colors.red.withOpacity(0.1);
      borderColor = Colors.red.withOpacity(0.3);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        
        // Левая полоска цвета предмета
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: subject.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        title: Text(
          task.title,
          style: theme.textTheme.titleSmall?.copyWith(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted 
                ? theme.colorScheme.onSurfaceVariant 
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                // Дедлайн
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: isOverdue ? Colors.red : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _formatDate(task.deadline),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isOverdue ? Colors.red : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isOverdue ? FontWeight.w500 : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                
                // Приоритет
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task.priority).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getPriorityColor(task.priority).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _formatPriority(task.priority),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _getPriorityColor(task.priority),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Кнопка завершения (остается видимой)
            if (!isCompleted)
              IconButton(
                icon: Icon(
                  Icons.check_circle_outline,
                  color: subject.color,
                  size: 28,
                ),
                onPressed: () {
                  context.read<TasksBloc>().add(CompleteTask(task.id));
                  onCompleted?.call();
                },
                tooltip: 'Отметить как выполненное',
              ),
            
            // Меню с тремя точками
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String value) {
                switch (value) {
                  case 'edit':
                    _showEditTaskDialog(context);
                    break;
                  case 'complete':
                    if (!isCompleted) {
                      context.read<TasksBloc>().add(CompleteTask(task.id));
                      onCompleted?.call();
                    }
                    break;
                  case 'uncomplete':
                    if (isCompleted) {
                      context.read<TasksBloc>().add(UnCompleteTask(task.id));
                      onCompleted?.call();
                    }
                    break;
                  case 'delete':
                    _showDeleteDialog(context);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      const Text('Редактировать'),
                    ],
                  ),
                ),
                if (!isCompleted)
                  PopupMenuItem<String>(
                    value: 'complete',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        const Text('Выполнить'),
                      ],
                    ),
                  ),
                if (isCompleted)
                  PopupMenuItem<String>(
                    value: 'uncomplete',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.orange, size: 20),
                        const SizedBox(width: 12),
                        const Text('Сделать незавершенной'),
                      ],
                    ),
                  ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      const Text('Удалить'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditTaskDialog(task: task, subject: subject),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: Text('Вы уверены, что хотите удалить задачу "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              context.read<TasksBloc>().add(DeleteTask(task.id));
              Navigator.of(context).pop();
              onDeleted?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Сегодня';
    } else if (taskDate == tomorrow) {
      return 'Завтра';
    } else if (taskDate.isBefore(today)) {
      final daysDiff = today.difference(taskDate).inDays;
      if (daysDiff > 365) {
        final yearsDiff = (daysDiff / 365).floor();
        return yearsDiff == 1 ? '1 год назад' : '$yearsDiff лет назад';
      }
      return '$daysDiff дн. назад';
    } else {
      final daysDiff = taskDate.difference(today).inDays;
      if (daysDiff > 365) {
        final yearsDiff = (daysDiff / 365).floor();
        return yearsDiff == 1 ? 'Через 1 год' : 'Через $yearsDiff лет';
      }
      return 'Через $daysDiff дн.';
    }
  }

  String _formatPriority(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Низкий';
      case TaskPriority.medium:
        return 'Средний';
      case TaskPriority.high:
        return 'Высокий';
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }
}