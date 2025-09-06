// lib/services/audio_manager.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:just_audio/just_audio.dart';

enum ThrottleSegment { start, idle, gear1, gear2, gear3, cruise, cutoff }

class AudioManager {
  final AudioPlayer _player = AudioPlayer();
  String _bank = 'default';
  String _file = 'exhaust.mp3';
  ThrottleSegment? _currentSeg;

  // NEW: allow using a file path instead of asset for single-master
  String? _filePathMaster;

  static const Map<ThrottleSegment, List<int>> _bounds = {
    ThrottleSegment.start:  [0,     2500],
    ThrottleSegment.idle:   [2500,  4500],
    ThrottleSegment.gear1:  [4500,  6500],
    ThrottleSegment.gear2:  [6500,  8500],
    ThrottleSegment.gear3:  [8500, 10500],
    ThrottleSegment.cruise: [10500,12500],
    ThrottleSegment.cutoff: [12500,14500],
  };

  final AudioPlayer _idleLayer = AudioPlayer();
  final AudioPlayer _midLayer  = AudioPlayer();
  final AudioPlayer _highLayer = AudioPlayer();
  bool _layeredMode = false;
  int _lastPct = 0;

  final AudioPlayer _musicPlayer = AudioPlayer();
  bool   _musicEnabled = false;
  double _engineVolume = 1.0;
  double _musicVolume  = 0.5;

  double duckThreshold    = 0.75;
  double duckVolumeFactor = 0.3;
  double crossfadeRate    = 0.5;

  Future<void> loadBank(
      String bankId, {
        String masterFileName = 'exhaust.mp3',
      }) async {
    _layeredMode = false;
    _filePathMaster = null;             // reset override
    _bank = bankId;
    _file = masterFileName;
    _currentSeg = null;
  }

  // NEW: single-master from FILE path (recording)
  Future<void> loadSingleMasterFile(String filePath) async {
    _layeredMode = false;
    _filePathMaster = filePath;         // use file instead of asset
    _currentSeg = null;
  }

  Future<void> loadPackFromFiles({
    required String idlePath,
    required String midPath,
    required String highPath,
  }) async {
    _layeredMode = true;
    _filePathMaster = null;             // not used in layered mode
    await _idleLayer.setFilePath(idlePath);
    await _midLayer .setFilePath(midPath);
    await _highLayer.setFilePath(highPath);

    await _idleLayer.setLoopMode(LoopMode.one);
    await _midLayer .setLoopMode(LoopMode.one);
    await _highLayer.setLoopMode(LoopMode.one);

    await _idleLayer.setVolume(0);
    await _midLayer .setVolume(0);
    await _highLayer.setVolume(0);

    _currentSeg = null;
  }

  Future<void> playStart() async {
    if (_layeredMode) {
      if (!_idleLayer.playing) await _idleLayer.play();
      if (!_midLayer.playing)  await _midLayer.play();
      if (!_highLayer.playing) await _highLayer.play();
      await _applyLayeredForPct(_lastPct);
      return;
    }
    _currentSeg = ThrottleSegment.start;
    await _playSegment(ThrottleSegment.start, loop: false);
    final dur = Duration(milliseconds: _bounds[ThrottleSegment.start]![1]);
    Future.delayed(dur, () => updateThrottle(0));
  }

  Future<void> playCutoff() async {
    if (_layeredMode) {
      await _idleLayer.stop();
      await _midLayer.stop();
      await _highLayer.stop();
      return;
    }
    _currentSeg = ThrottleSegment.cutoff;
    await _playSegment(ThrottleSegment.cutoff, loop: false);
  }

