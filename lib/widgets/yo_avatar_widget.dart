import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import '../theme/app_theme.dart';
import 'avatar_3d_widget.dart';

class YoAvatarWidget extends StatefulWidget {
  final String gender;
  final double size;
  final double bodyComposition;
  final bool isScanning;
  final bool mealAdded;
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

  bool _useFallback = true;
  bool _riveReady = false;

  NumberInput?  _bodyComposition;

  BooleanInput? _isScanning;

  BooleanInput? _calorieStreakPositive;

  TriggerInput? _mealAdded;

  @override
  void initState() {
    super.initState();

    _checkAsset();
  }

  Future<void> _checkAsset() async {
    try {
      await rootBundle.load(_assetPath);

      if (mounted) setState(() { _useFallback = false; _riveReady = true; });
    } catch (_) {

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

    final sm = state.controller.stateMachine;

    _bodyComposition       = sm.number('bodyComposition');

    _isScanning            = sm.boolean('isScanning');

    _calorieStreakPositive = sm.boolean('calorieStreakPositive');

    _mealAdded             = sm.trigger('mealAdded');

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

                if (mounted) setState(() => _useFallback = true);
              },
              builder: (context, state) {
                if (state is RiveLoaded) {
                  return RiveWidget(
                    controller: state.controller,
                    fit: Fit.contain,
                  );
                }

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

  Future<void> onMealAdded() async {
    _mealAdded = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 100));
    _mealAdded = false;
    notifyListeners();
  }
}
