import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🚀 StudyToDo демо версия для Windows запущена!');
  runApp(StudyToDoDemoApp());
}

class StudyToDoDemoApp extends StatelessWidget {
  StudyToDoDemoApp({super.key});

  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DemoMainScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'StudyToDo - Windows Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF26C6DA),
          brightness: Brightness.light,
          primary: const Color(0xFF26C6DA),
          secondary: const Color(0xFF9C27B0),
          tertiary: const Color(0xFF00BCD4),
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
    );
  }
}

class DemoMainScreen extends StatefulWidget {
  const DemoMainScreen({super.key});

  @override
  State<DemoMainScreen> createState() => _DemoMainScreenState();
}

class _DemoMainScreenState extends State<DemoMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DemoTasksScreen(),
    const DemoSubjectsScreen(),
    const DemoAnalyticsScreen(),
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

class DemoTasksScreen extends StatelessWidget {
  const DemoTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои задачи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getSubjectColor(index),
                child: Text(
                  _getSubjectAbbr(index),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(_getTaskTitle(index)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(_getTaskDescription(index)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getTaskDeadline(index),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(index),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getPriorityText(index),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Задача выполнена! 🎉'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Демо режим'),
              content: const Text(
                'Это демонстрационная версия StudyToDo для Windows.\n\n'
                'В полной версии вы можете:\n'
                '• Создавать и редактировать задачи\n'
                '• Управлять предметами\n'
                '• Синхронизировать с облаком\n'
                '• Использовать AI помощника',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Понятно'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getSubjectColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    return colors[index % colors.length];
  }

  String _getSubjectAbbr(int index) {
    final abbrs = ['М', 'Ф', 'Х', 'И', 'А'];
    return abbrs[index % abbrs.length];
  }

  String _getTaskTitle(int index) {
    final titles = [
      'Решить задачи по алгебре',
      'Подготовить доклад по физике',
      'Выучить химические формулы',
      'Написать эссе по истории',
      'Подготовиться к контрольной',
    ];
    return titles[index % titles.length];
  }

  String _getTaskDescription(int index) {
    final descriptions = [
      'Глава 5, упражнения 1-15',
      'Тема: Квантовая механика',
      'Органические соединения',
      'Великая Отечественная война',
      'Повторить все пройденные темы',
    ];
    return descriptions[index % descriptions.length];
  }

  String _getTaskDeadline(int index) {
    final deadlines = [
      'Завтра 14:00',
      'Понедельник 10:00',
      'Среда 12:00',
      'Пятница 15:00',
      'Следующая неделя',
    ];
    return deadlines[index % deadlines.length];
  }

  Color _getPriorityColor(int index) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.green,
      Colors.blue,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }

  String _getPriorityText(int index) {
    final priorities = ['Высокий', 'Средний', 'Низкий', 'Высокий', 'Средний'];
    return priorities[index % priorities.length];
  }
}

class DemoSubjectsScreen extends StatelessWidget {
  const DemoSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Предметы'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildSubjectCard('Математика', Colors.blue, 12, 8),
          _buildSubjectCard('Физика', Colors.green, 8, 6),
          _buildSubjectCard('Химия', Colors.orange, 6, 4),
          _buildSubjectCard('История', Colors.purple, 10, 7),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('В полной версии можно добавлять предметы'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSubjectCard(String name, Color color, int total, int completed) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 24,
              child: Text(
                name[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('$completed из $total'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: completed / total,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
      ),
    );
  }
}

class DemoAnalyticsScreen extends StatelessWidget {
  const DemoAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Статистика',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow('Всего задач', '36'),
                    _buildStatRow('Выполнено', '25'),
                    _buildStatRow('В работе', '8'),
                    _buildStatRow('Просрочено', '3'),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: 25 / 36,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF26C6DA),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Прогресс: 69%',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Достижения',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAchievement(
                      '🎯',
                      'Первая задача',
                      'Выполнили первую задачу',
                    ),
                    _buildAchievement(
                      '🔥',
                      'Продуктивная неделя',
                      'Выполнили 10 задач за неделю',
                    ),
                    _buildAchievement(
                      '⭐',
                      'Отличник',
                      'Выполнили 25 задач',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'О демо версии',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Это демонстрационная версия StudyToDo для Windows. '
                      'Приложение успешно запущено и показывает основной интерфейс.\n\n'
                      'В полной версии доступны:\n'
                      '• Реальная работа с задачами и предметами\n'
                      '• Синхронизация с Firebase\n'
                      '• AI помощник от Gemini\n'
                      '• Уведомления и напоминания\n'
                      '• Подробная аналитика',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('StudyToDo Windows'),
                            content: const Text(
                              '🚀 Приложение успешно оптимизировано и запущено на Windows!\n\n'
                              'Особенности:\n'
                              '• Material Design 3\n'
                              '• Адаптивный интерфейс\n'
                              '• Современная архитектура BLoC\n'
                              '• Готовность к производству',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Отлично!'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.info),
                      label: const Text('Подробнее'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievement(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}