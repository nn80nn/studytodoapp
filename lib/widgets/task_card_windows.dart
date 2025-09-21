import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/task_windows.dart';
import '../models/subject_windows.dart';
import '../blocs/subjects_bloc_windows.dart';
import '../theme/windows_theme.dart';

class TaskCardWindows extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onStatusChanged;
  final VoidCallback? onDelete;

  const TaskCardWindows({
    Key? key,
    required this.task,
    this.onTap,
    this.onStatusChanged,
    this.onDelete,
  }) : super(key: key);

  @override
  State<TaskCardWindows> createState() => _TaskCardWindowsState();
}

class _TaskCardWindowsState extends State<TaskCardWindows>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubjectsBloc, SubjectsState>(
      builder: (context, state) {
        Subject? subject;
        if (state is SubjectsLoaded) {
          try {
            subject = state.subjects.firstWhere((s) => s.id == widget.task.subjectId);
          } catch (e) {
            // Subject not found
          }
        }

        return MouseRegion(
          onEnter: (_) {
            setState(() {
              _isHovered = true;
            });
            _animationController.forward();
          },
          onExit: (_) {
            setState(() {
              _isHovered = false;
            });
            _animationController.reverse();
          },
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isHovered
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      : Theme.of(context).colorScheme.outline,
                  width: _isHovered ? 1.5 : 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.04),
                    offset: const Offset(0, 2),
                    blurRadius: _isHovered ? 8 : 4,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Чекбокс для статуса
                        _buildStatusCheckbox(),

                        const SizedBox(width: 16),

                        // Основной контент
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTaskHeader(subject),
                              const SizedBox(height: 8),
                              _buildTaskContent(),
                              const SizedBox(height: 12),
                              _buildTaskMetadata(),
                            ],
                          ),
                        ),

                        // Кнопки действий
                        if (_isHovered) _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCheckbox() {
    final isCompleted = widget.task.status == TaskStatus.completed;

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted
              ? WindowsTheme.completedStatus
              : Theme.of(context).colorScheme.outline,
          width: 2,
        ),
        color: isCompleted ? WindowsTheme.completedStatus : Colors.transparent,
      ),
      child: InkWell(
        onTap: widget.onStatusChanged,
        borderRadius: BorderRadius.circular(10),
        child: isCompleted
            ? const Icon(
                Icons.check,
                size: 14,
                color: Colors.white,
              )
            : null,
      ),
    );
  }

  Widget _buildTaskHeader(Subject? subject) {
    return Row(
      children: [
        // Иконка предмета
        if (subject != null) ...[
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: subject.colorValue,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                subject.abbreviation,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],

        // Название задачи
        Expanded(
          child: Text(
            widget.task.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              decoration: widget.task.status == TaskStatus.completed
                  ? TextDecoration.lineThrough
                  : null,
              color: widget.task.status == TaskStatus.completed
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                  : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Приоритет
        _buildPriorityIndicator(),
      ],
    );
  }

  Widget _buildTaskContent() {
    if (widget.task.description != null && widget.task.description!.isNotEmpty) {
      return Text(
        widget.task.description!,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          decoration: widget.task.status == TaskStatus.completed
              ? TextDecoration.lineThrough
              : null,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTaskMetadata() {
    return Row(
      children: [
        // Дедлайн
        _buildDeadlineInfo(),

        if (widget.task.plannedTime != null) ...[
          const SizedBox(width: 16),
          _buildTimeInfo(),
        ],

        const Spacer(),

        // Статус
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildPriorityIndicator() {
    Color color;
    IconData icon;

    switch (widget.task.priority) {
      case TaskPriority.high:
        color = WindowsTheme.highPriority;
        icon = Icons.keyboard_arrow_up;
        break;
      case TaskPriority.medium:
        color = WindowsTheme.mediumPriority;
        icon = Icons.remove;
        break;
      case TaskPriority.low:
        color = WindowsTheme.lowPriority;
        icon = Icons.keyboard_arrow_down;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Icon(
        icon,
        size: 14,
        color: color,
      ),
    );
  }

  Widget _buildDeadlineInfo() {
    final deadline = widget.task.deadline;
    final now = DateTime.now();
    final difference = deadline.difference(now);

    String text;
    Color color = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    IconData icon = Icons.schedule;

    if (widget.task.isOverdue) {
      text = 'Просрочено';
      color = WindowsTheme.errorRed;
      icon = Icons.error_outline;
    } else if (difference.inDays == 0) {
      text = 'Сегодня ${_formatTime(deadline)}';
      color = WindowsTheme.warningYellow;
    } else if (difference.inDays == 1) {
      text = 'Завтра ${_formatTime(deadline)}';
    } else if (difference.inDays < 7) {
      text = '${difference.inDays} дн.';
    } else {
      text = _formatDate(deadline);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfo() {
    final plannedTime = widget.task.plannedTime!;
    final hours = plannedTime ~/ 60;
    final minutes = plannedTime % 60;

    String timeText;
    if (hours > 0) {
      timeText = '${hours}ч ${minutes}м';
    } else {
      timeText = '${minutes}м';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timer_outlined,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Text(
          timeText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    switch (widget.task.status) {
      case TaskStatus.pending:
        color = WindowsTheme.pendingStatus;
        text = 'Ожидает';
        break;
      case TaskStatus.inProgress:
        color = WindowsTheme.progressStatus;
        text = 'В работе';
        break;
      case TaskStatus.completed:
        color = WindowsTheme.completedStatus;
        text = 'Выполнена';
        break;
      case TaskStatus.cancelled:
        color = Colors.grey;
        text = 'Отменена';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: widget.onTap,
          icon: const Icon(Icons.edit_outlined, size: 16),
          tooltip: 'Редактировать',
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          onPressed: widget.onDelete,
          icon: const Icon(Icons.delete_outline, size: 16),
          tooltip: 'Удалить',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
  }
}