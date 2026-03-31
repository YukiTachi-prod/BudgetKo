import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

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

class TaskerApp extends StatelessWidget {
  const TaskerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'TASKo',
      debugShowCheckedModeBanner: false,
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFDD0), // Creamy white
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          surface: const Color(0xFFFFFDD0),
        ),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFFDF5E6)),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF303030), // Dark grey
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF303030),
          primary: Colors.blueGrey,
        ),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF212121)),
      ),
      home: const SplashScreen(),
    );
  }
}
