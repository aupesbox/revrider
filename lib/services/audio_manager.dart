// lib/services/audio_manager.dart

import 'package:just_audio/just_audio.dart';

/// AudioManager for RevRider MVP: slices a master exhaust file into segments and plays them.
enum ThrottleSegment { start, idle, gear1, gear2, gear3, cruise, cutoff }

class AudioManager {
  final AudioPlayer _player = AudioPlayer();

  String _bank = 'default';
  String _file = 'exhaust.mp3';

  // Millisecond bounds for each segment
  static const Map<ThrottleSegment, List<int>> _bounds = {
    ThrottleSegment.start:  [0,    2500],
    ThrottleSegment.idle:   [2500, 4500],
    ThrottleSegment.gear1:  [4500, 6500],
    ThrottleSegment.gear2:  [6500, 8500],
    ThrottleSegment.gear3:  [8500,10500],
    ThrottleSegment.cruise: [10500,12500],
    ThrottleSegment.cutoff:[12500,14500],
  };

  ThrottleSegment? _currentSeg;

  /// Load a new bank and master file name (asset path)
  Future<void> loadBank(
      String bankId, {
        String masterFileName = 'exhaust.mp3',
      }) async {
    _bank = bankId;
    _file = masterFileName;
  }

  /// Play the startup slice once, then transition to idle
  Future<void> playStart() async {
    _currentSeg = ThrottleSegment.start;
    await _playSegment(ThrottleSegment.start, loop: false);
    final dur = Duration(milliseconds: _bounds[ThrottleSegment.start]![1]);
    Future.delayed(dur, () => updateThrottle(0));
  }

  /// Play the cutoff slice once
  Future<void> playCutoff() async {
    _currentSeg = ThrottleSegment.cutoff;
    await _playSegment(ThrottleSegment.cutoff, loop: false);
  }

  /// Update throttle 0–100: picks segment and plays it if changed
  Future<void> updateThrottle(int pct) async {
    final t = pct / 100.0;
    final seg = t == 0.0
        ? ThrottleSegment.idle
        : t < 0.3
        ? ThrottleSegment.gear1
        : t < 0.5
        ? ThrottleSegment.gear2
        : t < 0.7
        ? ThrottleSegment.gear3
        : t < 0.9
        ? ThrottleSegment.cruise
        : ThrottleSegment.cutoff;

    if (seg == _currentSeg) return;
    _currentSeg = seg;
    final loop = seg != ThrottleSegment.start && seg != ThrottleSegment.cutoff;
    await _playSegment(seg, loop: loop);
  }

  Future<void> _playSegment(ThrottleSegment seg, {required bool loop}) async {
    final bounds = _bounds[seg]!;
    final clip = ClippingAudioSource(
      start: Duration(milliseconds: bounds[0]),
      end: Duration(milliseconds: bounds[1]),
      child: AudioSource.asset('assets/sounds/$_bank/$_file'),
    );
    await _player.setAudioSource(clip);
    await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
    await _player.play();
  }

  Future<void> dispose() => _player.dispose();
}

