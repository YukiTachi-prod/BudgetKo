import 'package:flutter/material.dart';
import 'package:tasker/screens/dashboard_screen.dart';
import 'package:tasker/screens/routines_screen.dart';
import 'package:tasker/screens/settings_screen.dart';
import 'package:tasker/screens/task_edit_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const _labels = ['Tasks', 'Routines', 'Settings'];
  static const _icons = [
    Icons.description_outlined,
    Icons.loop_rounded,
    Icons.settings_outlined,
  ];
  static const _selectedIcons = [
    Icons.description_rounded,
    Icons.loop_rounded,
    Icons.settings_rounded,
  ];

  // IndexedStack preserves scroll/state on tab switch
  static const _screens = [
    DashboardScreen(),
    RoutinesScreen(),
    SettingsScreen(),
  ];

  void _onTab(int index) => setState(() => _selectedIndex = index);

  bool get _showNewButton => _selectedIndex < 2;

  void _openNewTask() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TaskEditScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return constraints.maxWidth >= 720
            ? _buildDesktop(context)
            : _buildMobile(context);
      },
    );
  }

  // ── Desktop layout ─────────────────────────────────────────────
  Widget _buildDesktop(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onTab,
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  SizedBox(height: 16),
                  Icon(Icons.task_alt_rounded, size: 26, color: Colors.white),
                  SizedBox(height: 4),
                  Text(
                    'TASKo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
            destinations: [
              for (int i = 0; i < _labels.length; i++)
                NavigationRailDestination(
                  icon: Icon(_icons[i]),
                  selectedIcon: Icon(_selectedIcons[i]),
                  label: Text(_labels[i]),
                ),
            ],
          ),

          Container(
            width: 1,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DesktopHeader(
                  title: _labels[_selectedIndex],
                  showNewButton: _showNewButton,
                  onNewTask: _openNewTask,
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile layout ──────────────────────────────────────────────
  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(_labels[_selectedIndex]),
          ],
        ),
        actions: [
          if (_showNewButton)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: _openNewTask,
              tooltip: 'New task',
            ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTab,
        items: [
          for (int i = 0; i < _labels.length; i++)
            BottomNavigationBarItem(
              icon: Icon(_icons[i]),
              activeIcon: Icon(_selectedIcons[i]),
              label: _labels[i],
            ),
        ],
      ),
    );
  }
}

// ── Desktop page header ────────────────────────────────────────────
class _DesktopHeader extends StatelessWidget {
  final String title;
  final bool showNewButton;
  final VoidCallback onNewTask;

  const _DesktopHeader({
    required this.title,
    required this.showNewButton,
    required this.onNewTask,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const Spacer(),
          if (showNewButton)
            FilledButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('New task'),
              onPressed: onNewTask,
            ),
        ],
      ),
    );
  }
}
