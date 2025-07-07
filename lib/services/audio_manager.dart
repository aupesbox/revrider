// lib/services/audio_manager.dart

import 'package:just_audio/just_audio.dart';

class AudioManager {
  // Engine sound players
  final AudioPlayer _idlePlayer   = AudioPlayer();
  final AudioPlayer _midPlayer    = AudioPlayer();
  final AudioPlayer _highPlayer   = AudioPlayer();
  final AudioPlayer _cutoffPlayer = AudioPlayer();

  // Music player
  final AudioPlayer _musicPlayer  = AudioPlayer();

  /// Folder under assets/sounds/ to load from
  String currentProfile = 'default';

  // Throttle, crossfade, pitch
  double _crossfadeRate = 1.0;
  double _pitchSens     = 1.0;
  double _masterVolume  = 1.0;
  double _lastThrottle  = 0.0;

  // Music vs engine mix [0.0–1.0]
  double _musicMix = 0.0;

  /// Initialize all players, load engine assets & set them to loop
  Future<void> init() async {
    final base = 'assets/sounds/$currentProfile';

    await _idlePlayer  .setAsset('$base/idle.mp3');
    _idlePlayer.setLoopMode(LoopMode.one);

    await _midPlayer   .setAsset('$base/mid.mp3');
    _midPlayer.setLoopMode(LoopMode.one);

    await _highPlayer  .setAsset('$base/high.mp3');
    _highPlayer.setLoopMode(LoopMode.one);

    await _cutoffPlayer.setAsset('$base/cutoff.mp3');
    _cutoffPlayer.setLoopMode(LoopMode.one);
  }

  /// Begin engine loops (and re-apply levels)
  Future<void> play() async {
    await Future.wait([
      _idlePlayer.play(),
      _midPlayer.play(),
      _highPlayer.play(),
      _cutoffPlayer.play(),
    ]);
    _applyVolumes();
  }

  /// Update throttle % [0–100]
  void updateThrottle(double throttlePercent) {
    _lastThrottle = throttlePercent;
    _applyVolumes();
  }

  /// Core method: mix engine volumes & music volume
  void _applyVolumes() {
    // engine mix based on throttle
    final t   = (_lastThrottle / 100).clamp(0.0, 1.0);
    final seg = (1 / 3) * _crossfadeRate;
    double vIdle=0, vMid=0, vHigh=0, vCutoff=0;

    if (t <= seg) {
      final p = t / seg;
      vIdle  = 1 - p;
      vMid   = p;
    } else if (t <= 2 * seg) {
      final p = (t - seg) / seg;
      vMid   = 1 - p;
      vHigh  = p;
    } else {
      final p = (t - 2 * seg) / (1 - 2 * seg);
      vHigh   = 1 - p;
      vCutoff = p;
    }

    // scale engine and music by master & mix
    final engineScale = (1 - _musicMix) * _masterVolume;
    final musicScale  = _musicMix * _masterVolume;

    _idlePlayer  .setVolume(vIdle   * engineScale);
    _midPlayer   .setVolume(vMid    * engineScale);
    _highPlayer  .setVolume(vHigh   * engineScale);
    _cutoffPlayer.setVolume(vCutoff * engineScale);

    _musicPlayer .setVolume(musicScale);

    // pitch‐shift both engine & music
    final speed = (0.8 + t) * _pitchSens;
    for (var p in [_idlePlayer, _midPlayer, _highPlayer, _cutoffPlayer, _musicPlayer]) {
      p.setSpeed(speed);
    }
  }

  /// Set overall master volume [0.0–1.0]
  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
    _applyVolumes();
  }

  /// Crossfade rate [0.1–2.0]
  void setCrossfadeRate(double rate) {
    _crossfadeRate = rate.clamp(0.1, 2.0);
    _applyVolumes();
  }

  /// Pitch sensitivity [0.1–3.0]
  void setPitchSensitivity(double sens) {
    _pitchSens = sens.clamp(0.1, 3.0);
    _applyVolumes();
  }

  /// Switch engine profile (reload assets & replay)
  Future<void> switchProfile(String profileName) async {
    currentProfile = profileName;
    await init();
    await play();
  }

  /// ---- MUSIC METHODS ----

  /// Load a music asset (e.g. 'assets/music/song.mp3')
  Future<void> loadMusicAsset(String assetPath) async {
    await _musicPlayer.setAsset(assetPath);
    _musicPlayer.setLoopMode(LoopMode.one);
    _applyVolumes();
  }

  /// Start music playback
  Future<void> playMusic() async {
    await _musicPlayer.play();
  }

  /// Pause music playback
  Future<void> pauseMusic() async {
    await _musicPlayer.pause();
  }

  /// Set the mix between music (1.0) and engine (0.0)
  void setMusicMix(double mix) {
    _musicMix = mix.clamp(0.0, 1.0);
    _applyVolumes();
  }

  /// Dispose all players
  Future<void> dispose() async {
    await Future.wait([
      _idlePlayer.dispose(),
      _midPlayer.dispose(),
      _highPlayer.dispose(),
      _cutoffPlayer.dispose(),
      _musicPlayer.dispose(),
    ]);
  }
}
