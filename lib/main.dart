import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const YOTRACKEZApp());
}

class YOTRACKEZApp extends StatelessWidget {
  const YOTRACKEZApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOTRACKEZ',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
