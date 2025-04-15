import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seva Finance',
      theme: AppTheme.theme,
      home: const WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
