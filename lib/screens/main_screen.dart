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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DesktopHeader(
            title: 'Tasks',
            onNewTask: _openNewTask,
            onOpenHeatmap: _openHeatmap,
            onOpenBudget: _openBudget,
            onOpenSettings: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const Expanded(child: DashboardScreen()),
        ],
      ),
    );
  }

  // ── Mobile layout ──────────────────────────────────────────────
  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        centerTitle: true,
        leadingWidth: 140, // accommodate 3 icons
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.account_balance_wallet_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _openBudget,
              tooltip: 'Wallet',
            ),
            IconButton(
              icon: const Icon(Icons.grid_view_rounded),
              onPressed: _openHeatmap,
              tooltip: 'Web: Open Heatmap (Squeeze)',
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: _openNewTask,
              tooltip: 'New task',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: const DashboardScreen(),
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onNewTask;
  final VoidCallback onOpenHeatmap;
  final VoidCallback onOpenBudget;
  final VoidCallback onOpenSettings;

  const _DesktopHeader({
    required this.title,
    required this.onNewTask,
    required this.onOpenHeatmap,
    required this.onOpenBudget,
    required this.onOpenSettings,
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
          IconButton(
            icon: Icon(
              Icons.account_balance_wallet_rounded,
              color: theme.colorScheme.primary,
            ),
            onPressed: onOpenBudget,
            tooltip: 'Wallet',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: onOpenHeatmap,
            tooltip: 'Web: Open Heatmap (Squeeze)',
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('New task'),
            onPressed: onNewTask,
          ),
          const Spacer(),
          Text(title, style: theme.textTheme.titleLarge),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: onOpenSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }
}
