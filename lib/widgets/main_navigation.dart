import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../screens/home_screen.dart';
import '../screens/subjects_screen.dart';
import '../screens/analytics_screen.dart';
import '../blocs/tasks_bloc.dart';
import '../blocs/subjects_bloc.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SubjectsScreen(),
    const AnalyticsScreen(),
  ];

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.task_outlined),
      selectedIcon: Icon(Icons.task),
      label: 'Задачи',
    ),
    const NavigationDestination(
      icon: Icon(Icons.subject_outlined),
      selectedIcon: Icon(Icons.subject),
      label: 'Предметы',
    ),
    const NavigationDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics),
      label: 'Аналитика',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Обновляем данные при переходе на экран
    switch (index) {
      case 0:
        context.read<TasksBloc>().add(RefreshTasks());
        break;
      case 1:
        context.read<SubjectsBloc>().add(RefreshSubjects());
        break;
      case 2:
        context.read<TasksBloc>().add(RefreshTasks());
        context.read<SubjectsBloc>().add(RefreshSubjects());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onItemTapped,
        destinations: _destinations,
        animationDuration: const Duration(milliseconds: 300),
        backgroundColor: Theme.of(context).brightness == Brightness.light 
            ? const Color(0xFFF8FDFF) 
            : const Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        indicatorColor: Theme.of(context).brightness == Brightness.light 
            ? const Color(0xFF26C6DA) 
            : const Color(0xFF4DD0E1),
        shadowColor: Theme.of(context).shadowColor,
        elevation: 8,
      ),
    );
  }
}