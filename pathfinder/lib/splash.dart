import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate some work (e.g., loading data)
    Future.delayed(const Duration(seconds: 3), () {
      // Navigate to the login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get the current theme

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Apply background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Replace with your app logo or branding
            Icon(Icons.app_registration, size: 100, color: theme.colorScheme.primary), // Apply icon color
            const SizedBox(height: 20),
            Text(
              "My App",
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24), // Apply text style
            ),
          ],
        ),
      ),
    );
  }
}