import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification/notification_service.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
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
      builder: (context, child) {
        if (kIsWeb) {
          return Container(
            color: const Color(0xFF1E1E1E), // Dark aesthetic background
            child: Center(
              child: Container(
                width: 393, // Vivo Y35 approximate logical width
                height: 876, // Vivo Y35 approximate logical height
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: child!,
                ),
              ),
            ),
          );
        }
        return child!;
      },
      home: const MainScreen(),
    );
  }
}
