import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'blocs/subjects_bloc.dart';
import 'blocs/tasks_bloc.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'screens/home_screen.dart';
import 'screens/subjects_screen.dart';
import 'screens/analytics_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('StudyToDo - Windows режим (только SQLite)');

  await NotificationService().initialize();
  await DatabaseService().initialize();

  runApp(StudyTodoWindowsApp());
}

class StudyTodoWindowsApp extends StatelessWidget {
  StudyTodoWindowsApp({super.key});

  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WindowsMainNavigation(),
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
        title: 'StudyToDo - Windows',
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
        routerConfig: _router,
      ),
    );
  }
}

class WindowsMainNavigation extends StatefulWidget {
  const WindowsMainNavigation({Key? key}) : super(key: key);

  @override
  State<WindowsMainNavigation> createState() => _WindowsMainNavigationState();
}

class _WindowsMainNavigationState extends State<WindowsMainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SubjectsScreen(),
    const AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Предметы',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Аналитика',
          ),
        ],
      ),
    );
  }
}