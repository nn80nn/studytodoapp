import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Windows-specific imports
import 'blocs/auth_bloc_windows.dart';
import 'blocs/subjects_bloc_windows.dart';
import 'blocs/tasks_bloc_windows.dart';
import 'widgets/auth_wrapper_windows.dart';
import 'theme/windows_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 StudyToDo для Windows запущен!');
  print('📱 Платформа: ${Platform.operatingSystem}');

  runApp(StudyTodoSimpleWindowsApp());
}

class StudyTodoSimpleWindowsApp extends StatelessWidget {
  StudyTodoSimpleWindowsApp({super.key});

  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthWrapperWindows(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc()),
        BlocProvider(create: (context) => SubjectsBloc()..add(LoadSubjects())),
        BlocProvider(create: (context) => TasksBloc()..add(LoadTasks())),
      ],
      child: MaterialApp.router(
        title: 'StudyToDo - Windows',
        debugShowCheckedModeBanner: false,
        theme: WindowsTheme.lightTheme,
        darkTheme: WindowsTheme.darkTheme,
        routerConfig: _router,
      ),
    );
  }
}