import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user_settings.dart';
import '../theme/app_theme.dart';

/// Editable settings / profile screen.
///
/// Lets the user update every field set during onboarding:
///   – Name, gender
///   – Age, height, weight
///   – Fitness goal
///   – Daily calorie limit (manual override or re-calculate)
///   – Step goal
///
/// Changes are saved immediately on each field tap / slider release.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _s = UserSettings.instance;
  late final TextEditingController _nameCtrl;

  late String _gender;
  late int _age;
  late double _heightCm;
  late double _weightKg;
  late String _goal;
  late int _calorieTarget;
  late int _stepGoal;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: _s.name);
    _gender = _s.gender;
    _age = _s.age;
    _heightCm = _s.heightCm;
    _weightKg = _s.weightKg;
    _goal = _s.goal;
    _calorieTarget = _s.calorieLimit;
    _stepGoal = _s.stepGoal;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _s.saveProfile(
      name: _nameCtrl.text.trim(),
      age: _age,
      heightCm: _heightCm,
      weightKg: _weightKg,
      goal: _goal,
      gender: _gender,
    );
    await _s.setCalorieLimit(_calorieTarget);
    await _s.setStepGoal(_stepGoal);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 18),
          SizedBox(width: 10),
          Text('Settings saved', style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: AppTheme.surfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _recalcCalories() {
    final base = 10 * _weightKg + 6.25 * _heightCm - 5 * _age;
    final bmr = _gender == 'female' ? base - 161 : base + 5;
    double target = bmr * 1.375;
    if (_goal == 'lose') target -= 500;
    if (_goal == 'gain') target += 400;
    setState(() => _calorieTarget = target.clamp(1200, 4500).round());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Text('Profile & Settings',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    TextButton(
                      onPressed: _save,
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                      child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ),
                  ],
                ),
              ),

              // ── Scrollable body ──
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  children: [

                    // ── BMI / Health card ──
                    _buildBmiCard(context),
                    const SizedBox(height: 24),

                    // ── Identity ──
                    _SectionHeader('Identity'),
                    const SizedBox(height: 12),
                    _buildNameField(context),
                    const SizedBox(height: 12),
                    _buildGenderRow(),
                    const SizedBox(height: 24),

                    // ── Body stats ──
                    _SectionHeader('Body Stats'),
                    const SizedBox(height: 12),
                    _buildSliderCard('Age', _age.toDouble(), 'yrs', 15, 80, 65,
                        (v) => setState(() => _age = v.round())),
                    const SizedBox(height: 12),
                    _buildSliderCard('Height', _heightCm, 'cm', 140, 220, 80,
                        (v) => setState(() => _heightCm = v)),
                    const SizedBox(height: 12),
                    _buildSliderCard('Weight', _weightKg, 'kg', 30, 180, 150,
                        (v) => setState(() => _weightKg = v)),
                    const SizedBox(height: 24),

                    // ── Goal ──
                    _SectionHeader('Fitness Goal'),
                    const SizedBox(height: 12),
                    _buildGoalSelector(),
                    const SizedBox(height: 24),

                    // ── Calorie target ──
                    _SectionHeader('Daily Calorie Target'),
                    const SizedBox(height: 12),
                    _buildCalorieCard(context),
                    const SizedBox(height: 24),

                    // ── Step goal ──
                    _SectionHeader('Daily Step Goal'),
                    const SizedBox(height: 12),
                    _buildSliderCard('Steps', _stepGoal.toDouble(), 'steps', 2000, 20000, 180,
                        (v) => setState(() => _stepGoal = v.round())),
                    const SizedBox(height: 32),

                    // ── Save button ──
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_rounded, size: 20),
                        label: const Text('SAVE SETTINGS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                          elevation: 8,
                          shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBmiCard(BuildContext context) {
    // Use current slider values (not yet saved to UserSettings)
    final heightM = _heightCm / 100;
    final bmi = heightM > 0 ? _weightKg / (heightM * heightM) : 0.0;
    final String bmiLabel;
    final Color bmiColor;
    if (bmi < 18.5) { bmiLabel = 'Underweight'; bmiColor = AppTheme.carbsBlue; }
    else if (bmi < 25) { bmiLabel = 'Normal'; bmiColor = AppTheme.fiberGreen; }
    else if (bmi < 30) { bmiLabel = 'Overweight'; bmiColor = AppTheme.calorieOrange; }
    else { bmiLabel = 'Obese'; bmiColor = AppTheme.proteinRed; }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bmiColor.withValues(alpha: 0.12), bmiColor.withValues(alpha: 0.04)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: bmiColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BMI', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              Text(bmi.toStringAsFixed(1), style: TextStyle(color: bmiColor, fontSize: 36, fontWeight: FontWeight.w900)),
              Text(bmiLabel, style: TextStyle(color: bmiColor, fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Suggested calories', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(height: 4),
              Text('${_s.suggestedCalorieLimit} kcal', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _recalcCalories,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: AppTheme.chipRadius,
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text('Re-calculate', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildNameField(BuildContext context) {
    return TextField(
      controller: _nameCtrl,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: 'Name',
        labelStyle: TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(Icons.person_rounded, color: AppTheme.primary.withValues(alpha: 0.7)),
        filled: true,
        fillColor: AppTheme.surfaceLight.withValues(alpha: 0.2),
        border: OutlineInputBorder(borderRadius: AppTheme.buttonRadius, borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: AppTheme.buttonRadius, borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        focusedBorder: OutlineInputBorder(borderRadius: AppTheme.buttonRadius, borderSide: BorderSide(color: AppTheme.primary, width: 1.5)),
      ),
    );
  }

  Widget _buildGenderRow() {
    return Row(
      children: ['male', 'female'].map((g) {
        final isSelected = _gender == g;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _gender = g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: g == 'male' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary.withValues(alpha: 0.12) : AppTheme.surfaceLight.withValues(alpha: 0.2),
                borderRadius: AppTheme.cardRadius,
                border: Border.all(color: isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.08)),
              ),
              child: Center(
                child: Text('${g == 'male' ? '♂️' : '♀️'}  ${g[0].toUpperCase()}${g.substring(1)}',
                    style: TextStyle(
                      color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliderCard(String label, double value, String unit, double min, double max, int divs, ValueChanged<double> onChanged) {
    final displayVal = unit == 'steps'
        ? '${value.round()}'
        : value.toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withValues(alpha: 0.2),
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
            RichText(text: TextSpan(children: [
              TextSpan(text: displayVal, style: TextStyle(color: AppTheme.primary, fontSize: 20, fontWeight: FontWeight.w800)),
              TextSpan(text: ' $unit', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ])),
          ]),
          Slider(value: value.clamp(min, max), min: min, max: max, divisions: divs,
              activeColor: AppTheme.primary,
              inactiveColor: AppTheme.primary.withValues(alpha: 0.12),
              onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildGoalSelector() {
    const goals = [
      ('lose', '🔥', 'Lose Weight'),
      ('maintain', '⚖️', 'Maintain'),
      ('gain', '💪', 'Gain Muscle'),
    ];
    return Row(
      children: goals.map((g) {
        final (value, emoji, label) = g;
        final isSelected = _goal == value;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _goal = value); _recalcCalories(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: value != 'gain' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary.withValues(alpha: 0.12) : AppTheme.surfaceLight.withValues(alpha: 0.2),
                borderRadius: AppTheme.cardRadius,
                border: Border.all(color: isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 6),
                Text(label, style: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                  fontSize: 11, fontWeight: FontWeight.w700,
                )),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalorieCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.calorieOrange.withValues(alpha: 0.06),
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppTheme.calorieOrange.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(Icons.local_fire_department_rounded, color: AppTheme.calorieOrange, size: 22),
              const SizedBox(width: 8),
              Text('Daily Target', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
            ]),
            Text('$_calorieTarget kcal', style: TextStyle(color: AppTheme.calorieOrange, fontSize: 22, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 4),
          Slider(
            value: _calorieTarget.toDouble().clamp(1200, 4000),
            min: 1200, max: 4000, divisions: 280,
            activeColor: AppTheme.calorieOrange,
            inactiveColor: AppTheme.calorieOrange.withValues(alpha: 0.12),
            onChanged: (v) => setState(() => _calorieTarget = v.round()),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('1200', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            Text('4000', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ]),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontSize: 11,
            ));
  }
}
