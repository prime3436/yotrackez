import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user_settings.dart';
import '../services/meal_db_service.dart';
import '../services/step_counter_service.dart';
import '../theme/app_theme.dart';

/// Floating Mini Avatar Dock displayed persistently at the bottom of the app.
/// Shows animated walking/idle avatar, live avatar state, net calories, and steps.
class PersistentAvatarDock extends StatefulWidget {
  final VoidCallback onTap;

  const PersistentAvatarDock({
    super.key,
    required this.onTap,
  });

  @override
  State<PersistentAvatarDock> createState() => _PersistentAvatarDockState();
}

class _PersistentAvatarDockState extends State<PersistentAvatarDock>
    with SingleTickerProviderStateMixin {
  late AnimationController _walkController;
  late Animation<double> _bounceAnimation;

  double _caloriesEaten = 0;
  double _caloriesBurned = 0;
  int _todaySteps = 0;
  String _avatarState = 'normal';

  @override
  void initState() {
    super.initState();
    // Continuous idle/walking animation loop
    _walkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _walkController, curve: Curves.easeInOut),
    );

    _loadData();
    MealDbService.instance.mealsChangedNotifier.addListener(_loadData);
    StepCounterService.instance.stepsNotifier.addListener(_loadData);
    StepCounterService.instance.caloriesBurnedNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    MealDbService.instance.mealsChangedNotifier.removeListener(_loadData);
    StepCounterService.instance.stepsNotifier.removeListener(_loadData);
    StepCounterService.instance.caloriesBurnedNotifier.removeListener(_loadData);
    _walkController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final totals = await MealDbService.instance.getDayTotals(DateTime.now());
    final steps = StepCounterService.instance.todaySteps;
    final burned = StepCounterService.instance.caloriesBurned;
    final eaten = totals['calories'] ?? 0;
    final net = eaten - burned;

    if (mounted) {
      setState(() {
        _caloriesEaten = eaten;
        _caloriesBurned = burned;
        _todaySteps = steps;
        _avatarState = UserSettings.instance.getAvatarState(net);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gender = UserSettings.instance.gender;
    final emoji = _getAvatarEmoji(gender);
    final label = UserSettings.instance.getAvatarLabel(_avatarState);
    final moodColor = _getMoodColor();
    final net = _caloriesEaten - _caloriesBurned;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: moodColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: moodColor.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Animated Bobbing Mini Avatar
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _bounceAnimation.value),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: moodColor.withValues(alpha: 0.15),
                      border: Border.all(color: moodColor.withValues(alpha: 0.8), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: moodColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        _getAvatarImagePath(gender),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Avatar State Name & Net Calories
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: moodColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label.toUpperCase(),
                            style: TextStyle(
                              color: moodColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _todaySteps > 0 ? '🚶 Walking' : '🧍 Idle',
                            style: TextStyle(
                              color: AppTheme.textSecondary.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Net: ${net >= 0 ? '+' : ''}${net.toStringAsFixed(0)} cal • $_todaySteps steps',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Open Avatar Indicator Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: moodColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'AVATAR',
                        style: TextStyle(
                          color: moodColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, color: moodColor, size: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }

  String _getAvatarEmoji(String gender) {
    if (gender == 'male') {
      switch (_avatarState) {
        case 'very_fit': return '🏋️‍♂️';
        case 'fit': return '🏃‍♂️';
        case 'normal': return '🧍‍♂️';
        case 'chubby': return '😮‍💨';
        case 'overweight': return '😴';
        default: return '🧍‍♂️';
      }
    } else {
      switch (_avatarState) {
        case 'very_fit': return '🏋️‍♀️';
        case 'fit': return '🏃‍♀️';
        case 'normal': return '🧍‍♀️';
        case 'chubby': return '😮‍💨';
        case 'overweight': return '😴';
        default: return '🧍‍♀️';
      }
    }
  }

  Color _getMoodColor() {
    switch (_avatarState) {
      case 'very_fit': return AppTheme.fiberGreen;
      case 'fit': return AppTheme.primary;
      case 'normal': return AppTheme.accent;
      case 'chubby': return AppTheme.calorieOrange;
      case 'overweight': return AppTheme.error;
      default: return AppTheme.primary;
    }
  }

  String _getAvatarImagePath(String gender) {
    final prefix = gender == 'female' ? 'avatar_female' : 'avatar_male';
    switch (_avatarState) {
      case 'very_fit':
        return 'assets/avatars/${prefix}_very_fit.png';
      case 'fit':
        return 'assets/avatars/${prefix}_fit.png';
      case 'normal':
        return 'assets/avatars/${prefix}_normal.png';
      case 'chubby':
        return 'assets/avatars/${prefix}_chubby.png';
      case 'overweight':
        return 'assets/avatars/${prefix}_overweight.png';
      default:
        return 'assets/avatars/${prefix}_normal.png';
    }
  }
}
