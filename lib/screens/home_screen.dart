import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/tasks_bloc.dart';
import '../blocs/subjects_bloc.dart';
import '../models/task.dart';
import '../models/subject.dart';
import '../utils/task_grouper.dart';
import '../widgets/task_group_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyTodo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TasksBloc>().add(RefreshTasks()),
          ),
        ],
      ),
      body: BlocBuilder<TasksBloc, TasksState>(
        builder: (context, tasksState) {
          return BlocBuilder<SubjectsBloc, SubjectsState>(
            builder: (context, subjectsState) {
              if (tasksState is TasksLoading || subjectsState is SubjectsLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (tasksState is TasksLoaded && subjectsState is SubjectsLoaded) {
                // Группируем задачи по предметам
                final taskGroups = TaskGrouper.groupTasksBySubject(
                  tasksState.tasks,
                  subjectsState.subjects,
                );
                
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<TasksBloc>().add(RefreshTasks());
                    context.read<SubjectsBloc>().add(RefreshSubjects());
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: taskGroups.isEmpty
                      ? const Center(
                          child: Text(
                            'Пока нет задач.\nДобавьте предмет и создайте первую задачу!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: taskGroups.length,
                          itemBuilder: (context, index) {
                            final group = taskGroups[index];
                            return TaskGroupCard(
                              group: group,
                              onTaskCompleted: () {
                                // Дополнительная логика при завершении задачи
                              },
                              onTaskDeleted: () {
                                // Дополнительная логика при удалении задачи
                              },
                            );
                          },
                        ),
                );
              }
              
              if (tasksState is TasksError) {
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<TasksBloc>().add(RefreshTasks());
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: Center(child: Text('Ошибка загрузки задач: ${tasksState.message}')),
                );
              }
              
              if (subjectsState is SubjectsError) {
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<SubjectsBloc>().add(RefreshSubjects());
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: Center(child: Text('Ошибка загрузки предметов: ${subjectsState.message}')),
                );
              }
              
              if (tasksState is TaskAdding || tasksState is TaskDeleting || tasksState is TaskUpdating) {
                return Stack(
                  children: [
                    // Показываем предыдущее состояние
                    BlocBuilder<TasksBloc, TasksState>(
                      buildWhen: (previous, current) => current is TasksLoaded,
                      builder: (context, previousTasksState) {
                        if (previousTasksState is TasksLoaded && subjectsState is SubjectsLoaded) {
                          final taskGroups = TaskGrouper.groupTasksBySubject(
                            previousTasksState.tasks,
                            subjectsState.subjects,
                          );
                          
                          return RefreshIndicator(
                            onRefresh: () async {
                              context.read<TasksBloc>().add(RefreshTasks());
                              context.read<SubjectsBloc>().add(RefreshSubjects());
                              await Future.delayed(const Duration(milliseconds: 500));
                            },
                            child: taskGroups.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Пока нет задач.\nДобавьте предмет и создайте первую задачу!',
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.only(bottom: 80),
                                    itemCount: taskGroups.length,
                                    itemBuilder: (context, index) {
                                      final group = taskGroups[index];
                                      return TaskGroupCard(group: group);
                                    },
                                  ),
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                    Container(
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ],
                );
              }
              
              return const Center(child: Text('Загрузка...'));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddTaskDialog(),
    );
  }
}


class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog({Key? key}) : super(key: key);

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 1));
  TaskPriority _priority = TaskPriority.medium;
  Subject? _selectedSubject;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить задачу'),
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
              decoration: const InputDecoration(labelText: 'Описание'),
              maxLines: 3,
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
                        child: Text(subject.name),
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
                  child: Text(_formatPriority(priority)),
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
                  final task = Task(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    subjectId: _selectedSubject!.id,
                    title: _titleController.text,
                    description: _descriptionController.text.isNotEmpty 
                        ? _descriptionController.text 
                        : null,
                    deadline: _deadline,
                    priority: _priority,
                    createdAt: DateTime.now(),
                  );
                  context.read<TasksBloc>().add(AddTask(task));
                  Navigator.of(context).pop(); // Закрываем немедленно
                }
              : null,
          child: const Text('Добавить'),
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}