// // lib/services/audio_manager.dart
//
// import 'package:flutter_volume_controller/flutter_volume_controller.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:flutter/foundation.dart';
//
// /// Segments of the exhaust master file
// enum ThrottleSegment { start, idle, firstGear, secondGear, thirdGear, cruise, cutoff }
//
// class AudioManager {
//   final AudioPlayer _enginePlayer = AudioPlayer();
//
//   // Current sound bank and file\ n  String _bankId       = 'default';
//   String _fileName     = 'exhaust.mp3';
//   String? _localPath;
//   String _bankId       = 'default';
//   // Mix settings
//   bool   _musicEnabled  = false;
//   double _engineVolume  = 1.0;
//   double _musicVolume   = 0.5;
//
//   // Ducking & crossfade thresholds
//   double duckThreshold    = 0.75;
//   double duckVolumeFactor = 0.3;
//   double crossfadeRate    = 0.5;
//
//   /// Millisecond boundaries for each segment
//   static const Map<ThrottleSegment, List<int>> _bounds = {
//     ThrottleSegment.start:     [0,    2500],
//     ThrottleSegment.idle:      [2500, 4500],
//     ThrottleSegment.firstGear: [4500, 6500],
//     ThrottleSegment.secondGear:[6500, 8500],
//     ThrottleSegment.thirdGear: [8500,10500],
//     ThrottleSegment.cruise:    [10500,12500],
//     ThrottleSegment.cutoff:    [12500,14500],
//   };
//
//   /// Load a new sound bank and master file
//   Future<void> loadBank(
//       String bankId, {
//         String? localPath,
//         String masterFileName = 'exhaust.mp3',
//       }) async {
//     _bankId    = bankId;
//     _localPath = localPath;
//     _fileName  = masterFileName;
//   }
//
//   /// Configure volumes and enable/disable music channel
//   void setMix({
//     required bool enabled,
//     required double engineVol,
//     required double musicVol,
//   }) {
//     _musicEnabled = enabled;
//     _engineVolume = engineVol.clamp(0.0, 1.0);
//     _musicVolume  = musicVol.clamp(0.0, 1.0);
//
//     // Engine channel volume
//     _enginePlayer.setVolume(_engineVolume);
//
//     // Music channel uses system volume
//     if (_musicEnabled) {
//       FlutterVolumeController.setVolume(_musicVolume);
//     }
//   }
//
//   /// Update throttle: map percentage to segment and play that segment
//   Future<void> updateThrottle(int pct) async {
//     final t   = (pct / 100).clamp(0.0, 1.0);
//     final seg = _mapSegment(t);
//     await _playSegment(seg, loop: true);
//
//     // Apply ducking: reduce system volume when throttle above threshold
//     final sysVol = t > duckThreshold ? duckVolumeFactor : 1.0;
//     await FlutterVolumeController.setVolume(sysVol);
//   }
//
//   ThrottleSegment _mapSegment(double t) {
//     if (t == 0.0) return ThrottleSegment.idle;
//     if (t < 0.2) return ThrottleSegment.firstGear;
//     if (t < 0.4) return ThrottleSegment.secondGear;
//     if (t < 0.6) return ThrottleSegment.thirdGear;
//     if (t < 0.8) return ThrottleSegment.cruise;
//     return ThrottleSegment.cutoff;
//   }
//
//   Future<void> _playSegment(ThrottleSegment seg, {required bool loop}) async {
//     final bounds = _bounds[seg]!;
//     final source = ClippingAudioSource(
//       start: Duration(milliseconds: bounds[0]),
//       end:   Duration(milliseconds: bounds[1]),
//       child: _localPath != null
//           ? AudioSource.uri(Uri.file('$_localPath/$_fileName'))
//           : AudioSource.asset('assets/sounds/$_bankId/$_fileName'),
//     );
//     try {
//       await _enginePlayer.stop();
//       await _enginePlayer.setAudioSource(source);
//       await _enginePlayer.setLoopMode(loop ? LoopMode.one : LoopMode.off);
//       await _enginePlayer.play();
//     } catch (e) {
//       debugPrint('AudioManager error playing segment $seg: $e');
//     }
//   }
//
//   /// Play the "start" slice then transition to idle
//   Future<void> playStart() async {
//     await _playSegment(ThrottleSegment.start, loop: false);
//     final dur = Duration(milliseconds: _bounds[ThrottleSegment.start]![1]);
//     Future.delayed(dur, () => updateThrottle(1));
//   }
//
//   /// Play the "cutoff" slice on disconnect
//   Future<void> playCutoff() async {
//     await _playSegment(ThrottleSegment.cutoff, loop: false);
//   }
//
//   /// Release resources
//   Future<void> dispose() async {
//     await _enginePlayer.dispose();
//   }
// }
