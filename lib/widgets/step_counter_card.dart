import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/step_counter_service.dart';
import '../theme/app_theme.dart';

class StepCounterCard extends StatelessWidget {
  final int stepGoal;

  const StepCounterCard({super.key, this.stepGoal = 10000});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: StepCounterService.instance.stepsNotifier,
      builder: (context, steps, _) {
        final progress = (steps / stepGoal).clamp(0.0, 1.0);
        final burned = steps * 0.04;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              CircularPercentIndicator(
                radius: 40,
                lineWidth: 6,
                percent: progress,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_walk_rounded, size: 20, color: AppTheme.primary),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                progressColor: _getProgressColor(progress),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                circularStrokeCap: CircularStrokeCap.round,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$steps steps',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Goal: $stepGoal • ${burned.toStringAsFixed(0)} cal burned',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.local_fire_department_rounded,
                color: AppTheme.calorieOrange,
                size: 28,
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return AppTheme.fiberGreen;
    if (progress >= 0.6) return AppTheme.primary;
    if (progress >= 0.3) return AppTheme.accent;
    return AppTheme.calorieOrange;
  }
}
