import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'models/user_settings.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_home_screen.dart';
import 'screens/scan_ai_screen.dart';
import 'screens/meal_history_screen.dart';
import 'services/step_counter_service.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';

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

/// Main 3-tab shell: Home | Scan & AI | History & Diary
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
    UserSettings.instance.load();
    StepCounterService.instance.start();
  }

  static const List<Widget> _screens = [
    DashboardHomeScreen(),
    ScanAiScreen(),
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
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryAction.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
                color: AppColors.primaryAction.withValues(alpha: 0.18), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primaryAction,
          unselectedItemColor: AppTheme.textSecondary,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.document_scanner_outlined),
              activeIcon: Icon(Icons.document_scanner_rounded),
              label: 'Scan & AI',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              activeIcon: Icon(Icons.history_rounded),
              label: 'Diary',
            ),
          ],
        ),
      ),
    );
  }
}
