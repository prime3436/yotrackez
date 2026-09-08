import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks how many consecutive days the user has logged at least one meal.
/// Called from MealDbService whenever a meal is saved.
class StreakService extends ChangeNotifier {
  static final StreakService instance = StreakService._();
  StreakService._();

  static const String _keyStreak = 'streak_count';
  static const String _keyLastLogged = 'streak_last_logged';
  static const String _keyLongest = 'streak_longest';

  int _streak = 0;
  int _longestStreak = 0;
  bool _loggedToday = false;
  bool _loaded = false;

  int get streak => _streak;
  int get longestStreak => _longestStreak;
  bool get loggedToday => _loggedToday;
  bool get loaded => _loaded;

  /// Fire this once at app startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _streak = prefs.getInt(_keyStreak) ?? 0;
    _longestStreak = prefs.getInt(_keyLongest) ?? 0;
    final lastLogged = prefs.getString(_keyLastLogged) ?? '';
    final today = _todayKey();
    final yesterday = _dayKey(DateTime.now().subtract(const Duration(days: 1)));

    if (lastLogged == today) {
      _loggedToday = true;
    } else if (lastLogged != yesterday && lastLogged.isNotEmpty) {
      // Streak broken — gap of more than 1 day
      _streak = 0;
      await prefs.setInt(_keyStreak, 0);
    }
    _loaded = true;
    notifyListeners();
  }

  /// Call this whenever a meal is successfully saved.
  Future<void> recordMeal() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final lastLogged = prefs.getString(_keyLastLogged) ?? '';

    if (lastLogged == today) return; // already counted today

    final yesterday = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    if (lastLogged == yesterday || lastLogged.isEmpty) {
      _streak++;
    } else {
      // Gap — restart streak
      _streak = 1;
    }

    _loggedToday = true;
    if (_streak > _longestStreak) _longestStreak = _streak;

    await prefs.setString(_keyLastLogged, today);
    await prefs.setInt(_keyStreak, _streak);
    await prefs.setInt(_keyLongest, _longestStreak);
    notifyListeners();
  }

  String _todayKey() => _dayKey(DateTime.now());
  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
