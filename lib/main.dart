import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification/notification_service.dart';
import 'screens/main_screen.dart';
import 'database/budget_database.dart';
import 'providers/ledger_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().initialize();
  final budgetDb = BudgetDatabase();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        Provider<BudgetDatabase>.value(value: budgetDb),
        ChangeNotifierProvider(create: (_) => LedgerProvider(budgetDb)),
      ],
      child: const TaskerApp(),
    ),
  );
}

class NoScrollbarBehavior extends MaterialScrollBehavior {
  const NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class TaskerApp extends StatelessWidget {
  const TaskerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    return MaterialApp(
      title: 'TASKo',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const NoScrollbarBehavior(),
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const MainScreen(),
    );
  }
}
