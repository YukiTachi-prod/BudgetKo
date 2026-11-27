import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'database/budget_database.dart';
import 'providers/ledger_provider.dart';
import 'theme/app_theme.dart';
import 'screens/budget_screen.dart';
import 'providers/notification_provider.dart';

import 'providers/group_wallet_provider.dart';
import 'providers/temp_group_pool_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final budgetDb = BudgetDatabase();
  final settingsProvider = SettingsProvider();
  final ledgerProvider = LedgerProvider(budgetDb);
  final notificationProvider = NotificationProvider();
  final groupWalletProvider = GroupWalletProvider();
  final tempGroupPoolProvider = TempGroupPoolProvider();

  // Preload all essentials concurrently from the beginning
  await Future.wait([
    NotificationService().initialize(),
    settingsProvider.preload(),
    ledgerProvider.preload(),
    notificationProvider.preload(),
    groupWalletProvider.preload(),
    tempGroupPoolProvider.preload(),
  ]);

  notificationProvider.checkLedgerWarnings(ledgerProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        Provider<BudgetDatabase>.value(value: budgetDb),
        ChangeNotifierProvider.value(value: ledgerProvider),
        ChangeNotifierProvider.value(value: notificationProvider),
        ChangeNotifierProvider.value(value: groupWalletProvider),
        ChangeNotifierProvider.value(value: tempGroupPoolProvider),
      ],
      child: const BudgetKoApp(),
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

class BudgetKoApp extends StatelessWidget {
  const BudgetKoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    return MaterialApp(
      title: 'BudgetKo',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const NoScrollbarBehavior(),
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.light(
        settings.themeColor != null ? Color(settings.themeColor!) : null,
      ),
      darkTheme: AppTheme.dark(
        settings.themeColor != null ? Color(settings.themeColor!) : null,
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(settings.textScaleFactor)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const BudgetScreen(),
    );
  }
}
