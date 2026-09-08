import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user_settings.dart';
import '../theme/app_theme.dart';
import '../main.dart';

/// First-launch multi-step onboarding.
///
/// Steps:
///   0 — Welcome
///   1 — Name
///   2 — Gender
///   3 — Age / Height / Weight
///   4 — Fitness goal
///   5 — Calorie target (auto-suggested, user can tweak)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _page = PageController();
  int _step = 0;
  bool _saving = false;

  // Form values
  final _nameCtrl = TextEditingController();
  String _gender = 'male';
  int _age = 25;
  double _heightCm = 170;
  double _weightKg = 70;
  String _goal = 'maintain';
  late int _calorieTarget; // filled at step 4 from suggestion

  @override
  void initState() {
    super.initState();
    _calorieTarget = 2000;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _page.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      _goTo(1);
    } else if (_step == 1) {
      if (_nameCtrl.text.trim().isEmpty) return;
      _goTo(2);
    } else if (_step == 2) {
      _goTo(3);
    } else if (_step == 3) {
      _goTo(4);
    } else if (_step == 4) {
      // Compute suggestion before showing step 5
      _computeCalorieSuggestion();
      _goTo(5);
    } else {
      _finish();
    }
  }

  void _computeCalorieSuggestion() {
    // Mifflin-St Jeor BMR
    final base = 10 * _weightKg + 6.25 * _heightCm - 5 * _age;
    final bmr = _gender == 'female' ? base - 161 : base + 5;
    double target = bmr * 1.375; // light activity
    if (_goal == 'lose') target -= 500;
    if (_goal == 'gain') target += 400;
    setState(() => _calorieTarget = target.clamp(1200, 4500).round());
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _page.animateToPage(step,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final s = UserSettings.instance;
    await s.saveProfile(
      name: _nameCtrl.text.trim(),
      age: _age,
      heightCm: _heightCm,
      weightKg: _weightKg,
      goal: _goal,
      gender: _gender,
    );
    await s.setCalorieLimit(_calorieTarget);
    await s.setOnboarded(true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, a, b) => const MainShell(),
        transitionsBuilder: (_, animation, b, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Progress bar ──
              _StepProgressBar(step: _step, total: 6),

              // ── Pages ──
              Expanded(
                child: PageView(
                  controller: _page,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _WelcomePage(onNext: _next),
                    _NamePage(controller: _nameCtrl, onNext: _next),
                    _GenderPage(
                      selected: _gender,
                      onChanged: (g) => setState(() => _gender = g),
                      onNext: _next,
                    ),
                    _BodyStatsPage(
                      age: _age,
                      heightCm: _heightCm,
                      weightKg: _weightKg,
                      onAgeChanged: (v) => setState(() => _age = v),
                      onHeightChanged: (v) => setState(() => _heightCm = v),
                      onWeightChanged: (v) => setState(() => _weightKg = v),
                      onNext: _next,
                    ),
                    _GoalPage(
                      selected: _goal,
                      onChanged: (g) => setState(() => _goal = g),
                      onNext: _next,
                    ),
                    _CaloriePage(
                      calories: _calorieTarget,
                      onChanged: (v) => setState(() => _calorieTarget = v),
                      onFinish: _saving ? null : _finish,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Step 0 — Welcome
// ═══════════════════════════════════════════════════════════

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(alpha: 0.12),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4), width: 2),
              boxShadow: AppTheme.glowShadow(AppTheme.primary),
            ),
            child: const Center(
              child: Text('🥗', style: TextStyle(fontSize: 52)),
            ),
          ).animate().scale(begin: const Offset(0.5, 0.5), curve: Curves.easeOutBack),

          const SizedBox(height: 36),

          Text('Welcome to YOTRACKEZ',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800, letterSpacing: 0.5,
                  )).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 16),

          Text(
            'Let\'s set up your profile so we can personalize your calorie goals and health recommendations.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary, height: 1.6,
                ),
          ).animate().fadeIn(delay: 350.ms),

          const SizedBox(height: 52),

          _NextButton(label: 'GET STARTED', onTap: onNext),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Step 1 — Name
