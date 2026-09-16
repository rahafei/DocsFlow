import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

class DocFlow extends StatelessWidget {
  const DocFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DocsFlow',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}