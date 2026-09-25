import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_3d_widget.dart';
import '../widgets/image_source_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;

  String? _photoPath;
  String _gender = 'male';
  String _goal = 'maintain';
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final settings = UserSettings.instance;
    _nameCtrl = TextEditingController(text: settings.name);
    _ageCtrl = TextEditingController(text: settings.age.toString());
    _heightCtrl = TextEditingController(text: settings.heightCm.toStringAsFixed(0));
    _weightCtrl = TextEditingController(text: settings.weightKg.toStringAsFixed(0));
    _photoPath = settings.photoPath;
    _gender = settings.gender;
    _goal = settings.goal;

    for (final c in [_nameCtrl, _ageCtrl, _heightCtrl, _weightCtrl]) {
      c.addListener(() => setState(() => _dirty = true));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  double get _heightValue => double.tryParse(_heightCtrl.text) ?? 170;
  double get _weightValue => double.tryParse(_weightCtrl.text) ?? 70;
  int get _ageValue => int.tryParse(_ageCtrl.text) ?? 25;

  double get _bmi {
    final m = _heightValue / 100;
    if (m <= 0) return 0;
    return _weightValue / (m * m);
  }

  String get _bmiCategory {
    final b = _bmi;
    if (b <= 0) return 'Unknown';
    if (b < 18.5) return 'Underweight';
    if (b < 25) return 'Normal';
    if (b < 30) return 'Overweight';
    return 'Obese';
  }

  Color get _bmiColor {
    final b = _bmi;
    if (b <= 0) return AppTheme.textSecondary;
    if (b < 18.5) return AppTheme.carbsBlue;
    if (b < 25) return AppTheme.fiberGreen;
    if (b < 30) return AppTheme.accent;
    return AppTheme.error;
  }

  String get _bmiBodyState {
    final b = _bmi;
    if (b <= 0) return 'normal';
    if (b < 18.5) return 'fit';
    if (b < 25) return 'normal';
    if (b < 30) return 'chubby';
    return 'overweight';
  }

  int get _suggestedCalories {
    final base = 10 * _weightValue + 6.25 * _heightValue - 5 * _ageValue;
    final bmr = _gender == 'female' ? base - 161 : base + 5;
    double target = bmr * 1.375;
    switch (_goal) {
      case 'lose':
        target -= 500;
        break;
      case 'gain':
        target += 400;
        break;
    }
    return target.clamp(1200, 4500).round();
  }

  Future<void> _pickPhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ImageSourceSheet(
        onCamera: () => _handlePickImage(ImageSource.camera),
        onGallery: () => _handlePickImage(ImageSource.gallery),
      ),
    );
  }

  Future<void> _handlePickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, maxWidth: 800, imageQuality: 85);
      if (image != null && mounted) {
        setState(() {
          _photoPath = image.path;
          _dirty = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await UserSettings.instance.saveProfile(
        name: _nameCtrl.text.trim(),
        photoPath: _photoPath,
        age: _ageValue,
        heightCm: _heightValue,
        weightKg: _weightValue,
        goal: _goal,
        gender: _gender,
      );
      if (mounted) {
        setState(() {
          _saving = false;
          _dirty = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved'), backgroundColor: AppTheme.fiberGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _applySuggestedCalories() async {
    await UserSettings.instance.setCalorieLimit(_suggestedCalories);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Daily calorie goal set to $_suggestedCalories kcal'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      _buildPhotoPicker(),
                      const SizedBox(height: 28),
                      _buildTextField(
                        controller: _nameCtrl,
                        label: 'Name',
                        icon: Icons.badge_outlined,
                        keyboardType: TextInputType.name,
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _ageCtrl,
                              label: 'Age',
                              icon: Icons.cake_outlined,
                              keyboardType: TextInputType.number,
                              suffix: 'yrs',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _buildGenderPicker()),
                        ],
                      ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _heightCtrl,
                              label: 'Height',
                              icon: Icons.height_rounded,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              suffix: 'cm',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _weightCtrl,
                              label: 'Weight',
                              icon: Icons.monitor_weight_outlined,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              suffix: 'kg',
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 160.ms, duration: 400.ms),
                      const SizedBox(height: 24),
                      Text('Fitness Goal', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      _buildGoalPicker().animate().fadeIn(delay: 220.ms, duration: 400.ms),
                      const SizedBox(height: 24),
                      _buildStatsCard().animate().fadeIn(delay: 280.ms, duration: 400.ms),
                      const SizedBox(height: 24),
                      Text('Character Appearance', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Your avatar\'s base look updates automatically as your BMI changes.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      _buildAvatarPreview().animate().fadeIn(delay: 340.ms, duration: 400.ms),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Text('My Profile', style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickPhoto,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppTheme.primary.withValues(alpha: 0.3), AppTheme.surface],
                ),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.6), width: 3),
                boxShadow: AppTheme.glowShadow(AppTheme.primary),
              ),
              child: ClipOval(
                child: _photoPath != null
                    ? Image.file(
                        File(_photoPath!),
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.person_rounded,
                          size: 56,
                          color: AppTheme.textSecondary,
                        ),
                      )
                    : const Icon(Icons.person_rounded, size: 56, color: AppTheme.textSecondary),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                  border: Border.all(color: AppTheme.background, width: 3),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppTheme.background),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.85, 0.85));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        filled: true,
        fillColor: AppTheme.card.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildGenderPicker() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(child: _genderChip('male', Icons.male_rounded)),
          Expanded(child: _genderChip('female', Icons.female_rounded)),
        ],
      ),
    );
  }

  Widget _genderChip(String value, IconData icon) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() {
        _gender = value;
        _dirty = true;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5)) : null,
        ),
        child: Icon(icon, size: 20, color: selected ? AppTheme.primary : AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildGoalPicker() {
    final goals = [
      ('lose', 'Lose', Icons.trending_down_rounded, AppTheme.carbsBlue),
      ('maintain', 'Maintain', Icons.trending_flat_rounded, AppTheme.fiberGreen),
      ('gain', 'Gain', Icons.trending_up_rounded, AppTheme.accent),
    ];
    return Row(
      children: goals.map((g) {
        final (value, label, icon, color) = g;
        final selected = _goal == value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: value != 'gain' ? 10 : 0),
            child: GestureDetector(
              onTap: () => setState(() {
                _goal = value;
                _dirty = true;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: selected ? color.withValues(alpha: 0.12) : AppTheme.card.withValues(alpha: 0.4),
                  borderRadius: AppTheme.cardRadius,
                  border: Border.all(
                    color: selected ? color.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.06),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon, size: 22, color: selected ? color : AppTheme.textSecondary),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? color : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_outlined, size: 18, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text('Your Stats', style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BMI', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      _bmi.toStringAsFixed(1),
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _bmiColor),
                    ),
                    Text(_bmiCategory, style: TextStyle(fontSize: 12, color: _bmiColor)),
                  ],
                ),
              ),
              Container(width: 1, height: 44, color: Colors.white.withValues(alpha: 0.08)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Suggested Goal', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      '$_suggestedCalories',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.primary),
                    ),
                    const Text('kcal / day', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _applySuggestedCalories,
              icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppTheme.primary),
              label: const Text('Apply to Calorie Goal', style: TextStyle(color: AppTheme.primary)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: AppTheme.glassCard(),
      child: Avatar3DWidget(
        avatarState: _bmiBodyState,
        gender: _gender,
        size: 160,
        autoSpin: true,
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_dirty && !_saving) ? _save : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.25),
        ),
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.background),
              )
            : Text(_dirty ? 'Save Profile' : 'Saved', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
