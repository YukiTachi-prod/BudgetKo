import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _startSplashScreen();
  }

  Future<void> _startSplashScreen() async {
    // Show splash for 1 second
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      await _controller.forward();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const DashboardScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFFFFDD0); // Creamy White

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 240,
                height: 240,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.brown[400]!),
                ),
              ),
              Image.asset(
                'lib/assets/tasko_logo_bg_remove.png',
                width: 180,
                height: 180,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
