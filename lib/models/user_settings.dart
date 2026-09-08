import 'package:shared_preferences/shared_preferences.dart';

/// User settings & profile: identity, body stats, fitness goal,
/// calorie/step targets, gender (for avatar), avatar state.
class UserSettings {
  static const String _calorieKey = 'daily_calorie_limit';
  static const String _stepGoalKey = 'step_goal';
  static const String _genderKey = 'gender'; // 'male' or 'female'
  static const String _onboardedKey = 'onboarded';

  // ─── Profile fields ─────────────────────────────────────
  static const String _nameKey = 'profile_name';
  static const String _photoPathKey = 'profile_photo_path';
  static const String _ageKey = 'profile_age';
  static const String _heightCmKey = 'profile_height_cm';
  static const String _weightKgKey = 'profile_weight_kg';
  static const String _goalKey = 'profile_goal'; // 'lose' | 'maintain' | 'gain'

  static UserSettings? _instance;
  UserSettings._();
  static UserSettings get instance {
    _instance ??= UserSettings._();
    return _instance!;
  }

  int _calorieLimit = 2000;
  int _stepGoal = 10000;
  String _gender = 'male';
  bool _onboarded = false;
  String _name = '';

  String? _photoPath;
  int _age = 25;
  double _heightCm = 170;
  double _weightKg = 70;
  String _goal = 'maintain';

  int get calorieLimit => _calorieLimit;
  int get stepGoal => _stepGoal;
  String get gender => _gender;
  bool get onboarded => _onboarded;
  String get name => _name;

  String? get photoPath => _photoPath;
  int get age => _age;
  double get heightCm => _heightCm;
  double get weightKg => _weightKg;
  String get goal => _goal;

  /// Load settings from shared prefs.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _calorieLimit = prefs.getInt(_calorieKey) ?? 2000;
    _stepGoal = prefs.getInt(_stepGoalKey) ?? 10000;
    _gender = prefs.getString(_genderKey) ?? 'male';
    _onboarded = prefs.getBool(_onboardedKey) ?? false;
    _name = prefs.getString(_nameKey) ?? '';

    _photoPath = prefs.getString(_photoPathKey);
    _age = prefs.getInt(_ageKey) ?? 25;
    _heightCm = prefs.getDouble(_heightCmKey) ?? 170;
    _weightKg = prefs.getDouble(_weightKgKey) ?? 70;
    _goal = prefs.getString(_goalKey) ?? 'maintain';
  }

  Future<void> setCalorieLimit(int limit) async {
    _calorieLimit = limit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_calorieKey, limit);
  }

  Future<void> setStepGoal(int goal) async {
    _stepGoal = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stepGoalKey, goal);
  }

  Future<void> setGender(String gender) async {
    _gender = gender;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_genderKey, gender);
  }

  Future<void> setOnboarded(bool value) async {
    _onboarded = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardedKey, value);
  }

  // ─── Profile setters ──────────────────────────────────────────────────

  Future<void> setName(String value) async {
    _name = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, value);
  }

  Future<void> setPhotoPath(String? value) async {
    _photoPath = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_photoPathKey);
    } else {
      await prefs.setString(_photoPathKey, value);
    }
  }

  Future<void> setAge(int value) async {
    _age = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_ageKey, value);
  }

  Future<void> setHeightCm(double value) async {
    _heightCm = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_heightCmKey, value);
  }

  Future<void> setWeightKg(double value) async {
    _weightKg = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_weightKgKey, value);
  }

  /// goal: 'lose' | 'maintain' | 'gain'
  Future<void> setGoal(String value) async {
    _goal = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalKey, value);
  }

  /// Save every profile field in one shot (used by the Profile screen's Save button).
  Future<void> saveProfile({
    required String name,
    String? photoPath,
    required int age,
    required double heightCm,
    required double weightKg,
    required String goal,
    required String gender,
  }) async {
    await setName(name);
    await setPhotoPath(photoPath);
    await setAge(age);
    await setHeightCm(heightCm);
    await setWeightKg(weightKg);
    await setGoal(goal);
    await setGender(gender);
  }

  // ─── Derived health metrics ───────────────────────────────────────────

  /// Body Mass Index = kg / m^2
  double get bmi {
    final heightM = _heightCm / 100;
    if (heightM <= 0) return 0;
    return _weightKg / (heightM * heightM);
  }

  String get bmiCategory {
    final b = bmi;
    if (b <= 0) return 'Unknown';
    if (b < 18.5) return 'Underweight';
    if (b < 25) return 'Normal';
    if (b < 30) return 'Overweight';
    return 'Obese';
  }

  /// Basal Metabolic Rate via Mifflin-St Jeor equation.
  double get bmr {
    final base = 10 * _weightKg + 6.25 * _heightCm - 5 * _age;
    return _gender == 'female' ? base - 161 : base + 5;
  }

  /// Suggested daily calorie target based on BMR, a moderate activity
  /// multiplier, and the user's stated goal. This is a starting point —
  /// users can still override it manually via [setCalorieLimit].
  int get suggestedCalorieLimit {
    const activityMultiplier = 1.375; // light activity baseline
    double target = bmr * activityMultiplier;
    switch (_goal) {
      case 'lose':
        target -= 500; // ~0.5kg/week deficit
        break;
      case 'gain':
        target += 400; // lean surplus
        break;
      case 'maintain':
      default:
        break;
    }
    return target.clamp(1200, 4500).round();
  }

  /// Avatar state (5 levels based on net calories):
  /// net = calories eaten - calories burned (steps)
  /// Very Fit (< -500), Fit (-500..0), Normal (0..300), Chubby (300..700), Overweight (>700)
  String getAvatarState(double netCalories) {
    if (netCalories < -500) return 'very_fit';
    if (netCalories < 0) return 'fit';
    if (netCalories < 300) return 'normal';
    if (netCalories < 700) return 'chubby';
    return 'overweight';
  }

  String getAvatarEmoji(String state) {
    switch (state) {
      case 'very_fit': return '💪';
      case 'fit': return '😊';
      case 'normal': return '😐';
      case 'chubby': return '😮‍💨';
      case 'overweight': return '😴';
      default: return '😐';
    }
  }

  String getAvatarLabel(String state) {
    switch (state) {
      case 'very_fit': return 'Very Fit';
      case 'fit': return 'Fit';
      case 'normal': return 'Normal';
      case 'chubby': return 'Chubby';
      case 'overweight': return 'Overweight';
      default: return 'Normal';
    }
  }

  String get goalLabel {
    switch (_goal) {
      case 'lose': return 'Lose Weight';
      case 'gain': return 'Gain Weight';
      case 'maintain':
      default: return 'Maintain Weight';
    }
  }

  // ─── BMI-based base avatar appearance ─────────────────────────────────
  //
  // This is the character's *baseline* look, driven by BMI (changes slowly,
  // as your stats change). It's distinct from [getAvatarState], which drives
  // the *daily* mood/glow feedback based on today's net calories. Both reuse
  // the same 5 avatar art assets, so no new art is required.

  /// Maps BMI to one of the 5 existing avatar body states.
  String get bmiBodyState {
    final b = bmi;
    if (b <= 0) return 'normal';
    if (b < 18.5) return 'fit';
    if (b < 25) return 'normal';
    if (b < 30) return 'chubby';
    return 'overweight';
  }

  String get bmiBodyLabel => getAvatarLabel(bmiBodyState);
}
