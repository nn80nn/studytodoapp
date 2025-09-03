import 'package:flutter/material.dart';
import '../models/task_group.dart';
import 'task_card.dart';

class TaskGroupCard extends StatefulWidget {
  final TaskGroup group;
  final VoidCallback? onTaskCompleted;
  final VoidCallback? onTaskDeleted;

  const TaskGroupCard({
    Key? key,
    required this.group,
    this.onTaskCompleted,
    this.onTaskDeleted,
  }) : super(key: key);

  @override
  State<TaskGroupCard> createState() => _TaskGroupCardState();
}

class _TaskGroupCardState extends State<TaskGroupCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final group = widget.group;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: group.color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Заголовок группы
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: group.color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  // Иконка предмета
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: group.color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        group.subject.name.isNotEmpty 
                            ? group.subject.name[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Информация о предмете
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.subject.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: group.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${group.pendingTasks} из ${group.totalTasks} задач',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (group.hasOverdueTasks) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Просрочено: ${group.overdueTasks}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Прогресс бар
                  Column(
                    children: [
                      Text(
                        '${(group.completionPercentage * 100).round()}%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: group.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 60,
                        child: LinearProgressIndicator(
                          value: group.completionPercentage,
                          backgroundColor: group.color.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(group.color),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Стрелка разворота
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more,
                      color: group.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Список задач
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                children: group.sortedTasks.map((task) {
                  return TaskCard(
                    task: task,
                    subject: group.subject,
                    onCompleted: widget.onTaskCompleted,
                    onDeleted: widget.onTaskDeleted,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}