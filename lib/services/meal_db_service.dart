import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/meal_entry.dart';
import 'streak_service.dart';

/// SQLite database service for persistent meal tracking history.
/// Includes fallback memory & SharedPreferences storage for web and desktop platforms.
class MealDbService {
  static MealDbService? _instance;
  static MealDbService get instance {
    _instance ??= MealDbService._();
    return _instance!;
  }

  MealDbService._() {
    _loadWebMeals();
  }

  static const String _webMealsPrefKey = 'yotrackez_web_meals';
  final ValueNotifier<int> mealsChangedNotifier = ValueNotifier(0);

  Database? _db;
  bool _useInMemory = kIsWeb;
  final List<MealEntry> _inMemoryMeals = [];

  Future<void> _loadWebMeals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_webMealsPrefKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        _inMemoryMeals.clear();
        _inMemoryMeals.addAll(list.map((m) => MealEntry.fromMap(m as Map<String, dynamic>)));
        mealsChangedNotifier.value++;
      }
    } catch (e) {
      debugPrint('[MealDB] Error loading web meals from SharedPreferences: $e');
    }
  }

  Future<void> _saveWebMeals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _inMemoryMeals.map((m) => m.toMap()).toList();
      await prefs.setString(_webMealsPrefKey, jsonEncode(list));
    } catch (e) {
      debugPrint('[MealDB] Error saving web meals to SharedPreferences: $e');
    }
  }

  Future<Database?> _getDatabase() async {
    if (_useInMemory) return null;
    if (_db != null) return _db;

    try {
      _db = await _initDatabase();
      return _db;
    } catch (e) {
      debugPrint('[MealDB] sqflite initialization failed: $e. Falling back to memory & SharedPreferences store.');
      _useInMemory = true;
      return null;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final dbFile = path.join(dbPath, 'yotrackez_meals.db');

    return openDatabase(
      dbFile,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE meals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            foodName TEXT NOT NULL,
            calories REAL NOT NULL,
            protein REAL NOT NULL,
            carbs REAL NOT NULL,
            fat REAL NOT NULL,
            fiber REAL NOT NULL,
            mealType TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            imagePath TEXT
          )
        ''');
        debugPrint('[MealDB] Created meals table.');
      },
    );
  }

  /// Insert a new meal entry.
  Future<int> insertMeal(MealEntry meal) async {
    final db = await _getDatabase();
    int assignedId;
    if (db == null) {
      assignedId = DateTime.now().millisecondsSinceEpoch;
      final entry = meal.copyWith(id: assignedId);
      _inMemoryMeals.add(entry);
      await _saveWebMeals();
      debugPrint('[MealDB] Inserted meal in memory/SharedPreferences: ${meal.foodName} (id=$assignedId)');
    } else {
      assignedId = await db.insert('meals', meal.toMap()..remove('id'));
      debugPrint('[MealDB] Inserted meal in sqflite: ${meal.foodName} (id=$assignedId)');
    }

    mealsChangedNotifier.value++;
    // Record meal for streak tracking (idempotent per day)
    StreakService.instance.recordMeal();
    return assignedId;
  }

  /// Get all meals for a specific day.
  Future<List<MealEntry>> getMealsForDay(DateTime date) async {
    final db = await _getDatabase();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    if (db == null) {
      return _inMemoryMeals.where((m) {
        final t = m.timestamp;
        return t.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) && t.isBefore(endOfDay);
      }).toList();
    }

    final maps = await db.query(
      'meals',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
      orderBy: 'timestamp ASC',
    );

    return maps.map((m) => MealEntry.fromMap(m)).toList();
  }

  /// Get daily totals (calories, protein, carbs, fat, fiber) for a specific day.
  Future<Map<String, double>> getDayTotals(DateTime date) async {
    final meals = await getMealsForDay(date);
    double cal = 0, pro = 0, carb = 0, fat = 0, fib = 0;
    for (final m in meals) {
      cal += m.calories;
      pro += m.protein;
      carb += m.carbs;
      fat += m.fat;
      fib += m.fiber;
    }
    return {
      'calories': cal,
      'protein': pro,
      'carbs': carb,
      'fat': fat,
      'fiber': fib,
    };
  }

  /// Get all meals (all time) ordered by newest first.
  Future<List<MealEntry>> getAllMeals() async {
    final db = await _getDatabase();
    if (db == null) {
      final list = List<MealEntry>.from(_inMemoryMeals);
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }

    final maps = await db.query('meals', orderBy: 'timestamp DESC');
    return maps.map((m) => MealEntry.fromMap(m)).toList();
  }

  /// Delete a meal entry by ID.
  Future<void> deleteMeal(int id) async {
    final db = await _getDatabase();
    if (db == null) {
      _inMemoryMeals.removeWhere((m) => m.id == id);
      await _saveWebMeals();
      debugPrint('[MealDB] Deleted memory meal id=$id');
    } else {
      await db.delete('meals', where: 'id = ?', whereArgs: [id]);
      debugPrint('[MealDB] Deleted meal id=$id');
    }

    mealsChangedNotifier.value++;
  }
}
