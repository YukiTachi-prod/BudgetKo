import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification/notification_service.dart';
import 'database/budget_database.dart';
import 'providers/ledger_provider.dart';
import 'theme/app_theme.dart';
import 'screens/budget_screen.dart';
import 'providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().initialize();
  final budgetDb = BudgetDatabase();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        Provider<BudgetDatabase>.value(value: budgetDb),
        ChangeNotifierProvider(create: (_) => LedgerProvider(budgetDb)),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const BulsaKoApp(),
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

class BulsaKoApp extends StatelessWidget {
  const BulsaKoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    return MaterialApp(
      title: 'BulsaKo',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const NoScrollbarBehavior(),
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.light(
        settings.themeColor != null ? Color(settings.themeColor!) : null,
      ),
      darkTheme: AppTheme.dark(
        settings.themeColor != null ? Color(settings.themeColor!) : null,
      ),
      home: const BudgetScreen(),
    );
  }
}
