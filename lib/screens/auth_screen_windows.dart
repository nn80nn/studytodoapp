import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc_windows.dart';
import '../services/database_service_windows.dart';

class AuthScreenWindows extends StatefulWidget {
  const AuthScreenWindows({Key? key}) : super(key: key);

  @override
  State<AuthScreenWindows> createState() => _AuthScreenWindowsState();
}

class _AuthScreenWindowsState extends State<AuthScreenWindows> {
  bool _isLogin = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Card(
              elevation: 8,
              child: Container(
                width: 450,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'StudyToDo',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'для Windows',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                    const SizedBox(height: 32),
                    _buildAuthForm(),
                    const SizedBox(height: 24),
                    _buildSwitchModeButton(),
                    const SizedBox(height: 16),
                    _buildAnonymousButton(),
                    const SizedBox(height: 24),
                    _buildDemoDataButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (!_isLogin) ...[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Имя',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (!_isLogin && (value == null || value.trim().isEmpty)) {
                  return 'Введите имя';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
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
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Пароль',
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите пароль';
              }
              if (value.length < 6) {
                return 'Пароль должен быть не менее 6 символов';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isLogin ? 'Войти' : 'Создать аккаунт'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchModeButton() {
    return TextButton(
      onPressed: _isLoading
          ? null
          : () {
              setState(() {
                _isLogin = !_isLogin;
              });
            },
      child: Text(
        _isLogin
            ? 'Нет аккаунта? Создать новый'
            : 'Уже есть аккаунт? Войти',
      ),
    );
  }

  Widget _buildAnonymousButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _signInAnonymously,
        icon: const Icon(Icons.person_outline),
        label: const Text('Продолжить как гость'),
      ),
    );
  }

  Widget _buildDemoDataButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.science,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 8),
          Text(
            'Хотите протестировать?',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isLoading ? null : _createDemoData,
            child: const Text('Создать демо данные'),
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        context.read<AuthBloc>().add(AuthSignInLocal(
              _emailController.text.trim(),
              _passwordController.text,
            ));
      } else {
        context.read<AuthBloc>().add(AuthCreateLocalAccount(
              _emailController.text.trim(),
              _passwordController.text,
              _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
            ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _signInAnonymously() async {
    setState(() {
      _isLoading = true;
    });

    try {
      context.read<AuthBloc>().add(AuthSignInAnonymously());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _createDemoData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Сначала войдем как гость
      context.read<AuthBloc>().add(AuthSignInAnonymously());

      // Затем создадим демо данные
      await Future.delayed(const Duration(milliseconds: 500));
      await DatabaseService().createDemoData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Демо данные созданы! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка создания демо данных: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }
}