import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/tasks_bloc_windows.dart';
import '../blocs/subjects_bloc_windows.dart';
import '../models/task_windows.dart';
import '../models/subject_windows.dart';
import '../theme/windows_theme.dart';
import '../widgets/task_card_windows.dart';
import '../widgets/task_dialog_windows.dart';

class HomeScreenWindows extends StatefulWidget {
  const HomeScreenWindows({Key? key}) : super(key: key);

  @override
  State<HomeScreenWindows> createState() => _HomeScreenWindowsState();
}

class _HomeScreenWindowsState extends State<HomeScreenWindows> {
  final TextEditingController _searchController = TextEditingController();
  TaskStatus? _selectedStatusFilter;
  String? _selectedSubjectFilter;
  TaskSortBy _sortBy = TaskSortBy.deadline;
  bool _ascending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // Windows-style header
          _buildHeader(),

          // Toolbar с фильтрами и поиском
          _buildToolbar(),

          // Основной контент
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Заголовок
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Мои задачи',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                BlocBuilder<TasksBloc, TasksState>(
                  builder: (context, state) {
                    if (state is TasksLoaded) {
                      final activeTasks = state.filteredTasks
                          .where((t) => t.status != TaskStatus.completed)
                          .length;
                      return Text(
                        '$activeTasks активных задач',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // Кнопки действий
          Row(
            children: [
              // Синхронизация (имитация)
              IconButton(
                onPressed: () {
                  context.read<TasksBloc>().add(LoadTasks());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Данные обновлены'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.sync, size: 20),
                tooltip: 'Обновить данные',
              ),

              const SizedBox(width: 8),

              // Создать задачу
              WindowsButton(
                text: 'Новая задача',
                icon: Icons.add,
                onPressed: _createNewTask,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Поиск
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Поиск задач...',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                context.read<TasksBloc>().add(FilterTasks(
                  statusFilter: _selectedStatusFilter,
                  subjectFilter: _selectedSubjectFilter,
                  searchQuery: value.isNotEmpty ? value : null,
                ));
              },
            ),
          ),

          const SizedBox(width: 16),

          // Фильтр по статусу
          Expanded(
            child: DropdownButtonFormField<TaskStatus?>(
              value: _selectedStatusFilter,
              decoration: const InputDecoration(
                labelText: 'Статус',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Все статусы'),
                ),
                ...TaskStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        _buildStatusIndicator(status),
                        const SizedBox(width: 8),
                        Text(_getStatusText(status)),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatusFilter = value;
                });
                context.read<TasksBloc>().add(FilterTasks(
                  statusFilter: value,
                  subjectFilter: _selectedSubjectFilter,
                  searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
                ));
              },
            ),
          ),

          const SizedBox(width: 16),

          // Фильтр по предмету
          Expanded(
            child: BlocBuilder<SubjectsBloc, SubjectsState>(
              builder: (context, state) {
                if (state is SubjectsLoaded) {
                  return DropdownButtonFormField<String?>(
                    value: _selectedSubjectFilter,
                    decoration: const InputDecoration(
                      labelText: 'Предмет',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Все предметы'),
                      ),
                      ...state.subjects.map((subject) {
                        return DropdownMenuItem(
                          value: subject.id,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 8,
                                backgroundColor: subject.colorValue,
                                child: Text(
                                  subject.abbreviation,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  subject.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSubjectFilter = value;
                      });
                      context.read<TasksBloc>().add(FilterTasks(
                        statusFilter: _selectedStatusFilter,
                        subjectFilter: value,
                        searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
                      ));
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          const SizedBox(width: 16),

          // Сортировка
          PopupMenuButton<TaskSortBy>(
            tooltip: 'Сортировка',
            icon: const Icon(Icons.sort),
            onSelected: (sortBy) {
              setState(() {
                if (_sortBy == sortBy) {
                  _ascending = !_ascending;
                } else {
                  _sortBy = sortBy;
                  _ascending = true;
                }
              });
              context.read<TasksBloc>().add(SortTasks(_sortBy, _ascending));
            },
            itemBuilder: (context) => [
              ...TaskSortBy.values.map((sortBy) {
                return PopupMenuItem(
                  value: sortBy,
                  child: Row(
                    children: [
                      Icon(
                        _getSortIcon(sortBy),
                        size: 16,
                        color: _sortBy == sortBy
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getSortText(sortBy),
                        style: TextStyle(
                          color: _sortBy == sortBy
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          fontWeight: _sortBy == sortBy
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                      if (_sortBy == sortBy) ...[
                        const Spacer(),
                        Icon(
                          _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<TasksBloc, TasksState>(
      builder: (context, state) {
        if (state is TasksLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is TasksError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ошибка загрузки задач',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                WindowsButton(
                  text: 'Попробовать снова',
                  onPressed: () {
                    context.read<TasksBloc>().add(LoadTasks());
                  },
                ),
              ],
            ),
          );
        }

        if (state is TasksLoaded) {
          if (state.filteredTasks.isEmpty) {
            return _buildEmptyState();
          }

          return _buildTasksList(state.filteredTasks);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty ||
                    _selectedStatusFilter != null ||
                    _selectedSubjectFilter != null
                ? 'Задачи не найдены'
                : 'Пока нет задач',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty ||
                    _selectedStatusFilter != null ||
                    _selectedSubjectFilter != null
                ? 'Попробуйте изменить фильтры поиска'
                : 'Создайте первую задачу для начала работы',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          WindowsButton(
            text: 'Создать задачу',
            icon: Icons.add,
            onPressed: _createNewTask,
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(List<Task> tasks) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TaskCardWindows(
            task: task,
            onTap: () => _editTask(task),
            onStatusChanged: () => _toggleTaskStatus(task),
            onDelete: () => _deleteTask(task),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(TaskStatus status) {
    Color color;
    switch (status) {
      case TaskStatus.pending:
        color = WindowsTheme.pendingStatus;
        break;
      case TaskStatus.inProgress:
        color = WindowsTheme.progressStatus;
        break;
      case TaskStatus.completed:
        color = WindowsTheme.completedStatus;
        break;
      case TaskStatus.cancelled:
        color = Colors.grey;
        break;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
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

  IconData _getSortIcon(TaskSortBy sortBy) {
    switch (sortBy) {
      case TaskSortBy.deadline:
        return Icons.schedule;
      case TaskSortBy.priority:
        return Icons.priority_high;
      case TaskSortBy.title:
        return Icons.sort_by_alpha;
      case TaskSortBy.createdAt:
        return Icons.access_time;
      case TaskSortBy.status:
        return Icons.check_circle_outline;
    }
  }

  String _getSortText(TaskSortBy sortBy) {
    switch (sortBy) {
      case TaskSortBy.deadline:
        return 'По дедлайну';
      case TaskSortBy.priority:
        return 'По приоритету';
      case TaskSortBy.title:
        return 'По названию';
      case TaskSortBy.createdAt:
        return 'По дате создания';
      case TaskSortBy.status:
        return 'По статусу';
    }
  }

  void _createNewTask() {
    showDialog(
      context: context,
      builder: (context) => const TaskDialogWindows(),
    );
  }

  void _editTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskDialogWindows(task: task),
    );
  }

  void _toggleTaskStatus(Task task) {
    context.read<TasksBloc>().add(ToggleTaskStatus(task.id));
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить задачу'),
        content: Text('Вы уверены, что хотите удалить задачу "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          WindowsButton(
            text: 'Удалить',
            isPrimary: false,
            onPressed: () {
              Navigator.pop(context);
              context.read<TasksBloc>().add(DeleteTask(task.id));
            },
          ),
        ],
      ),
    );
  }
}