import 'package:flutter/material.dart';
import 'package:tasker/screens/dashboard_screen.dart';
import 'package:tasker/screens/settings_screen.dart';
import 'package:tasker/screens/task_edit_screen.dart';
import 'package:tasker/screens/heatmap_screen.dart';
import 'package:tasker/screens/budget_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const _labels = ['Tasks', 'Settings'];
  static const _icons = [Icons.description_outlined, Icons.settings_outlined];
  static const _selectedIcons = [
    Icons.description_rounded,
    Icons.settings_rounded,
  ];

  // IndexedStack preserves scroll/state on tab switch
  static const _screens = [DashboardScreen(), SettingsScreen()];

  void _onTab(int index) => setState(() => _selectedIndex = index);

  bool get _showNewButton => _selectedIndex < 1;

  void _openNewTask() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TaskEditScreen()),
    );
  }

  bool _isHeatmapOpen = false;

  void _openHeatmap() {
    if (_isHeatmapOpen) return;
    _isHeatmapOpen = true;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, _, _) => const HeatmapScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _isHeatmapOpen = false;
      });
    });
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale < 0.8) {
      _openHeatmap();
    }
  }

  void _openBudget() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BudgetScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleUpdate: _handleScaleUpdate,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return constraints.maxWidth >= 720
              ? _buildDesktop(context)
              : _buildMobile(context);
        },
      ),
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
            leading: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  IconButton(
                    icon: const Icon(Icons.account_balance_wallet_rounded, size: 26, color: Colors.white),
                    onPressed: _openBudget,
                    tooltip: 'Budget Calculator',
                  ),
                  const SizedBox(height: 16),
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
                  onOpenHeatmap: _openHeatmap,
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
        leading: IconButton(
          icon: Icon(
            Icons.account_balance_wallet_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: _openBudget,
          tooltip: 'Budget Calculator',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: _openHeatmap,
            tooltip: 'Web: Open Heatmap (Squeeze)',
          ),
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
  final VoidCallback onOpenHeatmap;

  const _DesktopHeader({
    required this.title,
    required this.showNewButton,
    required this.onNewTask,
    required this.onOpenHeatmap,
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
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: onOpenHeatmap,
            tooltip: 'Web: Open Heatmap (Squeeze)',
          ),
          const SizedBox(width: 8),
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
