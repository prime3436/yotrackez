import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays short gamified sound-effect stingers for key app events.
///
/// This service only *plays* audio — it does not generate it. Drop your
/// own royalty-free .mp3 files into assets/sounds/ using the filenames
/// below (see README note in that folder / the PROFILE_ANIMATIONS doc).
///
/// Suggested vibe for each (search terms for royalty-free SFX libraries
/// like freesound.org, Pixabay Audio, or Zapsplat — avoid copyrighted
/// franchise audio):
///   power_up.mp3    -> "8-bit power up chime", "energy charge whoosh"
///   meal_logged.mp3 -> "positive ui confirm", "collect coin bling"
///   level_up.mp3    -> "arcade level up fanfare", "achievement unlock"
///   scan_beep.mp3   -> "sci-fi scanner beep loop"
class SoundService {
  static SoundService? _instance;
  static SoundService get instance {
    _instance ??= SoundService._();
    return _instance!;
  }
  SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;

  bool get enabled => _enabled;
  void setEnabled(bool value) => _enabled = value;

  Future<void> _play(String assetFile) async {
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$assetFile'));
    } catch (e) {
      // Missing/invalid asset shouldn't ever crash the app — sound is
      // purely decorative feedback.
      debugPrint('[SoundService] Could not play $assetFile: $e');
    }
  }

  /// A quick, punchy stinger when a meal is successfully logged.
  Future<void> playMealLogged() => _play('meal_logged.mp3');

  /// An energetic "power up" cue — used when the avatar's daily mood
  /// state improves (e.g. moving toward "Fit"/"Very Fit").
  Future<void> playPowerUp() => _play('power_up.mp3');

  /// A bigger fanfare for a meaningful milestone (e.g. BMI category
  /// improves, streak milestone, goal hit).
  Future<void> playLevelUp() => _play('level_up.mp3');

  /// Short beep usable during scanning/analysis loops.
  Future<void> playScanBeep() => _play('scan_beep.mp3');

  void dispose() {
    _player.dispose();
  }
}
