import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'blocs/subjects_bloc.dart';
import 'blocs/tasks_bloc.dart';
import 'services/notification_service.dart';
import 'widgets/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize();
  runApp(StudyTodoApp());
}

class StudyTodoApp extends StatelessWidget {
  StudyTodoApp({Key? key}) : super(key: key);
  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainNavigation(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => SubjectsBloc()..add(LoadSubjects())),
        BlocProvider(create: (context) => TasksBloc()..add(LoadTasks())),
      ],
      child: MaterialApp.router(
        title: 'StudyTodo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF26C6DA), // Бирюзовый
            brightness: Brightness.light,
            primary: const Color(0xFF26C6DA),
            secondary: const Color(0xFF9C27B0), // Фиолетовый
            tertiary: const Color(0xFF00BCD4), // Темно-бирюзовый
            surface: const Color(0xFFF8FDFF),
            surfaceContainerHighest: const Color(0xFFE0F2F1),
          ),
          textTheme: GoogleFonts.interTextTheme(),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFFFFFFFF),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF26C6DA),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF9C27B0),
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26C6DA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF26C6DA),
            brightness: Brightness.dark,
            primary: const Color(0xFF4DD0E1),
            secondary: const Color(0xFFBA68C8),
            tertiary: const Color(0xFF26C6DA),
            surface: const Color(0xFF121212),
            surfaceContainerHighest: const Color(0xFF1E1E1E),
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFF1E1E1E),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            foregroundColor: Color(0xFF4DD0E1),
            elevation: 0,
            centerTitle: true,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFFBA68C8),
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DD0E1),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        routerConfig: _router,
      ),
    );
  }
}