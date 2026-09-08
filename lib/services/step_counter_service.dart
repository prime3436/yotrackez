import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads step count from phone's pedometer sensor and calculates calories burned.
/// Formula: calories burned ≈ steps × 0.04 (about 40 cal per 1000 steps).
class StepCounterService {
  static StepCounterService? _instance;
  static StepCounterService get instance {
    _instance ??= StepCounterService._();
    return _instance!;
  }

  StepCounterService._();

  static const String _midnightStepsKey = 'midnight_steps';
  static const String _lastResetDateKey = 'last_reset_date';

  StreamSubscription<StepCount>? _stepSub;
  int _totalStepsSinceLastBoot = 0;
  int _midnightSteps = 0; // Steps at midnight (to calculate daily)
  int _todaySteps = 0;

  final ValueNotifier<int> stepsNotifier = ValueNotifier(0);
  final ValueNotifier<double> caloriesBurnedNotifier = ValueNotifier(0.0);

  int get todaySteps => _todaySteps;
  double get caloriesBurned => _todaySteps * 0.04;

  /// Start listening to the pedometer.
  Future<void> start() async {
    await _loadMidnightSteps();

    if (kIsWeb) {
      debugPrint('[Steps] Pedometer not supported on Web environment.');
      return;
    }

    try {
      _stepSub = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepError,
      );
      debugPrint('[Steps] Pedometer started.');
    } catch (e) {
      debugPrint('[Steps] Pedometer not available: $e');
    }
  }

  void _onStepCount(StepCount event) {
    _totalStepsSinceLastBoot = event.steps;
    _checkDayReset();

    _todaySteps = _totalStepsSinceLastBoot - _midnightSteps;
    if (_todaySteps < 0) _todaySteps = 0;

    stepsNotifier.value = _todaySteps;
    caloriesBurnedNotifier.value = caloriesBurned;
  }

  void _onStepError(dynamic error) {
    debugPrint('[Steps] Pedometer error: $error');
  }

  /// Check if the day has changed — if so, reset midnight baseline.
  Future<void> _checkDayReset() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetDate = prefs.getString(_lastResetDateKey) ?? '';
    final today = _todayDateStr();

    if (lastResetDate != today) {
      // Day changed — reset midnight baseline to current total
      _midnightSteps = _totalStepsSinceLastBoot;
      await prefs.setInt(_midnightStepsKey, _midnightSteps);
      await prefs.setString(_lastResetDateKey, today);
      debugPrint('[Steps] New day detected — midnight baseline reset to $_midnightSteps');
    }
  }

  Future<void> _loadMidnightSteps() async {
    final prefs = await SharedPreferences.getInstance();
    _midnightSteps = prefs.getInt(_midnightStepsKey) ?? 0;
    final lastDate = prefs.getString(_lastResetDateKey) ?? '';
    if (lastDate != _todayDateStr()) {
      // Will be reset on first step event
      debugPrint('[Steps] Midnight steps loaded: $_midnightSteps (pending day-reset)');
    }
  }

  String _todayDateStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _stepSub?.cancel();
    stepsNotifier.dispose();
    caloriesBurnedNotifier.dispose();
  }
}
