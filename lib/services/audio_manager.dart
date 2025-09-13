// lib/services/audio_manager.dart
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioManager {
  // One-shot clips
  AudioPlayer? _startClip;
  AudioPlayer? _shutdownClip;

  // Continuous loop layers
  final AudioPlayer _idleLayer = AudioPlayer();
  final AudioPlayer _gear1Layer = AudioPlayer();
  final AudioPlayer _gear2Layer = AudioPlayer();
  final AudioPlayer _gear3Layer = AudioPlayer();

  int _lastZone = -1;
  double _engineVolume = 1.0;

  int crossfadeMs = 300;
  int _fadeSteps = 12;

  /// Load a 6-clip pack
  Future<void> loadFullPack({
    required String startPath,
    required String idlePath,
    required String gear1Path,
    required String gear2Path,
    required String gear3Path,
    required String shutdownPath,
  }) async {
    // One-shots
    _startClip = AudioPlayer();
    await _startClip!.setAsset(startPath);

    _shutdownClip = AudioPlayer();
    await _shutdownClip!.setAsset(shutdownPath);

    // Loops
    await _idleLayer.setAsset(idlePath);
    await _gear1Layer.setAsset(gear1Path);
    await _gear2Layer.setAsset(gear2Path);
    await _gear3Layer.setAsset(gear3Path);

    await _idleLayer.setLoopMode(LoopMode.one);
    await _gear1Layer.setLoopMode(LoopMode.one);
    await _gear2Layer.setLoopMode(LoopMode.one);
    await _gear3Layer.setLoopMode(LoopMode.one);

    await _idleLayer.setVolume(0);
    await _gear1Layer.setVolume(0);
    await _gear2Layer.setVolume(0);
    await _gear3Layer.setVolume(0);

    // Pre-start the loops quietly
    await _idleLayer.play();
    await _gear1Layer.play();
    await _gear2Layer.play();
    await _gear3Layer.play();
  }

  Future<void> playStart() async {
    if (_startClip != null) {
      await _startClip!.seek(Duration.zero);
      await _startClip!.play();
    }
  }

  Future<void> playShutdown() async {
    if (_shutdownClip != null) {
      await _shutdownClip!.seek(Duration.zero);
      await _shutdownClip!.play();
    }
    await stopAll();
  }

  Future<void> updateThrottle(int pct) async {
    final zone = (pct < 10)
        ? 0
        : (pct < 35)
        ? 1
        : (pct < 65)
        ? 2
        : 3;

    if (zone == _lastZone) return;
    _lastZone = zone;

    // ✅ Ensure loops are running
    if (!_idleLayer.playing) await _idleLayer.play();
    if (!_gear1Layer.playing) await _gear1Layer.play();
    if (!_gear2Layer.playing) await _gear2Layer.play();
    if (!_gear3Layer.playing) await _gear3Layer.play();

    // ✅ Crossfade volumes
    await Future.wait([
      _fade(_idleLayer, zone == 0 ? _engineVolume : 0),
      _fade(_gear1Layer, zone == 1 ? _engineVolume : 0),
      _fade(_gear2Layer, zone == 2 ? _engineVolume : 0),
      _fade(_gear3Layer, zone == 3 ? _engineVolume : 0),
    ]);
  }


  Future<void> _fade(AudioPlayer p, double target) async {
    final from = p.volume;
    if (_fadeSteps <= 1) {
      await p.setVolume(target.clamp(0.0, 1.0));
      return;
    }
    final dt = Duration(milliseconds: (crossfadeMs / _fadeSteps).round());
    for (var i = 1; i <= _fadeSteps; i++) {
      final v = from + (target - from) * (i / _fadeSteps);
      await p.setVolume(v.clamp(0.0, 1.0));
      await Future.delayed(dt);
    }
  }

  void setEngineVolume(double v) {
    _engineVolume = v.clamp(0.0, 1.0);
  }

  Future<void> stopAll() async {
    try {
      await _idleLayer.stop();
      await _gear1Layer.stop();
      await _gear2Layer.stop();
      await _gear3Layer.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _startClip?.dispose();
    await _shutdownClip?.dispose();
    await _idleLayer.dispose();
    await _gear1Layer.dispose();
    await _gear2Layer.dispose();
    await _gear3Layer.dispose();
  }
}

// import 'package:flutter/cupertino.dart';
// import 'package:just_audio/just_audio.dart';
//
// class AudioManager {
//   final AudioPlayer _idle = AudioPlayer();
//   final AudioPlayer _gear1 = AudioPlayer();
//   final AudioPlayer _gear2 = AudioPlayer();
//   final AudioPlayer _gear3 = AudioPlayer();
//
//   AudioPlayer? _start;
//   AudioPlayer? _shutdown;
//
//   double _engineVolume = 1.0;
//   int crossfadeMs = 300; // smooth transitions
//   int _lastZone = -1;
//
//   // Load your pack of 6 files
//   Future<void> loadFullPack({
//     required String startPath,
//     required String idlePath,
//     required String gear1Path,
//     required String gear2Path,
//     required String gear3Path,
//     required String shutdownPath,
//   }) async {
//     // looping layers
//     await _idle.setAsset(idlePath);
//     await _gear1.setAsset(gear1Path);
//     await _gear2.setAsset(gear2Path);
//     await _gear3.setAsset(gear3Path);
//
//     await _idle.setLoopMode(LoopMode.one);
//     await _gear1.setLoopMode(LoopMode.one);
//     await _gear2.setLoopMode(LoopMode.one);
//     await _gear3.setLoopMode(LoopMode.one);
//
//     await _idle.setVolume(0);
//     await _gear1.setVolume(0);
//     await _gear2.setVolume(0);
//     await _gear3.setVolume(0);
//
//     // one-shots
//     _start = AudioPlayer()..setAsset(startPath);
//     _shutdown = AudioPlayer()..setAsset(shutdownPath);
//
//     // start loops muted
//     await _idle.play();
//     await _gear1.play();
//     await _gear2.play();
//     await _gear3.play();
//   }
//
//   Future<void> playStart() async {
//     debugPrint("▶️ playStart triggered");
//     if (_start != null) {
//       await _start!.seek(Duration.zero);
//       await _start!.play();
//     }
//   }
//
//   Future<void> playShutdown() async {
//     debugPrint("▶️ playShut triggered");
//     if (_shutdown != null) {
//       await _shutdown!.seek(Duration.zero);
//       await _shutdown!.play();
//     }
//     await stopAll();
//   }
//
//   Future<void> updateThrottle(int pct) async {
//
//     final zone = (pct < 10)
//         ? 0
//         : (pct < 35)
//         ? 1
//         : (pct < 65)
//         ? 2
//         : 3;
//
//     if (zone == _lastZone) return;
//     _lastZone = zone;
//
//     // fade volumes between zones
//     await Future.wait([
//       _fade(_idle, zone == 0 ? _engineVolume : 0),
//       _fade(_gear1, zone == 1 ? _engineVolume : 0),
//       _fade(_gear2, zone == 2 ? _engineVolume : 0),
//       _fade(_gear3, zone == 3 ? _engineVolume : 0),
//     ]);
//   }
//
//   Future<void> _fade(AudioPlayer p, double target) async {
//     final from = p.volume;
//     const steps = 6;
//     final dt = Duration(milliseconds: (crossfadeMs / steps).round());
//     for (var i = 1; i <= steps; i++) {
//       final v = from + (target - from) * (i / steps);
//       await p.setVolume(v.clamp(0.0, 1.0));
//       await Future.delayed(dt);
//     }
//   }
//
//   void setEngineVolume(double v) {
//     _engineVolume = v.clamp(0.0, 1.0);
//   }
//
//   Future<void> stopAll() async {
//     try {
//       await _idle.stop();
//       await _gear1.stop();
//       await _gear2.stop();
//       await _gear3.stop();
//     } catch (_) {}
//   }
//
//   Future<void> dispose() async {
//     await _idle.dispose();
//     await _gear1.dispose();
//     await _gear2.dispose();
//     await _gear3.dispose();
//     await _start?.dispose();
//     await _shutdown?.dispose();
//   }
//
//
//   // Backward-compat shims so AppState still compiles
//   void setMix({required bool enabled, required double engineVol, required double musicVol}) {
//     _engineVolume = engineVol.clamp(0.0, 1.0);
//     // (musicVol ignored for now, since we dropped layered music logic)
//   }
//
//   Future<void> loadMusicAsset(String assetPath) async {
//     // optional: keep background music
//     try { await _musicPlayer.setAsset(assetPath); } catch (_) {}
//   }
//
//   Future<void> playCutoff() async {
//     await playShutdown();
//   }
//
//   Future<void> loadSingleMasterFile(String filePath) async {
//     // ✅ Compatibility shim: treat it as idle loop only
//     await loadFullPack(
//       startPath: "assets/sounds/default/start.wav",
//       idlePath: "assets/sounds/default/idle1.wav",
//       gear1Path: "assets/sounds/default/first_gear.wav",
//       gear2Path: "assets/sounds/default/second_gear.wav",
//       gear3Path: "assets/sounds/default/third_gear.wav",
//       shutdownPath: "assets/sounds/default/shutdown.wav",
//     );
//   }
//
//
// }
//
// class _musicPlayer {
//   static Future<void> setAsset(String assetPath) async {}
// }

// // lib/services/audio_manager.dart
// import 'package:flutter/cupertino.dart';
// import 'package:flutter_volume_controller/flutter_volume_controller.dart';
// import 'package:just_audio/just_audio.dart';
//
// class AudioManager {
//   // Core loop layers
//   final AudioPlayer _idleLayer = AudioPlayer();
//   final AudioPlayer _midLayer  = AudioPlayer();
//   final AudioPlayer _highLayer = AudioPlayer();
//
//   // Optional one-shots
//   AudioPlayer? _startClip;
//   AudioPlayer? _cutoffClip;
//
//   // Music (Spotify/local)
//   final AudioPlayer _musicPlayer = AudioPlayer();
//   bool _musicEnabled = false;
//
//   // Engine mix
//   double _engineVolume = 1.0;
//   double _musicVolume  = 0.5;
//
//   // Crossfade config
//   int crossfadeMs = 300;
//   int _fadeSteps = 6;
//
//   int _lastPct = 0;
//
//   /// Load pack with 3 looping layers + optional start/cutoff
//   Future<void> loadPack({
//     required String idlePath,
//     required String midPath,
//     required String highPath,
//     String? startPath,
//     String? cutoffPath,
//   }) async {
//     // Loops
//     await _idleLayer.setFilePath(idlePath);
//     await _midLayer.setFilePath(midPath);
//     await _highLayer.setFilePath(highPath);
//
//     for (final p in [_idleLayer, _midLayer, _highLayer]) {
//       await p.setLoopMode(LoopMode.one);
//       await p.setVolume(0);
//     }
//
//     // Optional clips
//     if (startPath != null) {
//       _startClip = AudioPlayer();
//       await _startClip!.setFilePath(startPath);
//     }
//     if (cutoffPath != null) {
//       _cutoffClip = AudioPlayer();
//       await _cutoffClip!.setFilePath(cutoffPath);
//     }
//   }
//
//   /// Play start clip then fade into idle
//   Future<void> playStart() async {
//     if (_startClip != null) {
//       await _startClip!.seek(Duration.zero);
//       await _startClip!.play();
//     }
//
//     if (!_idleLayer.playing) await _idleLayer.play();
//     if (!_midLayer.playing)  await _midLayer.play();
//     if (!_highLayer.playing) await _highLayer.play();
//
//     await _applyForPct(_lastPct);
//   }
//
//   /// Play cutoff clip + stop all loops
//   Future<void> playCutoff() async {
//     if (_cutoffClip != null) {
//       await _cutoffClip!.seek(Duration.zero);
//       await _cutoffClip!.play();
//     }
//     await stopAll();
//   }
//
//   /// Update engine sound based on throttle percentage
//   Future<void> updateThrottle(int pct) async {
//     _lastPct = pct.clamp(0, 100);
//     await _applyForPct(_lastPct);
//   }
//
//   /// Crossfade volumes based on throttle % (smooth revs)
//   Future<void> _applyForPct(int pct) async {
//     final t = pct / 100.0;
//
//     final useIdle = t < 0.33;
//     final useMid  = t >= 0.33 && t < 0.75;
//     final useHigh = t >= 0.75;
//
//     if (!_idleLayer.playing) await _idleLayer.play();
//     if (!_midLayer.playing)  await _midLayer.play();
//     if (!_highLayer.playing) await _highLayer.play();
//
//     await Future.wait([
//       _fadeVolume(_idleLayer, useIdle ? _engineVolume : 0.0),
//       _fadeVolume(_midLayer , useMid  ? _engineVolume : 0.0),
//       _fadeVolume(_highLayer, useHigh ? _engineVolume : 0.0),
//     ]);
//   }
//
//   /// Smooth volume fade
//   Future<void> _fadeVolume(AudioPlayer p, double target) async {
//     final from = p.volume;
//     if (_fadeSteps <= 1) {
//       await p.setVolume(target);
//       return;
//     }
//     final dt = Duration(milliseconds: (crossfadeMs / _fadeSteps).round());
//     for (var i = 1; i <= _fadeSteps; i++) {
//       final v = from + (target - from) * (i / _fadeSteps);
//       await p.setVolume(v.clamp(0.0, 1.0));
//       await Future.delayed(dt);
//     }
//   }
//
//   /// Adjust mix
//   void setMix({required bool enabled, required double engineVol, required double musicVol}) {
//     _musicEnabled = enabled;
//     _engineVolume = engineVol.clamp(0.0, 1.0);
//     _musicVolume  = musicVol.clamp(0.0, 1.0);
//     if (_musicEnabled) {
//       FlutterVolumeController.setVolume(_musicVolume);
//     }
//   }
//
//   /// Stop all loops
//   Future<void> stopAll() async {
//     await _idleLayer.stop();
//     await _midLayer.stop();
//     await _highLayer.stop();
//   }
//
//   /// Clean up
//   Future<void> dispose() async {
//     for (final p in [_idleLayer, _midLayer, _highLayer, _musicPlayer]) {
//       await p.dispose();
//     }
//     if (_startClip != null) await _startClip!.dispose();
//     if (_cutoffClip != null) await _cutoffClip!.dispose();
//   }
// }
//
// // // lib/services/audio_manager.dart
// // import 'package:flutter/cupertino.dart';
// // import 'package:flutter_volume_controller/flutter_volume_controller.dart';
// // import 'package:just_audio/just_audio.dart';
// //
// // enum ThrottleSegment { start, idle, gear1, gear2, gear3, cruise, cutoff }
// //
// // class AudioManager {
// //   final AudioPlayer _player = AudioPlayer();
// //   String _bank = 'default';
// //   String _file = 'exhaust.mp3';
// //   ThrottleSegment? _currentSeg;
// //
// //   AudioPlayer? _startClip;
// //   AudioPlayer? _gear1Clip;
// //   AudioPlayer? _gear2Clip;
// //   AudioPlayer? _gear3Clip;
// //   AudioPlayer? _cruiseClip;
// //   AudioPlayer? _cutoffClip;
// //
// //   int crossfadeMs = 300; // fade time in ms
// //   int _fadeSteps = 6;    // number of steps for fade
// //
// //   // NEW: allow using a file path instead of asset for single-master
// //   String? _filePathMaster;
// //
// //   static const Map<ThrottleSegment, List<int>> _bounds = {
// //     ThrottleSegment.start:  [0,     2500],
// //     ThrottleSegment.idle:   [2500,  4500],
// //     ThrottleSegment.gear1:  [4500,  6500],
// //     ThrottleSegment.gear2:  [6500,  8500],
// //     ThrottleSegment.gear3:  [8500, 10500],
// //     ThrottleSegment.cruise: [10500,12500],
// //     ThrottleSegment.cutoff: [12500,14500],
// //   };
// //
// //   final AudioPlayer _idleLayer = AudioPlayer();
// //   final AudioPlayer _midLayer  = AudioPlayer();
// //   final AudioPlayer _highLayer = AudioPlayer();
// //   bool _layeredMode = false;
// //   int _lastPct = 0;
// //
// //   final AudioPlayer _musicPlayer = AudioPlayer();
// //   bool   _musicEnabled = false;
// //   double _engineVolume = 1.0;
// //   double _musicVolume  = 0.5;
// //
// //   double duckThreshold    = 0.75;
// //   double duckVolumeFactor = 0.3;
// //   double crossfadeRate    = 0.5;
// //
// //   Future<void> loadBank(
// //       String bankId, {
// //         String masterFileName = 'exhaust.mp3',
// //       }) async {
// //     _layeredMode = false;
// //     _filePathMaster = null;             // reset override
// //     _bank = bankId;
// //     _file = masterFileName;
// //     _currentSeg = null;
// //   }
// //
// //   // Smooth volume fade helper
// //   Future<void> _fadeVolume(AudioPlayer p, double target) async {
// //     final from = p.volume;
// //     final steps = _fadeSteps;
// //     if (steps <= 1) {
// //       await p.setVolume(target.clamp(0.0, 1.0));
// //       return;
// //     }
// //     final dt = Duration(milliseconds: (crossfadeMs / steps).round());
// //     for (var i = 1; i <= steps; i++) {
// //       final v = from + (target - from) * (i / steps);
// //       await p.setVolume(v.clamp(0.0, 1.0));
// //       await Future.delayed(dt);
// //     }
// //   }
// //
// //   // NEW: single-master from FILE path (recording)
// //   Future<void> loadSingleMasterFile(String filePath) async {
// //     _layeredMode = false;
// //     _filePathMaster = filePath;         // use file instead of asset
// //     _currentSeg = null;
// //   }
// //
// //   // For segmented cut sounds
// //   Future<void> loadFullPack({
// //     required String startPath,
// //     required String idlePath,
// //     required String gear1Path,
// //     required String gear2Path,
// //     required String gear3Path,
// //     required String cruisePath,
// //     required String cutoffPath,
// //   }) async {
// //     _layeredMode = true;
// //     _filePathMaster = null;
// //
// //     // Base loop layers
// //     await _idleLayer.setFilePath(idlePath);
// //     await _midLayer.setFilePath(gear2Path); // treat as "mid"
// //     await _highLayer.setFilePath(gear3Path); // treat as "high"
// //
// //     await _idleLayer.setLoopMode(LoopMode.one);
// //     await _midLayer.setLoopMode(LoopMode.one);
// //     await _highLayer.setLoopMode(LoopMode.one);
// //
// //     await _idleLayer.setVolume(0);
// //     await _midLayer.setVolume(0);
// //     await _highLayer.setVolume(0);
// //
// //     // Non-looping clips
// //     _startClip  = AudioPlayer()..setFilePath(startPath);
// //     _gear1Clip  = AudioPlayer()..setFilePath(gear1Path);
// //     _cruiseClip = AudioPlayer()..setFilePath(cruisePath);
// //     _cutoffClip = AudioPlayer()..setFilePath(cutoffPath);
// //   }
// //
// //   Future<void> loadPackFromFiles({
// //     required String idlePath,
// //     required String midPath,
// //     required String highPath,
// //   }) async {
// //     _layeredMode = true;
// //     _filePathMaster = null;             // not used in layered mode
// //     await _idleLayer.setFilePath(idlePath);
// //     await _midLayer .setFilePath(midPath);
// //     await _highLayer.setFilePath(highPath);
// //
// //     await _idleLayer.setLoopMode(LoopMode.one);
// //     await _midLayer .setLoopMode(LoopMode.one);
// //     await _highLayer.setLoopMode(LoopMode.one);
// //
// //     await _idleLayer.setVolume(0);
// //     await _midLayer .setVolume(0);
// //     await _highLayer.setVolume(0);
// //
// //     _currentSeg = null;
// //   }
// //
// //   Future<void> playStart() async {
// //     if (_startClip != null) {
// //       await _startClip!.seek(Duration.zero);
// //       await _startClip!.play();
// //     }
// //     if (!_idleLayer.playing) await _idleLayer.play();
// //     if (!_midLayer.playing)  await _midLayer.play();
// //     if (!_highLayer.playing) await _highLayer.play();
// //     await _applyLayeredForPct(_lastPct);
// //   }
// //
// //   Future<void> playCutoff() async {
// //     if (_cutoffClip != null) {
// //       await _cutoffClip!.seek(Duration.zero);
// //       await _cutoffClip!.play();
// //     }
// //     await stopAll();
// //   }
// //
// //   void setMix({
// //     required bool enabled,
// //     required double engineVol,
// //     required double musicVol,
// //   }) {
// //     _musicEnabled = enabled;
// //     _engineVolume = engineVol.clamp(0.0, 1.0);
// //     _musicVolume  = musicVol.clamp(0.0, 1.0);
// //
// //     if (_layeredMode) {
// //       _idleLayer.setVolume(_engineVolume);
// //       _midLayer .setVolume(_engineVolume);
// //       _highLayer.setVolume(_engineVolume);
// //     } else {
// //       _player.setVolume(_engineVolume);
// //     }
// //     if (_musicEnabled) {
// //       FlutterVolumeController.setVolume(_musicVolume);
// //     }
// //   }
// //
// //   Future<void> loadMusicAsset(String assetPath) async {
// //     try { await _musicPlayer.setAsset(assetPath); } catch (e) { debugPrint('loadMusicAsset: $e'); }
// //   }
// //
// //   Future<void> updateThrottle(int pct) async {
// //     _lastPct = pct.clamp(0, 100);
// //
// //     if (_layeredMode) {
// //       await _applyLayeredForPct(_lastPct);
// //       return;
// //     }
// //
// //     final t = _lastPct / 100.0;
// //     final seg = (t == 0.0)
// //         ? ThrottleSegment.idle
// //         : (t < 0.3)
// //         ? ThrottleSegment.gear1
// //         : (t < 0.5)
// //         ? ThrottleSegment.gear2
// //         : (t < 0.7)
// //         ? ThrottleSegment.gear3
// //         : (t < 0.9)
// //         ? ThrottleSegment.cruise
// //         : ThrottleSegment.cutoff;
// //
// //     if (seg == _currentSeg) return;
// //     _currentSeg = seg;
// //
// //     final loop = seg != ThrottleSegment.start && seg != ThrottleSegment.cutoff;
// //     await _playSegment(seg, loop: loop);
// //   }
// //
// //   Future<void> _applyLayeredForPct(int pct) async {
// //     final t = pct / 100.0;
// //
// //     final useIdle   = t < 0.2;
// //     final useGear1  = t >= 0.2 && t < 0.4;      // one-shot
// //     final useMid    = t >= 0.4 && t < 0.6;      // loop layer
// //     final useHigh   = t >= 0.6 && t < 0.8;      // loop layer
// //     final useCruise = t >= 0.8;                 // one-shot
// //
// //     // Ensure loop layers are running
// //     if (!_idleLayer.playing) await _idleLayer.play();
// //     if (!_midLayer.playing)  await _midLayer.play();
// //     if (!_highLayer.playing) await _highLayer.play();
// //
// //     // Smooth fade between loop layers
// //     await Future.wait([
// //       _idleLayer.fadeTo(useIdle ? _engineVolume : 0.0, ms: crossfadeMs, steps: _fadeSteps),
// //       _midLayer .fadeTo(useMid  ? _engineVolume : 0.0, ms: crossfadeMs, steps: _fadeSteps),
// //       _highLayer.fadeTo(useHigh ? _engineVolume : 0.0, ms: crossfadeMs, steps: _fadeSteps),
// //     ]);
// //
// //     // One-shots (trigger only when entering zone)
// //     if (useGear1 && _gear1Clip != null && !_gear1Clip!.playing) {
// //       await _gear1Clip!.seek(Duration.zero);
// //       await _gear1Clip!.play();
// //     }
// //     if (useCruise && _cruiseClip != null && !_cruiseClip!.playing) {
// //       await _cruiseClip!.seek(Duration.zero);
// //       await _cruiseClip!.play();
// //     }
// //   }
// //
// //   Future<void> _playSegment(ThrottleSegment seg, {required bool loop}) async {
// //     final bounds = _bounds[seg]!;
// //     final child = (_filePathMaster != null)
// //         ? AudioSource.uri(Uri.file(_filePathMaster!))
// //         : AudioSource.asset('assets/sounds/$_bank/$_file');
// //
// //     final clip = ClippingAudioSource(
// //       start: Duration(milliseconds: bounds[0]),
// //       end:   Duration(milliseconds: bounds[1]),
// //       child: child,
// //     );
// //
// //     await _player.setAudioSource(clip);
// //     await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
// //     await _player.setVolume(_engineVolume);
// //     await _player.play();
// //   }
// //
// //   Future<void> dispose() async {
// //     await _player.dispose();
// //     await _idleLayer.dispose();
// //     await _midLayer.dispose();
// //     await _highLayer.dispose();
// //     await _musicPlayer.dispose();
// //   }
// //
// //   Future<void> stopAll() async {
// //     try {
// //       await _player.stop();
// //       await _idleLayer.stop();
// //       await _midLayer.stop();
// //       await _highLayer.stop();
// //     } catch (_) {}
// //   }
// // }
// //
// // // ───────────────────────────────────────────────
// // // Extension: Smooth fade for JustAudio volume
// // extension SmoothVolume on AudioPlayer {
// //   Future<void> fadeTo(double target, {int ms = 300, int steps = 6}) async {
// //     final from = volume;
// //     final dt = Duration(milliseconds: (ms / steps).round());
// //     for (var i = 1; i <= steps; i++) {
// //       final v = from + (target - from) * (i / steps);
// //       await setVolume(v.clamp(0.0, 1.0));
// //       await Future.delayed(dt);
// //     }
// //   }
// // }
