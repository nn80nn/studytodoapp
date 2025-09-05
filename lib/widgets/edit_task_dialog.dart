import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/task.dart';
import '../models/subject.dart';
import '../blocs/tasks_bloc.dart';
import '../blocs/subjects_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../services/ai_service.dart';

class EditTaskDialog extends StatefulWidget {
  final Task task;
  final Subject subject;

  const EditTaskDialog({
    super.key,
    required this.task,
    required this.subject,
  });

  @override
  EditTaskDialogState createState() => EditTaskDialogState();
}

class EditTaskDialogState extends State<EditTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _deadline;
  late TaskPriority _priority;
  Subject? _selectedSubject;
  bool _isImproving = false;
  bool _hasApiKey = false;
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.task.title;
    _descriptionController.text = widget.task.description ?? '';
    _deadline = widget.task.deadline;
    _priority = widget.task.priority;
    _selectedSubject = widget.subject;
    _checkApiKey();
  }

  void _checkApiKey() {
    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;
    if (authState is AuthAuthenticated && authState.userProfile.hasGeminiApiKey) {
      _hasApiKey = true;
      _apiKey = authState.userProfile.geminiApiKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать задачу'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Название задачи'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Описание',
                suffixIcon: _hasApiKey
                    ? (_isImproving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.auto_fix_high),
                            onPressed: _canImprove() ? _improveDescription : null,
                            tooltip: 'Улучшить с помощью AI',
                          ))
                    : null,
              ),
              maxLines: 3,
              onChanged: (value) => setState(() {}), // Trigger rebuild for button state
            ),
            const SizedBox(height: 16),
            BlocBuilder<SubjectsBloc, SubjectsState>(
              builder: (context, state) {
                if (state is SubjectsLoaded && state.subjects.isNotEmpty) {
                  return DropdownButtonFormField<Subject>(
                    value: _selectedSubject,
                    decoration: const InputDecoration(labelText: 'Предмет'),
                    items: state.subjects.map((subject) {
                      return DropdownMenuItem(
                        value: subject,
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: subject.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(subject.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedSubject = value),
                  );
                }
                return const Text('Загрузите предметы...');
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Приоритет'),
              items: TaskPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getPriorityColor(priority),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_formatPriority(priority)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _priority = value!),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text('Дедлайн: ${_formatDate(_deadline)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _deadline,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _deadline = date);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: (_titleController.text.isNotEmpty && _selectedSubject != null)
              ? () {
                  final updatedTask = widget.task.copyWith(
                    title: _titleController.text,
                    description: _descriptionController.text.isNotEmpty 
                        ? _descriptionController.text 
                        : null,
                    deadline: _deadline,
                    priority: _priority,
                  );
                  
                  // Если изменился предмет, создаем новую задачу
                  final finalTask = _selectedSubject!.id != widget.task.subjectId 
                      ? Task(
                          id: updatedTask.id,
                          subjectId: _selectedSubject!.id,
                          title: updatedTask.title,
                          description: updatedTask.description,
                          deadline: updatedTask.deadline,
                          plannedTime: updatedTask.plannedTime,
                          priority: updatedTask.priority,
                          status: updatedTask.status,
                          createdAt: updatedTask.createdAt,
                        )
                      : updatedTask;
                  
                  context.read<TasksBloc>().add(UpdateTask(finalTask));
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
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

  bool _canImprove() {
    return _descriptionController.text.trim().isNotEmpty &&
           _titleController.text.trim().isNotEmpty &&
           _selectedSubject != null &&
           !_isImproving;
  }

  Future<void> _improveDescription() async {
    if (!_canImprove() || _apiKey == null) return;
    
    setState(() => _isImproving = true);
    
    try {
      AIService().initialize(_apiKey!);
      final improvedDescription = await AIService().improveTaskDescription(
        _descriptionController.text.trim(),
        _titleController.text.trim(),
        _selectedSubject!.name,
      );
      
      if (mounted) {
        setState(() {
          _descriptionController.text = improvedDescription;
          _isImproving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImproving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка улучшения описания: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}