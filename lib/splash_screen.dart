import 'dart:async';
import 'package:flutter/material.dart';
import 'package:task_management_application/modules/Login/presentation/views/user_role_login.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Navigate to Login Screen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserLoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Responsive Layout
  double _getResponsiveSize(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < 600) return 150; // mobile
    if (width < 1024) return 200; // tablet
    return 250; // desktop
  }

  @override
  Widget build(BuildContext context) {
    double imageSize = _getResponsiveSize(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: ScaleTransition(
            scale: _animation,
            child: Image.asset(
              'assets/logo.png', // 👈 Replace with your image path
              width: imageSize,
              height: imageSize,
            ),
          ),
        ),
      ),
    );
  }
}
