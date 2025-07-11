// lib/services/audio_manager.dart

import 'package:just_audio/just_audio.dart';

/// The rev phases we carve out of one big file.
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
  // ─── Players ───────────────────────────────────────────
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
  String currentProfile = 'default';               // folder under assets/sounds/
  ThrottleSegment _currentSegment = ThrottleSegment.idle;
  double _masterVolume    = 1.0;
  double _crossfadeRate   = 1.0;
  double _pitchSens       = 1.0;
  double _lastThrottle    = 0.0;

  /// Millisecond bounds for each segment in exhaust_all.mp3
  static const Map<ThrottleSegment, List<int>> _segmentBounds = {
    ThrottleSegment.start:     [0,    2500],
    ThrottleSegment.idle:      [2500, 4500],
    ThrottleSegment.firstGear: [4500, 6500],
    ThrottleSegment.secondGear:[6500, 8500],
    ThrottleSegment.thirdGear: [8500, 10500],
    ThrottleSegment.cruise:    [10500,12500],
    ThrottleSegment.cutoff:    [12500,14500],
  };

  /// Always clip from this master source
  UriAudioSource get _masterSource => AudioSource.asset(
    'assets/sounds/$currentProfile/exhaust_all.mp3',
  );

  /// Preload & configure each clip player.
  Future<void> init() async {
    await _configPlayer(_startPlayer,   ThrottleSegment.start,    loop: false);
    await _configPlayer(_idlePlayer,    ThrottleSegment.idle,     loop: true);
    await _configPlayer(_gear1Player,   ThrottleSegment.firstGear, loop: true);
    await _configPlayer(_gear2Player,   ThrottleSegment.secondGear,loop: true);
    await _configPlayer(_gear3Player,   ThrottleSegment.thirdGear, loop: true);
    await _configPlayer(_cruisePlayer,  ThrottleSegment.cruise,   loop: true);
    await _configPlayer(_cutoffPlayer,  ThrottleSegment.cutoff,   loop: true);
  }

  Future<void> _configPlayer(
      AudioPlayer player,
      ThrottleSegment seg, {
        required bool loop,
      }) async {
    final bounds = _segmentBounds[seg]!;
    await player.setAudioSource(
      ClippingAudioSource(
        start: Duration(milliseconds: bounds[0]),
        end:   Duration(milliseconds: bounds[1]),
        child: _masterSource,
      ),
    );
    await player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
  }

  // ─── Playback API ───────────────────────────────────

  /// Exactly your old `play()` API.
  Future<void> playStart() async {
    await _stopAllLoopers();
    await _startPlayer.seek(Duration.zero);
    await _startPlayer.play();
    final dur = _startPlayer.duration ?? const Duration(milliseconds: 1500);
    Future.delayed(dur, () => _playSegment(ThrottleSegment.idle));
    await _startPlayer.stop();
  }

  /// On BLE disconnect.
  Future<void> playCutoff() async {
    await _stopAllLoopers();
    //await _playSegment(ThrottleSegment.cutoff);
    //final dur = _cutoffPlayer.duration ?? const Duration(milliseconds: 1500);
    //Future.delayed(dur, () => _playSegment(ThrottleSegment.idle));
  }

  /// Feed in throttle 0–100 and switch segments.
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
    final playerMap = {
      ThrottleSegment.idle:       _idlePlayer,
      ThrottleSegment.firstGear:  _gear1Player,
      ThrottleSegment.secondGear: _gear2Player,
      ThrottleSegment.thirdGear:  _gear3Player,
      ThrottleSegment.cruise:     _cruisePlayer,
      ThrottleSegment.cutoff:     _cutoffPlayer,
    };
    final p = playerMap[seg];
    if (p != null) {
      await p.seek(Duration.zero);
      await p.setVolume(_masterVolume);
      await p.setSpeed(0.8 + (_lastThrottle / 100) * _pitchSens);
      await p.play();
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

  // ─── Profile switching ─────────────────────────────

  /// Switch to another sound profile and reload segments.
  Future<void> switchProfile(String profileName) async {
    currentProfile = profileName;
    await init();
  }

  // ─── Configuration API ─────────────────────────────

  /// Change overall engine volume, then reapply.
  void setMasterVolume(double vol) {
    _masterVolume = vol.clamp(0.0, 1.0);
    updateThrottle(_lastThrottle);
  }

  /// Change pitch sensitivity, then reapply.
  void setPitchSensitivity(double sens) {
    _pitchSens = sens.clamp(0.1, 3.0);
    updateThrottle(_lastThrottle);
  }

  /// Change crossfade sharpness, then reapply.
  void setCrossfadeRate(double rate) {
    _crossfadeRate = rate.clamp(0.1, 2.0);
    updateThrottle(_lastThrottle);
  }

  // ─── Music API ─────────────────────────────────────

  Future<void> loadMusicAsset(String path)    => _musicPlayer.setAsset(path);
  Future<void> playMusic()                    => _musicPlayer.play();
  Future<void> pauseMusic()                   => _musicPlayer.pause();
  Future<void> setMusicMix(double mix)        => _musicPlayer.setVolume(mix.clamp(0.0, 1.0));

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
