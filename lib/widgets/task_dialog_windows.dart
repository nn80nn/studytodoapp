import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../models/task_windows.dart';
import '../models/subject_windows.dart';
import '../blocs/tasks_bloc_windows.dart';
import '../blocs/subjects_bloc_windows.dart';
import '../services/database_service_windows.dart';
import '../theme/windows_theme.dart';

class TaskDialogWindows extends StatefulWidget {
  final Task? task;

  const TaskDialogWindows({Key? key, this.task}) : super(key: key);

  @override
  State<TaskDialogWindows> createState() => _TaskDialogWindowsState();
}

class _TaskDialogWindowsState extends State<TaskDialogWindows> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _uuid = const Uuid();

  String? _selectedSubjectId;
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskStatus _selectedStatus = TaskStatus.pending;
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  int? _plannedTime; // в минутах

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.task != null) {
      final task = widget.task!;
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _selectedSubjectId = task.subjectId;
      _selectedPriority = task.priority;
      _selectedStatus = task.status;
      _selectedDeadline = task.deadline;
      _selectedTime = TimeOfDay.fromDateTime(task.deadline);
      _plannedTime = task.plannedTime;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildForm(),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.task != null ? Icons.edit : Icons.add_task,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.task != null ? 'Редактировать задачу' : 'Новая задача',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Название задачи
          _buildFormField(
            label: 'Название задачи',
            child: TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Введите название задачи...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите название задачи';
                }
                return null;
              },
              autofocus: true,
            ),
          ),

          const SizedBox(height: 20),

          // Предмет
          _buildFormField(
            label: 'Предмет',
            child: BlocBuilder<SubjectsBloc, SubjectsState>(
              builder: (context, state) {
                if (state is SubjectsLoaded) {
                  return DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    decoration: const InputDecoration(
                      hintText: 'Выберите предмет...',
                    ),
                    validator: (value) {
                      if (value == null) {
                        return 'Выберите предмет';
                      }
                      return null;
                    },
                    items: state.subjects.map((subject) {
                      return DropdownMenuItem(
                        value: subject.id,
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: subject.colorValue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  subject.abbreviation,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(subject.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSubjectId = value;
                      });
                    },
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
          ),

          const SizedBox(height: 20),

          // Описание
          _buildFormField(
            label: 'Описание (необязательно)',
            child: TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Дополнительная информация о задаче...',
              ),
              maxLines: 3,
            ),
          ),

          const SizedBox(height: 20),

          // Дедлайн и время
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  label: 'Дедлайн',
                  child: InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(_formatDate(_selectedDeadline)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField(
                  label: 'Время',
                  child: InkWell(
                    onTap: _selectTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(_selectedTime.format(context)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Приоритет и статус
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  label: 'Приоритет',
                  child: DropdownButtonFormField<TaskPriority>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(),
                    items: TaskPriority.values.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Row(
                          children: [
                            _buildPriorityIcon(priority),
                            const SizedBox(width: 12),
                            Text(_getPriorityText(priority)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPriority = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              if (widget.task != null)
                Expanded(
                  child: _buildFormField(
                    label: 'Статус',
                    child: DropdownButtonFormField<TaskStatus>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(),
                      items: TaskStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Row(
                            children: [
                              _buildStatusIcon(status),
                              const SizedBox(width: 12),
                              Text(_getStatusText(status)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Планируемое время
          _buildFormField(
            label: 'Планируемое время (необязательно)',
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: (_plannedTime ?? 60).toDouble(),
                    min: 15,
                    max: 480,
                    divisions: 31,
                    label: _formatPlannedTime(_plannedTime ?? 60),
                    onChanged: (value) {
                      setState(() {
                        _plannedTime = value.round();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: Text(
                    _formatPlannedTime(_plannedTime ?? 60),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _plannedTime = null;
                    });
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  tooltip: 'Очистить',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          const SizedBox(width: 12),
          WindowsButton(
            text: widget.task != null ? 'Сохранить' : 'Создать',
            onPressed: _saveTask,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityIcon(TaskPriority priority) {
    Color color;
    IconData icon;

    switch (priority) {
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

    return Icon(icon, color: color, size: 16);
  }

  Widget _buildStatusIcon(TaskStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case TaskStatus.pending:
        color = WindowsTheme.pendingStatus;
        icon = Icons.schedule;
        break;
      case TaskStatus.inProgress:
        color = WindowsTheme.progressStatus;
        icon = Icons.play_arrow;
        break;
      case TaskStatus.completed:
        color = WindowsTheme.completedStatus;
        icon = Icons.check_circle;
        break;
      case TaskStatus.cancelled:
        color = Colors.grey;
        icon = Icons.cancel;
        break;
    }

    return Icon(icon, color: color, size: 16);
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'Высокий';
      case TaskPriority.medium:
        return 'Средний';
      case TaskPriority.low:
        return 'Низкий';
    }
  }

  String _getStatusText(TaskStatus status) {
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

  String _formatDate(DateTime date) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatPlannedTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0) {
      return '${hours}ч ${mins}м';
    } else {
      return '${mins}м';
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDeadline.hour,
          _selectedDeadline.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDeadline = DateTime(
          _selectedDeadline.year,
          _selectedDeadline.month,
          _selectedDeadline.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final userId = DatabaseService().currentUserId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка: пользователь не найден'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final task = Task(
      id: widget.task?.id ?? _uuid.v4(),
      userId: userId,
      subjectId: _selectedSubjectId!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      deadline: _selectedDeadline,
      plannedTime: _plannedTime,
      priority: _selectedPriority,
      status: _selectedStatus,
      createdAt: widget.task?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.task != null) {
      context.read<TasksBloc>().add(UpdateTask(task));
    } else {
      context.read<TasksBloc>().add(AddTask(task));
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.task != null
              ? 'Задача обновлена'
              : 'Задача создана',
        ),
        backgroundColor: WindowsTheme.successGreen,
      ),
    );
  }
}