  void setMix({
    required bool enabled,
    required double engineVol,
    required double musicVol,
  }) {
    _musicEnabled = enabled;
    _engineVolume = engineVol.clamp(0.0, 1.0);
    _musicVolume  = musicVol.clamp(0.0, 1.0);

    if (_layeredMode) {
      _idleLayer.setVolume(_engineVolume);
      _midLayer .setVolume(_engineVolume);
      _highLayer.setVolume(_engineVolume);
    } else {
      _player.setVolume(_engineVolume);
    }
    if (_musicEnabled) {
      FlutterVolumeController.setVolume(_musicVolume);
    }
  }

  Future<void> loadMusicAsset(String assetPath) async {
    try { await _musicPlayer.setAsset(assetPath); } catch (e) { debugPrint('loadMusicAsset: $e'); }
  }

  Future<void> updateThrottle(int pct) async {
    _lastPct = pct.clamp(0, 100);

    if (_layeredMode) {
      await _applyLayeredForPct(_lastPct);
      return;
    }

    final t = _lastPct / 100.0;
    final seg = (t == 0.0)
        ? ThrottleSegment.idle
        : (t < 0.3)
        ? ThrottleSegment.gear1
        : (t < 0.5)
        ? ThrottleSegment.gear2
        : (t < 0.7)
        ? ThrottleSegment.gear3
        : (t < 0.9)
        ? ThrottleSegment.cruise
        : ThrottleSegment.cutoff;

    if (seg == _currentSeg) return;
    _currentSeg = seg;

    final loop = seg != ThrottleSegment.start && seg != ThrottleSegment.cutoff;
    await _playSegment(seg, loop: loop);
  }

  Future<void> _applyLayeredForPct(int pct) async {
    final t = pct / 100.0;
    final useIdle = t < 0.33;
    final useMid  = t >= 0.33 && t < 0.75;
    final useHigh = t >= 0.75;

    if (!_idleLayer.playing) await _idleLayer.play();
    if (!_midLayer.playing)  await _midLayer.play();
    if (!_highLayer.playing) await _highLayer.play();

    await _idleLayer.setVolume(useIdle ? _engineVolume : 0);
    await _midLayer .setVolume(useMid  ? _engineVolume : 0);
    await _highLayer.setVolume(useHigh ? _engineVolume : 0);
  }

  Future<void> _playSegment(ThrottleSegment seg, {required bool loop}) async {
    final bounds = _bounds[seg]!;
    final child = (_filePathMaster != null)
        ? AudioSource.uri(Uri.file(_filePathMaster!))
        : AudioSource.asset('assets/sounds/$_bank/$_file');

    final clip = ClippingAudioSource(
      start: Duration(milliseconds: bounds[0]),
      end:   Duration(milliseconds: bounds[1]),
      child: child,
    );

    await _player.setAudioSource(clip);
    await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
    await _player.setVolume(_engineVolume);
    await _player.play();
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _idleLayer.dispose();
    await _midLayer.dispose();
    await _highLayer.dispose();
    await _musicPlayer.dispose();
  }
}

