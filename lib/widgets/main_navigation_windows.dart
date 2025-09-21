import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc_windows.dart';
import '../screens/home_screen_windows.dart';
import '../screens/subjects_screen_windows.dart';
import '../screens/analytics_screen_windows.dart';
import '../theme/windows_theme.dart';

class MainNavigationWindows extends StatefulWidget {
  const MainNavigationWindows({Key? key}) : super(key: key);

  @override
  State<MainNavigationWindows> createState() => _MainNavigationWindowsState();
}

class _MainNavigationWindowsState extends State<MainNavigationWindows> {
  int _selectedIndex = 0;
  bool _isNavigationExpanded = true;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Главная',
      tooltip: 'Управление задачами',
    ),
    NavigationItem(
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder,
      label: 'Предметы',
      tooltip: 'Организация по предметам',
    ),
    NavigationItem(
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      label: 'Аналитика',
      tooltip: 'Статистика и достижения',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Windows-style Navigation Rail
          _buildNavigationRail(),

          // Вертикальный разделитель
          Container(
            width: 1,
            color: Theme.of(context).colorScheme.outline,
          ),

          // Основной контент
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isNavigationExpanded ? 250 : 72,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Заголовок приложения
          _buildAppHeader(),

          // Навигационные элементы
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                return _buildNavigationTile(index);
              },
            ),
          ),

          // Нижняя секция с настройками
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildAppHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Иконка приложения
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.school,
              color: Colors.white,
              size: 20,
            ),
          ),

          if (_isNavigationExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'StudyToDo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Windows',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Кнопка сворачивания
          IconButton(
            onPressed: () {
              setState(() {
                _isNavigationExpanded = !_isNavigationExpanded;
              });
            },
            icon: Icon(
              _isNavigationExpanded ? Icons.menu_open : Icons.menu,
              size: 20,
            ),
            tooltip: _isNavigationExpanded ? 'Свернуть меню' : 'Развернуть меню',
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(int index) {
    final item = _navigationItems[index];
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(
              horizontal: _isNavigationExpanded ? 16 : 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isSelected
                  ? Border(
                      left: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  size: 20,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),

                if (_isNavigationExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: Theme.of(context).colorScheme.outline,
          ),

          // Профиль пользователя
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return _buildUserProfile(state.user);
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile(user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: _showUserMenu,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: EdgeInsets.all(_isNavigationExpanded ? 12 : 8),
            child: Row(
              children: [
                // Аватар
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? Text(
                          user.displayText.isNotEmpty
                              ? user.displayText[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : null,
                ),

                if (_isNavigationExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayText,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user.email != null)
                          Text(
                            user.email!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.more_vert,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return const HomeScreenWindows();
      case 1:
        return const SubjectsScreenWindows();
      case 2:
        return const AnalyticsScreenWindows();
      default:
        return const HomeScreenWindows();
    }
  }

  void _showUserMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        _isNavigationExpanded ? 200 : 60,
        MediaQuery.of(context).size.height - 200,
        50,
        100,
      ),
      items: <PopupMenuEntry>[
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.settings_outlined, size: 20),
              SizedBox(width: 12),
              Text('Настройки'),
            ],
          ),
          onTap: () {
            // TODO: Открыть настройки
          },
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.help_outline, size: 20),
              SizedBox(width: 12),
              Text('Справка'),
            ],
          ),
          onTap: () {
            _showAboutDialog();
          },
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 12),
              Text('Выйти'),
            ],
          ),
          onTap: () {
            context.read<AuthBloc>().add(AuthSignOut());
          },
        ),
      ],
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('О приложении'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('StudyToDo для Windows'),
            SizedBox(height: 8),
            Text('Версия: 1.0.0'),
            SizedBox(height: 8),
            Text('Современное приложение для управления учебными задачами с поддержкой Windows-нативного интерфейса.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String tooltip;

  NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.tooltip,
  });
}