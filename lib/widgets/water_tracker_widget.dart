import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/water_service.dart';
import '../theme/app_theme.dart';

class WaterTrackerWidget extends StatefulWidget {
  const WaterTrackerWidget({super.key});

  @override
  State<WaterTrackerWidget> createState() => _WaterTrackerWidgetState();
}

class _WaterTrackerWidgetState extends State<WaterTrackerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleCtrl;
  bool _justAdded = false;

  @override
  void initState() {
    super.initState();
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    final svc = WaterService.instance;
    if (!svc.loaded) {
      svc.load().then((_) {
        if (mounted) setState(() {});
      });
    }
    svc.addListener(_onServiceChange);
  }

  void _onServiceChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WaterService.instance.removeListener(_onServiceChange);
    _rippleCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    HapticFeedback.lightImpact();
    await WaterService.instance.addGlass();
    setState(() => _justAdded = true);
    _rippleCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _justAdded = false);
  }

  Future<void> _remove() async {
    HapticFeedback.mediumImpact();
    await WaterService.instance.removeGlass();
  }

  @override
  Widget build(BuildContext context) {
    final svc = WaterService.instance;
    final glasses = svc.glasses;
    final goal = svc.goal;
    final progress = svc.progress;
    final done = svc.goalReached;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D1B3E),
            done
                ? AppTheme.accent.withValues(alpha: 0.15)
                : const Color(0xFF111827),
          ],
        ),
        border: Border.all(
          color: done
              ? AppTheme.accent.withValues(alpha: 0.6)
              : AppTheme.accent.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: done ? AppTheme.glowShadow(AppTheme.accent) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  done ? Icons.water_drop : Icons.water_drop_outlined,
                  color: AppTheme.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hydration',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    done ? '🎉 Goal reached!' : '$glasses of $goal glasses',
                    style: TextStyle(
                      color: done
                          ? AppTheme.accent
                          : Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              GestureDetector(
                onTap: _add,
                onLongPress: _remove,
                child: AnimatedBuilder(
                  animation: _rippleCtrl,
                  builder: (context, child) {
                    final scale = _justAdded
                        ? (1.0 +
                            0.25 *
                                Curves.elasticOut.transform(_rippleCtrl.value))
                        : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accent.withValues(alpha: 0.2),
                      border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(Icons.add, color: AppTheme.accent, size: 20),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  color: AppTheme.accent.withValues(alpha: 0.1),
                ),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  widthFactor: progress,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accent.withValues(alpha: 0.6),
                          AppTheme.accent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(goal, (i) {
              final filled = i < glasses;
              return GestureDetector(
                onTap: i == glasses ? _add : null,
                onLongPress: filled ? _remove : null,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200 + i * 30),
                  curve: Curves.bounceOut,
                  margin: const EdgeInsets.only(right: 5),
                  child: Icon(
                    filled ? Icons.water_drop : Icons.water_drop_outlined,
                    color: filled
                        ? AppTheme.accent.withValues(alpha: 0.7 + 0.3 * (i / goal))
                        : Colors.white.withValues(alpha: 0.15),
                    size: 20,
                  ),
                ),
              );
            }),

          ),

          if (glasses > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Long-press to remove · Tap + to add',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
