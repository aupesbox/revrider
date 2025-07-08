// lib/services/audio_manager.dart

import 'package:just_audio/just_audio.dart';

class AudioManager {
  // Engine-sound players
  final AudioPlayer _startPlayer  = AudioPlayer();
  final AudioPlayer _idlePlayer   = AudioPlayer();
  final AudioPlayer _midPlayer    = AudioPlayer();
  final AudioPlayer _highPlayer   = AudioPlayer();
  final AudioPlayer _cutoffPlayer = AudioPlayer();

  // Music player
  final AudioPlayer _musicPlayer  = AudioPlayer();

  String currentProfile = 'default';
  double _crossfadeRate = 1.0;
  double _pitchSens     = 1.0;
  double _masterVolume  = 1.0;
  double _lastThrottle  = 0.0;

  /// Load all engine-banks and set them to loop
  Future<void> init() async {
    final base = 'assets/sounds/$currentProfile';

    await _startPlayer.setAsset('$base/start.mp3');
    await _idlePlayer .setAsset('$base/idle.mp3');
    _idlePlayer.setLoopMode(LoopMode.one);
    await _midPlayer  .setAsset('$base/mid.mp3');
    _midPlayer.setLoopMode(LoopMode.one);
    await _highPlayer .setAsset('$base/high.mp3');
    _highPlayer.setLoopMode(LoopMode.one);
    await _cutoffPlayer.setAsset('$base/cutoff.mp3');
    _cutoffPlayer.setLoopMode(LoopMode.one);
  }

  /// Alias for legacy calls
  Future<void> play() => playStart();

  /// Play "start" once, then begin looping banks
  Future<void> playStart() async {
    await _startPlayer.play();
    await playLoops();
  }

  /// Loop idle→mid→high→cutoff indefinitely
  Future<void> playLoops() async {
    await Future.wait([
      _idlePlayer.play(),
      _midPlayer.play(),
      _highPlayer.play(),
      _cutoffPlayer.play(),
    ]);
    _applyThrottle(_lastThrottle);
  }

  /// Update volumes + pitch based on 0–100 throttle
  void updateThrottle(double throttlePercent) {
    _lastThrottle = throttlePercent;
    _applyThrottle(throttlePercent);
  }

  void _applyThrottle(double throttlePercent) {
    final t   = (throttlePercent / 100).clamp(0.0, 1.0);
    final seg = (1 / 3) * _crossfadeRate;
    double vIdle = 0, vMid = 0, vHigh = 0, vCutoff = 0;

    if (t <= seg) {
      final p = t / seg;
      vIdle = 1 - p;
      vMid  = p;
    } else if (t <= 2 * seg) {
      final p = (t - seg) / seg;
      vMid  = 1 - p;
      vHigh = p;
    } else {
      final p = (t - 2 * seg) / (1 - 2 * seg);
      vHigh   = 1 - p;
      vCutoff = p;
    }

    _idlePlayer  .setVolume(vIdle   * _masterVolume);
    _midPlayer   .setVolume(vMid    * _masterVolume);
    _highPlayer  .setVolume(vHigh   * _masterVolume);
    _cutoffPlayer.setVolume(vCutoff * _masterVolume);

    final speed = (0.8 + t) * _pitchSens;
    for (var p in [_idlePlayer, _midPlayer, _highPlayer, _cutoffPlayer]) {
      p.setSpeed(speed);
    }
  }

  /// Overall engine volume
  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
    _applyThrottle(_lastThrottle);
  }

  /// How sharp each bank transitions
  void setCrossfadeRate(double rate) {
    _crossfadeRate = rate.clamp(0.1, 2.0);
    _applyThrottle(_lastThrottle);
  }

  /// How much pitch changes with throttle
  void setPitchSensitivity(double sens) {
    _pitchSens = sens.clamp(0.1, 3.0);
    _applyThrottle(_lastThrottle);
  }

  /// Switch to a different sound profile
  Future<void> switchProfile(String profileName) async {
    currentProfile = profileName;
    await init();
    await playStart();
  }

  // ── Music API ───────────────────────────────────────

  /// Load a music asset (for Music Mode)
  Future<void> loadMusicAsset(String assetPath) async {
    await _musicPlayer.setAsset(assetPath);
  }

  /// Play loaded music
  Future<void> playMusic() => _musicPlayer.play();

  /// Pause music
  Future<void> pauseMusic() => _musicPlayer.pause();

  /// Mix ratio: 0.0 = pure engine, 1.0 = pure music
  void setMusicMix(double mix) {
    _musicPlayer.setVolume(mix.clamp(0.0, 1.0));
  }

  /// Clean up all players
  Future<void> dispose() async {
    await Future.wait([
      _startPlayer.dispose(),
      _idlePlayer.dispose(),
      _midPlayer.dispose(),
      _highPlayer.dispose(),
      _cutoffPlayer.dispose(),
      _musicPlayer.dispose(),
    ]);
  }
}
