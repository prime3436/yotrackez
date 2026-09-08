import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'models/user_settings.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/meal_history_screen.dart';
import 'services/step_counter_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Required by rive 0.14.x — initialises the native renderer
  await RiveNative.init();
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
      home: const SplashScreen(),
    );
  }
}

/// Main shell with bottom navigation (Home & History) without the 3D avatar figure.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize services
    UserSettings.instance.load();
    StepCounterService.instance.start();
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    MealHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(color: AppTheme.primary.withValues(alpha: 0.15), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textSecondary,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_rounded),
              activeIcon: Icon(Icons.qr_code_scanner_rounded),
              label: 'Scan & AI',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timeline_rounded),
              activeIcon: Icon(Icons.timeline_rounded),
              label: 'History & Diary',
            ),
          ],
        ),
      ),
    );
  }
}
