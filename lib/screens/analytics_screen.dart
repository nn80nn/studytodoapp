import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/tasks_bloc.dart';
import '../blocs/subjects_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../models/task.dart';
import '../models/user_profile.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль и аналитика'),
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return PopupMenuButton(
                  icon: const Icon(Icons.account_circle),
                  onSelected: (value) {
                    if (value == 'logout') {
                      context.read<AuthBloc>().add(AuthSignOut());
                    } else if (value == 'delete') {
                      _showDeleteAccountDialog(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text('Выйти'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Удалить аккаунт'),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthUnauthenticated) {
            return _buildAuthOptions(context);
          } else if (authState is AuthAuthenticated) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<TasksBloc>().add(RefreshTasks());
                context.read<SubjectsBloc>().add(RefreshSubjects());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserProfile(authState.userProfile),
                    const SizedBox(height: 20),
                    BlocBuilder<TasksBloc, TasksState>(
                      builder: (context, state) {
                        if (state is TasksLoading) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (state is TasksLoaded) {
                          return _buildTasksStats(state.tasks);
                        } else if (state is TasksError) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text('Ошибка загрузки задач: ${state.message}'),
                            ),
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                    const SizedBox(height: 20),
                    BlocBuilder<SubjectsBloc, SubjectsState>(
                      builder: (context, state) {
                        if (state is SubjectsLoading) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (state is SubjectsLoaded) {
                          return _buildSubjectsStats(state.subjects.length);
                        } else if (state is SubjectsError) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text('Ошибка загрузки предметов: ${state.message}'),
                            ),
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ],
                ),
              ),
            );
          } else if (authState is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (authState is AuthError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ошибка аутентификации: ${authState.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<AuthBloc>().add(AuthInitialize()),
                    child: const Text('Попробовать снова'),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildTasksStats(List<Task> tasks) {
    final completedTasks = tasks.where((task) => task.status == TaskStatus.completed).length;
    final pendingTasks = tasks.where((task) => task.status == TaskStatus.pending).length;
    final overdueTasks = tasks.where((task) => 
        task.status == TaskStatus.overdue || 
        (task.status == TaskStatus.pending && task.deadline.isBefore(DateTime.now()))
    ).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика задач',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Всего задач', tasks.length, Colors.blue),
            _buildStatRow('Выполнено', completedTasks, Colors.green),
            _buildStatRow('В работе', pendingTasks, Colors.orange),
            _buildStatRow('Просрочено', overdueTasks, Colors.red),
            const SizedBox(height: 16),
            if (tasks.isNotEmpty) ...[
              Text('Процент выполнения: ${(completedTasks / tasks.length * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: completedTasks / tasks.length,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsStats(int subjectsCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика предметов',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Всего предметов', subjectsCount, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile(UserProfile profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: profile.hasProfileImage 
                    ? NetworkImage(profile.photoURL!)
                    : null,
                  child: !profile.hasProfileImage 
                    ? Icon(Icons.person, size: 30)
                    : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayNameOrEmail,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (profile.email != null && profile.displayName != null)
                        Text(
                          profile.email!,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      if (profile.isAnonymous)
                        const Text(
                          'Анонимный пользователь',
                          style: TextStyle(
                            color: Colors.orange,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Личная статистика',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatRow('Всего задач', profile.totalTasks, Colors.blue),
            _buildStatRow('Выполнено', profile.completedTasks, Colors.green),
            _buildStatRow('Осталось', profile.pendingTasks, Colors.orange),
            _buildStatRow('Предметов', profile.totalSubjects, Colors.purple),
            if (profile.totalTasks > 0) ...[
              const SizedBox(height: 16),
              Text('Процент выполнения: ${(profile.completionRate * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: profile.completionRate,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Последний вход: ${_formatDate(profile.lastLoginAt)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthOptions(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_circle,
              size: 100,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              'Войдите в свой аккаунт',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Синхронизация задач и личная статистика доступны только после входа в систему',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(AuthSignInWithGoogle());
              },
              icon: const Icon(Icons.login),
              label: const Text('Войти с Google'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                _showEmailPasswordDialog(context, false);
              },
              icon: const Icon(Icons.email),
              label: const Text('Войти с email'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                _showEmailPasswordDialog(context, true);
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Регистрация'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(AuthSignInAnonymously());
              },
              icon: const Icon(Icons.person_outline),
              label: const Text('Войти анонимно'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить аккаунт'),
        content: const Text(
          'Вы уверены, что хотите удалить свой аккаунт? Все ваши данные будут безвозвратно потеряны.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(AuthDeleteAccount());
              
              // Показываем уведомление о процессе удаления
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Удаление аккаунта... Пожалуйста, подождите.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showEmailPasswordDialog(BuildContext context, bool isRegistration) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRegistration ? 'Регистрация' : 'Вход в систему'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите email';
                  }
                  if (!value.contains('@')) {
                    return 'Введите корректный email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите пароль';
                  }
                  if (value.length < 6) {
                    return 'Пароль должен содержать минимум 6 символов';
                  }
                  return null;
                },
              ),
              if (!isRegistration) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showResetPasswordDialog(context);
                  },
                  child: const Text('Забыли пароль?'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop();
                if (isRegistration) {
                  context.read<AuthBloc>().add(AuthCreateUserWithEmailPassword(
                    emailController.text.trim(),
                    passwordController.text,
                  ));
                } else {
                  context.read<AuthBloc>().add(AuthSignInWithEmailPassword(
                    emailController.text.trim(),
                    passwordController.text,
                  ));
                }
              }
            },
            child: Text(isRegistration ? 'Зарегистрироваться' : 'Войти'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сброс пароля'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              helperText: 'Мы отправим ссылку для сброса пароля на ваш email',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Введите email';
              }
              if (!value.contains('@')) {
                return 'Введите корректный email';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(AuthResetPassword(
                  emailController.text.trim(),
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ссылка для сброса пароля отправлена на email'),
                  ),
                );
              }
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}.${date.month}.${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'только что';
    }
  }
}