// ═══════════════════════════════════════════════════════════

class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onNext;
  const _NamePage({required this.controller, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepLabel('Step 1 of 5'),
          const SizedBox(height: 12),
          Text('What\'s your name?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  )).animate().fadeIn(),
          const SizedBox(height: 8),
          Text('We\'ll use it to personalise your experience.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  )).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 36),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'e.g. Alex',
              hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5)),
              filled: true,
              fillColor: AppTheme.surfaceLight.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: AppTheme.buttonRadius,
                borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppTheme.buttonRadius,
                borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppTheme.buttonRadius,
                borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
            onSubmitted: (_) => onNext(),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 40),
          _NextButton(label: 'CONTINUE', onTap: onNext),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Step 2 — Gender
// ═══════════════════════════════════════════════════════════

class _GenderPage extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  const _GenderPage({required this.selected, required this.onChanged, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepLabel('Step 2 of 5'),
          const SizedBox(height: 12),
          Text('Biological sex',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))
              .animate().fadeIn(),
          const SizedBox(height: 8),
          Text('Used for accurate BMR & calorie calculations.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary))
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(child: _GenderCard(emoji: '♂️', label: 'Male', value: 'male', selected: selected, onTap: onChanged)),
              const SizedBox(width: 16),
              Expanded(child: _GenderCard(emoji: '♀️', label: 'Female', value: 'female', selected: selected, onTap: onChanged)),
            ],
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 48),
          _NextButton(label: 'CONTINUE', onTap: onNext),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String emoji, label, value, selected;
  final ValueChanged<String> onTap;
  const _GenderCard({required this.emoji, required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surfaceLight.withValues(alpha: 0.2),
          borderRadius: AppTheme.cardRadius,
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? AppTheme.glowShadow(AppTheme.primary.withValues(alpha: 0.3)) : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: FontWeight.w700, fontSize: 15,
            )),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Step 3 — Age / Height / Weight
// ═══════════════════════════════════════════════════════════

class _BodyStatsPage extends StatelessWidget {
  final int age;
  final double heightCm, weightKg;
  final ValueChanged<int> onAgeChanged;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<double> onWeightChanged;
  final VoidCallback onNext;

  const _BodyStatsPage({
    required this.age, required this.heightCm, required this.weightKg,
    required this.onAgeChanged, required this.onHeightChanged,
    required this.onWeightChanged, required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _StepLabel('Step 3 of 5'),
          const SizedBox(height: 12),
          Text('Your stats', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)).animate().fadeIn(),
          const SizedBox(height: 8),
          Text('Needed to calculate your personal calorie target.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 32),

          _SliderStat(
            label: 'Age', value: age.toDouble(), unit: 'yrs',
            min: 15, max: 80, divisions: 65,
            onChanged: (v) => onAgeChanged(v.round()),
          ),
          const SizedBox(height: 24),
          _SliderStat(
            label: 'Height', value: heightCm, unit: 'cm',
            min: 140, max: 220, divisions: 80,
            onChanged: onHeightChanged,
          ),
          const SizedBox(height: 24),
          _SliderStat(
            label: 'Weight', value: weightKg, unit: 'kg',
            min: 30, max: 180, divisions: 150,
            onChanged: onWeightChanged,
          ),

          const SizedBox(height: 48),
          _NextButton(label: 'CONTINUE', onTap: onNext),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SliderStat extends StatelessWidget {
  final String label, unit;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderStat({
    required this.label, required this.value, required this.unit,
    required this.min, required this.max, required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withValues(alpha: 0.2),
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              RichText(text: TextSpan(children: [
                TextSpan(text: value.toStringAsFixed(0),
                    style: TextStyle(color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.w800)),
                TextSpan(text: ' $unit',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ])),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min, max: max, divisions: divisions,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.primary.withValues(alpha: 0.15),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Step 4 — Fitness Goal
// ═══════════════════════════════════════════════════════════

class _GoalPage extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  const _GoalPage({required this.selected, required this.onChanged, required this.onNext});

  static const _goals = [
    ('lose',     '🔥', 'Lose Weight',     'Calorie deficit of ~500 kcal/day'),
    ('maintain', '⚖️', 'Maintain Weight', 'Balanced intake matching your burn'),
    ('gain',     '💪', 'Gain Muscle',     'Calorie surplus of ~400 kcal/day'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepLabel('Step 4 of 5'),
          const SizedBox(height: 12),
          Text('Your goal', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)).animate().fadeIn(),
          const SizedBox(height: 8),
          Text('We\'ll set your daily calorie target based on this.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 32),
          ..._goals.asMap().entries.map((e) {
            final (value, emoji, label, desc) = e.value;
            final isSelected = selected == value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onChanged(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary.withValues(alpha: 0.12) : AppTheme.surfaceLight.withValues(alpha: 0.2),
                    borderRadius: AppTheme.cardRadius,
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.08),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: TextStyle(
                              color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                              fontWeight: FontWeight.w700, fontSize: 15,
                            )),
                            Text(desc, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 22),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (100 + e.key * 60).ms),
            );
          }),
          const SizedBox(height: 32),
          _NextButton(label: 'CALCULATE MY TARGET', onTap: onNext),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Step 5 — Calorie Target
// ═══════════════════════════════════════════════════════════

class _CaloriePage extends StatelessWidget {
  final int calories;
  final ValueChanged<int> onChanged;
  final VoidCallback? onFinish;
  const _CaloriePage({required this.calories, required this.onChanged, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepLabel('Step 5 of 5'),
          const SizedBox(height: 20),
          Text('Your daily calorie target',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))
              .animate().fadeIn(),
          const SizedBox(height: 8),
          Text('Calculated from your BMR and goal. You can fine-tune it.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary))
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 40),

          // Big calorie display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: AppTheme.calorieOrange.withValues(alpha: 0.08),
              borderRadius: AppTheme.cardRadius,
              border: Border.all(color: AppTheme.calorieOrange.withValues(alpha: 0.3), width: 1.5),
              boxShadow: AppTheme.glowShadow(AppTheme.calorieOrange.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(Icons.local_fire_department_rounded, color: AppTheme.calorieOrange, size: 36),
                const SizedBox(height: 8),
                Text('$calories', style: TextStyle(
                  color: AppTheme.calorieOrange, fontSize: 56,
                  fontWeight: FontWeight.w900, letterSpacing: -1,
                )),
                Text('kcal / day', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              ],
            ),
          ).animate().scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack, delay: 150.ms),

          const SizedBox(height: 28),

          // Tweak slider
          Slider(
            value: calories.toDouble().clamp(1200, 4000),
            min: 1200, max: 4000, divisions: 280,
            activeColor: AppTheme.calorieOrange,
            inactiveColor: AppTheme.calorieOrange.withValues(alpha: 0.15),
            onChanged: (v) => onChanged(v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1200', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              Text('4000', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),

          const SizedBox(height: 40),
          _NextButton(
            label: onFinish == null ? 'SAVING...' : 'FINISH SETUP',
            onTap: onFinish,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Shared helpers
// ═══════════════════════════════════════════════════════════

class _StepProgressBar extends StatelessWidget {
  final int step, total;
  const _StepProgressBar({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: List.generate(total, (i) {
          final filled = i < step;
          final current = i == step;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: filled
                    ? AppTheme.primary
                    : current
                        ? AppTheme.primary.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.1),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String text;
  const _StepLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Text(text, style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
    );
  }
}

class _NextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _NextButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.black,
          elevation: 8,
          shadowColor: AppTheme.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        child: Text(label),
      ),
    );
  }
}
