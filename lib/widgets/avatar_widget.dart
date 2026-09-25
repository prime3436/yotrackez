import 'package:flutter/material.dart';
import '../models/user_settings.dart';
import '../theme/app_theme.dart';

class AvatarWidget extends StatelessWidget {
  final String avatarState;
  final String gender;
  final double size;

  const AvatarWidget({
    super.key,
    required this.avatarState,
    required this.gender,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    final scale = _getScale();
    final moodColor = _getMoodColor();
    final emoji = UserSettings.instance.getAvatarEmoji(avatarState);
    final label = UserSettings.instance.getAvatarLabel(avatarState);
    final imagePath = _getAvatarImagePath();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          width: size * scale,
          height: size * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                moodColor.withValues(alpha: 0.35),
                AppTheme.surface,
              ],
            ),
            border: Border.all(
              color: moodColor.withValues(alpha: 0.8),
              width: 3.5,
            ),
            boxShadow: [
              BoxShadow(
                color: moodColor.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 6,
              ),
            ],
          ),
          child: ClipOval(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Image.asset(
                imagePath,
                key: ValueKey(imagePath),
                fit: BoxFit.cover,
                width: size * scale,
                height: size * scale,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      gender == 'male' ? _getMaleEmoji() : _getFemaleEmoji(),
                      style: TextStyle(fontSize: size * scale * 0.4),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: moodColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: moodColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: moodColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getAvatarImagePath() {
    final prefix = gender == 'female' ? 'avatar_female' : 'avatar_male';
    switch (avatarState) {
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

  double _getScale() {
    switch (avatarState) {
      case 'very_fit': return 0.85;
      case 'fit': return 0.95;
      case 'normal': return 1.0;
      case 'chubby': return 1.1;
      case 'overweight': return 1.2;
      default: return 1.0;
    }
  }

  Color _getMoodColor() {
    switch (avatarState) {
      case 'very_fit': return AppTheme.fiberGreen;
      case 'fit': return AppTheme.primary;
      case 'normal': return AppTheme.accent;
      case 'chubby': return AppTheme.calorieOrange;
      case 'overweight': return AppTheme.error;
      default: return AppTheme.primary;
    }
  }

  String _getMaleEmoji() {
    switch (avatarState) {
      case 'very_fit': return '🏋️‍♂️';
      case 'fit': return '🏃‍♂️';
      case 'normal': return '🧍‍♂️';
      case 'chubby': return '😮‍💨';
      case 'overweight': return '😴';
      default: return '🧍‍♂️';
    }
  }

  String _getFemaleEmoji() {
    switch (avatarState) {
      case 'very_fit': return '🏋️‍♀️';
      case 'fit': return '🏃‍♀️';
      case 'normal': return '🧍‍♀️';
      case 'chubby': return '😮‍💨';
      case 'overweight': return '😴';
      default: return '🧍‍♀️';
    }
  }
}
