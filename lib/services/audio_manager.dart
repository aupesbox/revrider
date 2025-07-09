// lib/services/audio_manager.dart

import 'package:just_audio/just_audio.dart';

/// Defines each of the seven exhaust‐sound phases.
enum ThrottleSegment {
  start,
  idle,
  firstGear,
  secondGear,
  thirdGear,
  cruise,
  cutoff,
}

class AudioManager {
  // ─── Engine Players ─────────────────────────────────
  final AudioPlayer _startPlayer   = AudioPlayer();
  final AudioPlayer _idlePlayer    = AudioPlayer();
  final AudioPlayer _gear1Player   = AudioPlayer();
  final AudioPlayer _gear2Player   = AudioPlayer();
  final AudioPlayer _gear3Player   = AudioPlayer();
  final AudioPlayer _cruisePlayer  = AudioPlayer();
  final AudioPlayer _cutoffPlayer  = AudioPlayer();

  // ─── Music Player ──────────────────────────────────
  final AudioPlayer _musicPlayer   = AudioPlayer();

  // ─── State ───────────────────────────────────────
  String currentProfile = 'default';
  ThrottleSegment _currentSegment = ThrottleSegment.idle;
  double _masterVolume   = 1.0;
  double _crossfadeRate  = 1.0;
  double _pitchSens      = 1.0;
  double _lastThrottle   = 0.0;

  /// Preload all seven exhaust segments (start is one‐shot).
  Future<void> init() async {
    final base = 'assets/sounds/$currentProfile';

    await _startPlayer .setAsset('$base/start.mp3')
        .then((_) => _startPlayer.setLoopMode(LoopMode.off));

    await _idlePlayer  .setAsset('$base/idle.mp3')
        .then((_) => _idlePlayer.setLoopMode(LoopMode.one));

    await _gear1Player .setAsset('$base/first_gear.mp3')
        .then((_) => _gear1Player.setLoopMode(LoopMode.one));

    await _gear2Player .setAsset('$base/second_gear.mp3')
        .then((_) => _gear2Player.setLoopMode(LoopMode.one));

    await _gear3Player .setAsset('$base/third_gear.mp3')
        .then((_) => _gear3Player.setLoopMode(LoopMode.one));

    await _cruisePlayer.setAsset('$base/cruise.mp3')
        .then((_) => _cruisePlayer.setLoopMode(LoopMode.one));

    await _cutoffPlayer.setAsset('$base/cutoff.mp3')
        .then((_) => _cutoffPlayer.setLoopMode(LoopMode.one));
  }

  // ─── Legacy / UI‐friendly API ──────────────────────

  /// Exactly your old `play()` call.
  Future<void> play() => playStart();

  /// Play the one‐shot “start” then loop idle.
  Future<void> playStart() async {
    await _stopAllLoopers();
    await _startPlayer.seek(Duration.zero);
    await _startPlayer.play();
    final dur = _startPlayer.duration ?? const Duration(seconds: 1);
    Future.delayed(dur, () => _playSegment(ThrottleSegment.idle));
  }

  /// Change crossfade sharpness, then reapply current throttle.
  void setCrossfadeRate(double rate) {
    _crossfadeRate = rate.clamp(0.1, 2.0);
    updateThrottle(_lastThrottle);
  }

  /// Change pitch sensitivity, then reapply.
  void setPitchSensitivity(double sens) {
    _pitchSens = sens.clamp(0.1, 3.0);
    updateThrottle(_lastThrottle);
  }

  /// Change overall engine volume, then reapply.
  void setMasterVolume(double vol) {
    _masterVolume = vol.clamp(0.0, 1.0);
    updateThrottle(_lastThrottle);
  }

  // ─── Throttle‐driven logic ─────────────────────────

  /// Feed in a new throttle % 0–100.
  void updateThrottle(double throttlePercent) {
    _lastThrottle = throttlePercent;
    final t = (throttlePercent / 100).clamp(0.0, 1.0);

    ThrottleSegment seg;
    if (t == 0) seg = ThrottleSegment.idle;
    else if (t < 0.2) seg = ThrottleSegment.firstGear;
    else if (t < 0.4) seg = ThrottleSegment.secondGear;
    else if (t < 0.6) seg = ThrottleSegment.thirdGear;
    else if (t < 0.8) seg = ThrottleSegment.cruise;
    else seg = ThrottleSegment.cutoff;

    if (seg != _currentSegment) {
      _playSegment(seg);
    }
  }

  Future<void> _playSegment(ThrottleSegment seg) async {
    _currentSegment = seg;
    await _stopAllLoopers();
    final player = <ThrottleSegment, AudioPlayer>{
      ThrottleSegment.idle:       _idlePlayer,
      ThrottleSegment.firstGear:  _gear1Player,
      ThrottleSegment.secondGear: _gear2Player,
      ThrottleSegment.thirdGear:  _gear3Player,
      ThrottleSegment.cruise:     _cruisePlayer,
      ThrottleSegment.cutoff:     _cutoffPlayer,
    }[seg];
    if (player != null) {
      await player.seek(Duration.zero);
      await player.setVolume(_masterVolume);
      await player.setSpeed(0.8 + (_lastThrottle/100) * _pitchSens);
      await player.play();
    }
  }

  Future<void> _stopAllLoopers() async {
    for (var p in [
      _idlePlayer,
      _gear1Player,
      _gear2Player,
      _gear3Player,
      _cruisePlayer,
      _cutoffPlayer,
    ]) {
      await p.stop();
    }
  }

  // ─── Profile switching ────────────────────────────

  /// Load a different bank and re‐init.
  Future<void> switchProfile(String profileName) async {
    currentProfile = profileName;
    await init();
  }

  // ─── Music API ─────────────────────────────────────

  Future<void> loadMusicAsset(String path)   => _musicPlayer.setAsset(path);
  Future<void> playMusic()                   => _musicPlayer.play();
  Future<void> pauseMusic()                  => _musicPlayer.pause();
  Future<void> setMusicMix(double mix)       => _musicPlayer.setVolume(mix.clamp(0.0, 1.0));

  // ─── Cleanup ──────────────────────────────────────

  Future<void> dispose() async {
    for (var p in [
      _startPlayer,
      _idlePlayer,
      _gear1Player,
      _gear2Player,
      _gear3Player,
      _cruisePlayer,
      _cutoffPlayer,
      _musicPlayer,
    ]) {
      await p.dispose();
    }
  }
}