// // lib/services/audio_manager.dart
//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter_volume_controller/flutter_volume_controller.dart';
// import 'package:just_audio/just_audio.dart';
//
// /// Segment-based exhaust from a single master file, with optional layered pack mode.
// enum ThrottleSegment { start, idle, gear1, gear2, gear3, cruise, cutoff }
//
// class AudioManager {
//   // === Single-master mode (your original) ===
//   final AudioPlayer _player = AudioPlayer();
//   String _bank = 'default';
//   String _file = 'exhaust.mp3';
//   ThrottleSegment? _currentSeg;
//
//   // Segment bounds (ms) inside the master file
//   static const Map<ThrottleSegment, List<int>> _bounds = {
//     ThrottleSegment.start:  [0,     2500],
//     ThrottleSegment.idle:   [2500,  4500],
//     ThrottleSegment.gear1:  [4500,  6500],
//     ThrottleSegment.gear2:  [6500,  8500],
//     ThrottleSegment.gear3:  [8500, 10500],
//     ThrottleSegment.cruise: [10500,12500],
//     ThrottleSegment.cutoff: [12500,14500],
//   };
//
//   // === Layered-pack mode (optional; for AI/store packs) ===
//   final AudioPlayer _idleLayer = AudioPlayer();
//   final AudioPlayer _midLayer  = AudioPlayer();
//   final AudioPlayer _highLayer = AudioPlayer();
//   bool _layeredMode = false;          // false = single-master segments, true = layered
//   int _lastPct = 0;
//
//   // === Music ===
//   final AudioPlayer _musicPlayer = AudioPlayer();
//   bool   _musicEnabled = false;
//   double _engineVolume = 1.0;
//   double _musicVolume  = 0.5;
//
//   // Exposed (not used internally here; preserved for API parity with AppState/UI)
//   double duckThreshold    = 0.75;
//   double duckVolumeFactor = 0.3;
//   double crossfadeRate    = 0.5;
//
//   // ─────────────────────────────────────────────────────────────────────────────
//   // Loading
//   // ─────────────────────────────────────────────────────────────────────────────
//
//   /// Use the original single-master logic:
//   /// plays clips from `assets/sounds/<bankId>/<masterFileName>`
//   Future<void> loadBank(
//       String bankId, {
//         String masterFileName = 'exhaust.mp3',
//       }) async {
//     _layeredMode = false;
//     _bank = bankId;
//     _file = masterFileName;
//     _currentSeg = null; // force first segment set on next play/update
//   }
//
//   /// Optional: use three direct files (idle/mid/high) for packs (AI/store).
//   Future<void> loadPackFromFiles({
//     required String idlePath,
//     required String midPath,
//     required String highPath,
//   }) async {
//     _layeredMode = true;
//     await _idleLayer.setFilePath(idlePath);
//     await _midLayer .setFilePath(midPath);
//     await _highLayer.setFilePath(highPath);
//
//     await _idleLayer.setLoopMode(LoopMode.one);
//     await _midLayer .setLoopMode(LoopMode.one);
//     await _highLayer.setLoopMode(LoopMode.one);
//
//     await _idleLayer.setVolume(0);
//     await _midLayer .setVolume(0);
//     await _highLayer.setVolume(0);
//
//     _currentSeg = null; // not used in layered mode; kept for parity
//   }
//
//   // ─────────────────────────────────────────────────────────────────────────────
//   // Playback lifecycle
//   // ─────────────────────────────────────────────────────────────────────────────
//
//   /// Play the startup slice once, then go to idle (single-master) or just start layers.
//   Future<void> playStart() async {
//     if (_layeredMode) {
//       // Start all layers muted; we'll unmute based on throttle
//       if (!_idleLayer.playing) await _idleLayer.play();
//       if (!_midLayer.playing)  await _midLayer.play();
//       if (!_highLayer.playing) await _highLayer.play();
//       await _applyLayeredForPct(_lastPct);
//       return;
//     }
//
//     // Single-master segments
//     _currentSeg = ThrottleSegment.start;
//     await _playSegment(ThrottleSegment.start, loop: false);
//     final dur = Duration(milliseconds: _bounds[ThrottleSegment.start]![1]);
//     Future.delayed(dur, () => updateThrottle(0));
//   }
//
//   /// Play the cutoff slice once (single-master) or mute layers (layered).
//   Future<void> playCutoff() async {
//     if (_layeredMode) {
//       await _idleLayer.stop();
//       await _midLayer.stop();
//       await _highLayer.stop();
//       return;
//     }
//     _currentSeg = ThrottleSegment.cutoff;
//     await _playSegment(ThrottleSegment.cutoff, loop: false);
//   }
//
//   // ─────────────────────────────────────────────────────────────────────────────
//   // Mix / volumes
//   // ─────────────────────────────────────────────────────────────────────────────
//
//   /// Configure engine & music volumes. Music uses system volume via FlutterVolumeController.
//   void setMix({
//     required bool enabled,
//     required double engineVol,
//     required double musicVol,
//   }) {
//     _musicEnabled = enabled;
//     _engineVolume = engineVol.clamp(0.0, 1.0);
//     _musicVolume  = musicVol.clamp(0.0, 1.0);
//
//     if (_layeredMode) {
//       // Set on all layers (only the active one will be audible)
//       _idleLayer.setVolume(_engineVolume);
//       _midLayer .setVolume(_engineVolume);
//       _highLayer.setVolume(_engineVolume);
//     } else {
//       _player.setVolume(_engineVolume);
//     }
//
//     if (_musicEnabled) {
//       FlutterVolumeController.setVolume(_musicVolume);
//     }
//   }
//
//   /// Optional local music (demo/background)
//   Future<void> loadMusicAsset(String assetPath) async {
//     try {
//       await _musicPlayer.setAsset(assetPath);
//     } catch (e) {
//       debugPrint('AudioManager.loadMusicAsset error: $e');
//     }
//   }
//
//   // ─────────────────────────────────────────────────────────────────────────────
//   // Throttle → playback
//   // ─────────────────────────────────────────────────────────────────────────────
//
//   /// Update throttle 0–100.
//   Future<void> updateThrottle(int pct) async {
//     _lastPct = pct.clamp(0, 100);
//
//     if (_layeredMode) {
//       await _applyLayeredForPct(_lastPct);
//       return;
//     }
//
//     // Single-master segment selection (your original logic)
//     final t = _lastPct / 100.0;
//     final seg = (t == 0.0)
//         ? ThrottleSegment.idle
//         : (t < 0.3)
//         ? ThrottleSegment.gear1
//         : (t < 0.5)
//         ? ThrottleSegment.gear2
//         : (t < 0.7)
//         ? ThrottleSegment.gear3
//         : (t < 0.9)
//         ? ThrottleSegment.cruise
//         : ThrottleSegment.cutoff;
//
//     if (seg == _currentSeg) return;
//     _currentSeg = seg;
//
//     final loop = seg != ThrottleSegment.start && seg != ThrottleSegment.cutoff;
//     await _playSegment(seg, loop: loop);
//   }
//
//   // ─────────────────────────────────────────────────────────────────────────────
//   // Internals
//   // ─────────────────────────────────────────────────────────────────────────────
//
//   Future<void> _applyLayeredForPct(int pct) async {
//     final t = pct / 100.0;
//
//     // Simple thresholds mapping for layered packs:
//     //   0..33% => idle, 33..75% => mid, 75..100% => high
//     final useIdle = t < 0.33;
//     final useMid  = t >= 0.33 && t < 0.75;
//     final useHigh = t >= 0.75;
//
//     // Start players if not running
//     if (!_idleLayer.playing) await _idleLayer.play();
//     if (!_midLayer.playing)  await _midLayer.play();
//     if (!_highLayer.playing) await _highLayer.play();
//
//     // Hard switch volumes (keeps things stable; no rebuffer/restart)
//     await _idleLayer.setVolume(useIdle ? _engineVolume : 0);
//     await _midLayer .setVolume(useMid  ? _engineVolume : 0);
//     await _highLayer.setVolume(useHigh ? _engineVolume : 0);
//   }
//
//   Future<void> _playSegment(ThrottleSegment seg, {required bool loop}) async {
//     final bounds = _bounds[seg]!;
//     final clip = ClippingAudioSource(
//       start: Duration(milliseconds: bounds[0]),
//       end:   Duration(milliseconds: bounds[1]),
//       child: AudioSource.asset('assets/sounds/$_bank/$_file'),
//     );
//     await _player.setAudioSource(clip);
//     await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
//     await _player.setVolume(_engineVolume);
//     await _player.play();
//   }
//
//   Future<void> dispose() async {
//     await _player.dispose();
//     await _idleLayer.dispose();
//     await _midLayer.dispose();
//     await _highLayer.dispose();
//     await _musicPlayer.dispose();
//   }
// }
