import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

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

      debugPrint('[SoundService] Could not play $assetFile: $e');
    }
  }

  Future<void> playMealLogged() => _play('meal_logged.mp3');

  Future<void> playPowerUp() => _play('power_up.mp3');

  Future<void> playLevelUp() => _play('level_up.mp3');

  Future<void> playScanBeep() => _play('scan_beep.mp3');

  void dispose() {
    _player.dispose();
  }
}
