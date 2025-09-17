import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/tasks_bloc.dart';
import '../blocs/subjects_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../models/task.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

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
                    } else if (value == 'clear') {
                      _showClearDataDialog(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text('Выйти'),
                    ),
                    const PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(Icons.clear_all, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Очистить данные'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Удалить аккаунт'),
                        ],
                      ),
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
                    _buildUserProfile(context, authState.userProfile),
                    const SizedBox(height: 20),
                    if (!authState.userProfile.isAnonymous)
                      _buildSyncSection(context, authState.userProfile),
                    if (!authState.userProfile.isAnonymous)
                      const SizedBox(height: 20),
                    BlocBuilder<TasksBloc, TasksState>(
                      builder: (context, tasksState) {
                        return BlocBuilder<SubjectsBloc, SubjectsState>(
                          builder: (context, subjectsState) {
                            if (tasksState is TasksLoading || subjectsState is SubjectsLoading) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (tasksState is TasksLoaded && subjectsState is SubjectsLoaded) {
                              return _buildComprehensiveStats(tasksState.tasks, subjectsState.subjects.length, authState.userProfile);
                            } else if (tasksState is TasksError) {
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text('Ошибка загрузки задач: ${tasksState.message}'),
                                ),
                              );
                            } else if (subjectsState is SubjectsError) {
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text('Ошибка загрузки предметов: ${subjectsState.message}'),
                                ),
                              );
                            }
                            return const Center(child: CircularProgressIndicator());
                          },
                        );
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

  Widget _buildComprehensiveStats(List<Task> tasks, int subjectsCount, UserProfile profile) {
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
            const Text(
              'Общая статистика',
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
            _buildStatRow('Предметов', subjectsCount, Colors.purple),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _buildStatRow('Выполнено за всё время', profile.totalCompletedAllTime, Colors.teal),
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Процент выполнения: ${(completedTasks / tasks.length * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: completedTasks / tasks.length,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ],
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, UserProfile profile) {
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
                    ? const Icon(Icons.person, size: 30)
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Последний вход: ${_formatDate(profile.lastLoginAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showApiKeyDialog(context, profile),
                  icon: Icon(
                    profile.hasGeminiApiKey ? Icons.smart_toy : Icons.smart_toy_outlined,
                    size: 16,
                  ),
                  label: Text(
                    profile.hasGeminiApiKey ? 'Настроить AI' : 'Добавить AI ключ',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
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
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(AuthContinueAsAnonymous());
              },
              icon: const Icon(Icons.person_outline),
              label: const Text('Продолжить как гость'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'В режиме гостя данные сохраняются только на этом устройстве',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
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

  void _showApiKeyDialog(BuildContext context, UserProfile profile) {
    final apiKeyController = TextEditingController(text: profile.geminiApiKey ?? '');
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройка AI'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Для использования AI-функций введите ваш API ключ Google Gemini:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API ключ Gemini',
                  prefixIcon: Icon(Icons.key),
                  helperText: 'Получить ключ можно на ai.google.dev',
                ),
                obscureText: true,
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 10) {
                    return 'API ключ должен содержать минимум 10 символов';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'С помощью AI вы сможете улучшать описания задач - исправлять ошибки и делать текст более читаемым.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          if (profile.hasGeminiApiKey)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(AuthUpdateGeminiApiKey(null));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('API ключ удален'),
                  ),
                );
              },
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop();
                final newApiKey = apiKeyController.text.trim();
                context.read<AuthBloc>().add(AuthUpdateGeminiApiKey(
                  newApiKey.isEmpty ? null : newApiKey,
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(newApiKey.isEmpty 
                        ? 'API ключ удален' 
                        : 'API ключ сохранен'),
                  ),
                );
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncSection(BuildContext context, UserProfile profile) {
    final databaseService = DatabaseService();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Синхронизация данных',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                FutureBuilder<bool>(
                  future: databaseService.canSync,
                  builder: (context, snapshot) {
                    final canSync = snapshot.data ?? false;
                    return Icon(
                      canSync ? Icons.cloud_done : Icons.cloud_off,
                      color: canSync ? Colors.green : Colors.orange,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<DateTime?>(
              future: databaseService.lastSyncTime,
              builder: (context, snapshot) {
                final lastSync = snapshot.data;
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Последняя синхронизация:',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            lastSync != null 
                                ? _formatDate(lastSync)
                                : 'Никогда',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FutureBuilder<bool>(
                      future: databaseService.canSync,
                      builder: (context, snapshot) {
                        final canSync = snapshot.data ?? false;
                        return ElevatedButton.icon(
                          onPressed: canSync ? () => _syncNow(context) : null,
                          icon: const Icon(Icons.sync, size: 16),
                          label: const Text('Синхронизировать'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canSync ? Colors.blue : Colors.grey,
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Данные автоматически синхронизируются при наличии интернета. Ваши задачи и предметы сохраняются локально.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncNow(BuildContext context) async {
    final databaseService = DatabaseService();

    // Сохраняем Navigator для закрытия диалога
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Синхронизация данных...'),
            ],
          ),
        ),
      );

      await databaseService.forceSyncNow();

      // Закрываем диалог загрузки
      navigator.pop();

      // Обновляем данные в BLoC
      if (context.mounted) {
        context.read<TasksBloc>().add(RefreshTasks());
        context.read<SubjectsBloc>().add(RefreshSubjects());
      }

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Синхронизация завершена успешно'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Закрываем диалог загрузки в случае ошибки
      navigator.pop();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Ошибка синхронизации: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить все данные?'),
        content: const Text(
          'Это действие удалит все ваши задачи и предметы как из локальной, так и из удалённой базы данных. Статистика выполненных задач за всё время сохранится.\n\nДанное действие необратимо!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearAllData(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData(BuildContext context) async {
    final databaseService = DatabaseService();

    // Сохраняем Navigator для закрытия диалога
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Очищаем данные...'),
            ],
          ),
        ),
      );

      await databaseService.clearAllUserData();

      // Закрываем диалог загрузки
      navigator.pop();

      // Обновляем данные в BLoC
      if (context.mounted) {
        context.read<TasksBloc>().add(RefreshTasks());
        context.read<SubjectsBloc>().add(RefreshSubjects());
      }

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Все данные успешно удалены'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Закрываем диалог загрузки в случае ошибки
      navigator.pop();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Ошибка очистки данных: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    // Проверка на очень большие разницы для предотвращения переполнения
    if (difference.inDays > 365) {
      final yearsDiff = (difference.inDays / 365).floor();
      return yearsDiff == 1 ? '1 год назад' : '$yearsDiff лет назад';
    } else if (difference.inDays > 30) {
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