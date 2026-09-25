import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterService extends ChangeNotifier {
  static final WaterService instance = WaterService._();
  WaterService._();

  static const int _goal = 8;
  static const String _keyGlasses = 'water_glasses';
  static const String _keyDate = 'water_date';

  int _glasses = 0;
  bool _loaded = false;

  int get glasses => _glasses;
  int get goal => _goal;
  double get progress => (_glasses / _goal).clamp(0.0, 1.0);
  bool get goalReached => _glasses >= _goal;
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final storedDate = prefs.getString(_keyDate) ?? '';
    if (storedDate != today) {

      await prefs.setInt(_keyGlasses, 0);
      await prefs.setString(_keyDate, today);
    }
    _glasses = prefs.getInt(_keyGlasses) ?? 0;
    _loaded = true;
    notifyListeners();
  }

  Future<void> addGlass() async {
    if (_glasses >= _goal + 4) return;
    _glasses++;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyGlasses, _glasses);
    await prefs.setString(_keyDate, _todayKey());
  }

  Future<void> removeGlass() async {
    if (_glasses <= 0) return;
    _glasses--;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyGlasses, _glasses);
  }

  Future<void> reset() async {
    _glasses = 0;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyGlasses, 0);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
