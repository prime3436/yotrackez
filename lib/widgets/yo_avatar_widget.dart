import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import '../theme/app_theme.dart';
import 'avatar_3d_widget.dart'; // graceful fallback while .riv files are pending

// ════════════════════════════════════════════════════════════════════════════
// YoAvatarWidget — Rive 0.14.x Data Binding
//
// Loads  assets/rive/avatar_male.riv  or  avatar_female.riv.
// Drives the AvatarConfig state machine with:
//   bodyComposition   (NumberInput,  0–100)
//   isScanning        (BooleanInput, true while camera analyses a meal)
//   mealAdded         (TriggerInput, fires the Transform burst once)
//   calorieStreakPositive (BooleanInput)
//
// FALLBACK: if the .riv file is not yet in assets, Avatar3DWidget is shown
// so the app never displays a blank area.
// ════════════════════════════════════════════════════════════════════════════

class YoAvatarWidget extends StatefulWidget {
  final String gender;             // 'male' | 'female'
  final double size;
  final double bodyComposition;    // 0 = leanest, 100 = heaviest
  final bool isScanning;           // true → EagerWait layer
  final bool mealAdded;            // rising edge → Transform trigger
  final bool calorieStreakPositive;

  const YoAvatarWidget({
    super.key,
    this.gender = 'male',
    this.size = 300,
    this.bodyComposition = 50,
    this.isScanning = false,
    this.mealAdded = false,
    this.calorieStreakPositive = false,
  });

  @override
  State<YoAvatarWidget> createState() => _YoAvatarWidgetState();
}

class _YoAvatarWidgetState extends State<YoAvatarWidget> {
  // Start in fallback mode — only switch to Rive once asset check passes.
  // This eliminates the race where RiveWidgetBuilder throws before onFailed fires.
  bool _useFallback = true;
  bool _riveReady = false;

  // Inputs grabbed once the state machine loads
  // ignore: deprecated_member_use
  NumberInput?  _bodyComposition;
  // ignore: deprecated_member_use
  BooleanInput? _isScanning;
  // ignore: deprecated_member_use
  BooleanInput? _calorieStreakPositive;
  // ignore: deprecated_member_use
  TriggerInput? _mealAdded;

  @override
  void initState() {
    super.initState();
    // Pre-check the asset. Only enable Rive if file is present.
    _checkAsset();
  }

  Future<void> _checkAsset() async {
    try {
      await rootBundle.load(_assetPath);
      // Asset confirmed present — unlock Rive mode
      if (mounted) setState(() { _useFallback = false; _riveReady = true; });
    } catch (_) {
      // Asset missing — stay in fallback mode (already default)
    }
  }

  String get _assetPath => 'assets/rive/avatar_${widget.gender}.riv';

  String get _avatarState {
    if (widget.bodyComposition < 20) return 'very_fit';
    if (widget.bodyComposition < 40) return 'fit';
    if (widget.bodyComposition < 60) return 'normal';
    if (widget.bodyComposition < 80) return 'chubby';
    return 'overweight';
  }

  void _onLoaded(RiveLoaded state) {
    // ignore: deprecated_member_use
    final sm = state.controller.stateMachine;
    // ignore: deprecated_member_use
    _bodyComposition       = sm.number('bodyComposition');
    // ignore: deprecated_member_use
    _isScanning            = sm.boolean('isScanning');
    // ignore: deprecated_member_use
    _calorieStreakPositive = sm.boolean('calorieStreakPositive');
    // ignore: deprecated_member_use
    _mealAdded             = sm.trigger('mealAdded');

    // Push initial values
    _bodyComposition?.value       = widget.bodyComposition;
    _isScanning?.value            = widget.isScanning;
    _calorieStreakPositive?.value = widget.calorieStreakPositive;
  }

  @override
  void didUpdateWidget(YoAvatarWidget old) {
    super.didUpdateWidget(old);
    _bodyComposition?.value       = widget.bodyComposition;
    _isScanning?.value            = widget.isScanning;
    _calorieStreakPositive?.value = widget.calorieStreakPositive;

    // Fire trigger only on rising edge
    if (widget.mealAdded && !old.mealAdded) {
      _mealAdded?.fire();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ground glow (visible regardless of Rive/fallback)
          Positioned(
            bottom: 0,
            child: Container(
              width: widget.size * 0.6,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.size),
                boxShadow: AppTheme.glowShadow(AppTheme.primary),
                gradient: RadialGradient(colors: [
                  AppTheme.primary.withValues(alpha: 0.4),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          if (_useFallback || !_riveReady)
            // .riv not present — use the full animated CustomPainter avatar
            Avatar3DWidget(
              avatarState: _avatarState,
              gender: widget.gender,
              size: widget.size,
              autoSpin: widget.isScanning,
              bodyComposition: widget.bodyComposition,
              isScanning: widget.isScanning,
              mealAdded: widget.mealAdded,
              calorieStreakPositive: widget.calorieStreakPositive,
            )
          else
            RiveWidgetBuilder(
              fileLoader: FileLoader.fromAsset(
                _assetPath,
                riveFactory: Factory.flutter,
              ),
              stateMachineSelector: const StateMachineNamed('AvatarConfig'),
              onLoaded: _onLoaded,
              onFailed: (error, _) {
                // Fallback if something still goes wrong at runtime
                if (mounted) setState(() => _useFallback = true);
              },
              builder: (context, state) {
                if (state is RiveLoaded) {
                  return RiveWidget(
                    controller: state.controller,
                    fit: Fit.contain,
                  );
                }
                // Loading spinner while the .riv streams in
                return SizedBox(
                  width: widget.size * 0.3,
                  height: widget.size * 0.3,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary.withValues(alpha: 0.6),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// YoAvatarController — app-wide ChangeNotifier
// ════════════════════════════════════════════════════════════════════════════

class YoAvatarController extends ChangeNotifier {
  double _bodyComposition       = 50;
  bool   _isScanning            = false;
  bool   _mealAdded             = false;
  bool   _calorieStreakPositive = false;
  String _gender                = 'male';

  double get bodyComposition       => _bodyComposition;
  bool   get isScanning            => _isScanning;
  bool   get mealAdded             => _mealAdded;
  bool   get calorieStreakPositive => _calorieStreakPositive;
  String get gender                => _gender;

  void setGender(String g)  { _gender = g; notifyListeners(); }
  void setScanState(bool v) { _isScanning = v; notifyListeners(); }
  void setStreak(bool v)    { _calorieStreakPositive = v; notifyListeners(); }

  void setBodyComposition(double v) {
    _bodyComposition = v.clamp(0, 100);
    notifyListeners();
  }

  /// Call once a meal is logged — fires the Transform trigger.
  Future<void> onMealAdded() async {
    _mealAdded = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 100));
    _mealAdded = false;
    notifyListeners();
  }
}
