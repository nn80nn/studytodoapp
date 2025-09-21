import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc_windows.dart';
import '../screens/auth_screen_windows.dart';
import '../widgets/main_navigation_windows.dart';

class AuthWrapperWindows extends StatelessWidget {
  const AuthWrapperWindows({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Инициализация StudyToDo...'),
                ],
              ),
            ),
          );
        } else if (state is AuthAuthenticated) {
          return const MainNavigationWindows();
        } else if (state is AuthUnauthenticated) {
          return const AuthScreenWindows();
        } else if (state is AuthError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка приложения',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(AuthInitialize());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Попробовать снова'),
                  ),
                ],
              ),
            ),
          );
        }

        return const Scaffold(
          body: Center(
            child: Text('Неизвестное состояние'),
          ),
        );
      },
    );
  }
}