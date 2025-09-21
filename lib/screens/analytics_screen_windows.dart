import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc_windows.dart';
import '../blocs/tasks_bloc_windows.dart';
import '../blocs/subjects_bloc_windows.dart';
import '../models/user_profile_windows.dart';
import '../models/task_windows.dart';
import '../theme/windows_theme.dart';
import '../services/database_service_windows.dart';

class AnalyticsScreenWindows extends StatelessWidget {
  const AnalyticsScreenWindows({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Профиль и аналитика',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Ваша статистика и достижения',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 12),
                    Text('Очистить данные'),
                  ],
                ),
                onTap: () => _clearAllData(context),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 12),
                    Text('Обновить статистику'),
                  ],
                ),
                onTap: () => _refreshStats(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Профиль пользователя
          _buildUserProfile(context),
          const SizedBox(height: 24),

          // Основная статистика
          _buildMainStats(context),
          const SizedBox(height: 24),

          // Детальная аналитика
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildTasksBreakdown(context),
                    const SizedBox(height: 16),
                    _buildSubjectsStats(context),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAchievements(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return WindowsCard(
            child: Row(
              children: [
                // Аватар
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: state.user.photoURL != null
                      ? NetworkImage(state.user.photoURL!)
                      : null,
                  child: state.user.photoURL == null
                      ? Text(
                          state.user.displayText.isNotEmpty
                              ? state.user.displayText[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : null,
                ),

                const SizedBox(width: 20),

                // Информация о пользователе
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.user.displayText,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (state.user.email != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          state.user.email!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            state.user.isAnonymous ? Icons.person_outline : Icons.verified_user,
                            size: 16,
                            color: state.user.isAnonymous
                                ? Colors.orange
                                : WindowsTheme.successGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            state.user.isAnonymous ? 'Гостевой аккаунт' : 'Аккаунт подтвержден',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: state.user.isAnonymous
                                  ? Colors.orange
                                  : WindowsTheme.successGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Прогресс-индикатор
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: state.user.completionRate,
                        strokeWidth: 6,
                        backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Center(
                        child: Text(
                          state.user.completionPercentage,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMainStats(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Всего задач',
                  state.user.totalTasks.toString(),
                  Icons.assignment,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Выполнено',
                  state.user.completedTasks.toString(),
                  Icons.check_circle,
                  WindowsTheme.successGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Предметов',
                  state.user.totalSubjects.toString(),
                  Icons.folder,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Всего выполнено',
                  state.user.totalCompletedAllTime.toString(),
                  Icons.emoji_events,
                  Colors.purple,
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return WindowsCard(
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTasksBreakdown(BuildContext context) {
    return BlocBuilder<TasksBloc, TasksState>(
      builder: (context, state) {
        if (state is TasksLoaded) {
          final tasks = state.tasks.where((t) => !t.isDeleted).toList();
          final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
          final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
          final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
          final overdue = tasks.where((t) => t.isOverdue).length;

          return WindowsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Разбивка задач',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTaskBreakdownItem(context, 'Ожидают', pending, WindowsTheme.pendingStatus),
                _buildTaskBreakdownItem(context, 'В работе', inProgress, WindowsTheme.progressStatus),
                _buildTaskBreakdownItem(context, 'Выполнены', completed, WindowsTheme.completedStatus),
                if (overdue > 0)
                  _buildTaskBreakdownItem(context, 'Просрочены', overdue, WindowsTheme.errorRed),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTaskBreakdownItem(BuildContext context, String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsStats(BuildContext context) {
    return BlocBuilder<SubjectsBloc, SubjectsState>(
      builder: (context, state) {
        if (state is SubjectsLoaded) {
          return WindowsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Предметы',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...state.subjects.take(5).map((subject) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
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
                      Expanded(
                        child: Text(
                          subject.name,
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAchievements(BuildContext context) {
    return WindowsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Достижения',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return Column(
                  children: [
                    _buildAchievementItem(
                      context,
                      '🎯',
                      'Первая задача',
                      'Создали свою первую задачу',
                      state.user.totalTasks > 0,
                    ),
                    _buildAchievementItem(
                      context,
                      '✅',
                      'Выполнитель',
                      'Выполнили первую задачу',
                      state.user.completedTasks > 0,
                    ),
                    _buildAchievementItem(
                      context,
                      '📚',
                      'Организатор',
                      'Создали 3 предмета',
                      state.user.totalSubjects >= 3,
                    ),
                    _buildAchievementItem(
                      context,
                      '🔥',
                      'Продуктивность',
                      'Выполнили 10 задач',
                      state.user.totalCompletedAllTime >= 10,
                    ),
                    _buildAchievementItem(
                      context,
                      '⭐',
                      'Мастер',
                      'Выполнили 25 задач',
                      state.user.totalCompletedAllTime >= 25,
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(
    BuildContext context,
    String emoji,
    String title,
    String description,
    bool isUnlocked,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            emoji,
            style: TextStyle(
              fontSize: 24,
              color: isUnlocked ? null : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isUnlocked ? null : Colors.grey,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isUnlocked
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (isUnlocked)
            Icon(
              Icons.check_circle,
              color: WindowsTheme.successGreen,
              size: 16,
            ),
        ],
      ),
    );
  }

  void _clearAllData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить все данные'),
        content: const Text(
          'Это действие удалит все ваши задачи и предметы, но сохранит статистику достижений. '
          'Вы уверены, что хотите продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          WindowsButton(
            text: 'Очистить',
            isPrimary: false,
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseService().clearAllUserData();

              // Обновляем все BLoC'и
              context.read<TasksBloc>().add(LoadTasks());
              context.read<SubjectsBloc>().add(LoadSubjects());
              context.read<AuthBloc>().add(AuthInitialize());

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Данные очищены'),
                  backgroundColor: WindowsTheme.successGreen,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _refreshStats(BuildContext context) {
    context.read<TasksBloc>().add(LoadTasks());
    context.read<SubjectsBloc>().add(LoadSubjects());
    context.read<AuthBloc>().add(AuthInitialize());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Статистика обновлена'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}