// lib/services/audio_manager.dart

import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:flutter/foundation.dart';

enum ThrottleSegment { start, idle, firstGear, secondGear, thirdGear, cruise, cutoff }

class AudioManager {
  final AudioPlayer _enginePlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  String _bankId = "default";
  String? _localPath;
  String _fileName = "exhaust.mp3";

  final double _engineVolume = 1.0;
  final double _pitchSens = 1.0;

  // Ducking + crossfade
  double duckThreshold = 0.75;
  double duckVolumeFactor = 0.3;
  double crossfadeRate = 0.5;

  static const Map<ThrottleSegment, List<int>> _bounds = {
    ThrottleSegment.start: [0, 2500],
    ThrottleSegment.idle: [2500, 4500],
    ThrottleSegment.firstGear: [4500, 6500],
    ThrottleSegment.secondGear: [6500, 8500],
    ThrottleSegment.thirdGear: [8500, 10500],
    ThrottleSegment.cruise: [10500, 12500],
    ThrottleSegment.cutoff: [12500, 14500],
  };

  /// Load a new bank & master file name
  Future<void> loadBank(
      String bankId, {
        String? localPath,
        String masterFileName = 'exhaust.mp3',
      }) async {
    _bankId = bankId;
    _localPath = localPath;
    _fileName = masterFileName;
  }

  /// Map throttle % to a segment and play the clipped audio
  Future<void> updateThrottle(int angle) async {
    final t = (angle / 100).clamp(0.0, 1.0);
    final seg = _mapSegment(t);
    final bounds = _bounds[seg]!;

    // Determine master source: file if exists, otherwise bundled asset
    final filePath = (_localPath != null) ? '$_localPath/$_fileName' : null;
    UriAudioSource masterSource;
    if (filePath != null && File(filePath).existsSync()) {
      masterSource = AudioSource.uri(Uri.file(filePath));
    } else {
      final assetKey = 'assets/sounds/default/exhaust.mp3';//'assets/sounds/$_bankId/$_fileName';
      masterSource = AudioSource.asset(assetKey);
    }

    debugPrint('▶️ AudioManager: playing $seg from ${filePath ?? "asset"}');

    final clip = ClippingAudioSource(
      start: Duration(milliseconds: bounds[0]),
      end: Duration(milliseconds: bounds[1]),
      child: masterSource,
    );

    try {
      await _enginePlayer.stop();
      await _enginePlayer.setAudioSource(clip);
      await _enginePlayer.setLoopMode(LoopMode.one);
      await _enginePlayer.setVolume(_engineVolume);
      await _enginePlayer.setSpeed(0.8 + t * _pitchSens);
      await _enginePlayer.play();
    } catch (e) {
      debugPrint('AudioManager error: $e');
    }

    // Apply system volume ducking
    final sysVol = (t > duckThreshold) ? duckVolumeFactor : 1.0;
    await FlutterVolumeController.setVolume(sysVol);
  }

  ThrottleSegment _mapSegment(double t) {
    if (t == 0) return ThrottleSegment.start;
    if (t < 0.1) return ThrottleSegment.idle;
    if (t < 0.33) return ThrottleSegment.firstGear;
    if (t < 0.66) return ThrottleSegment.secondGear;
    if (t < 0.9) return ThrottleSegment.thirdGear;
    return ThrottleSegment.cutoff;
  }

  /// Play the "start" slice then transition to idle
  Future<void> playStart() async {
    await updateThrottle(0);
    final dur = Duration(milliseconds: _bounds[ThrottleSegment.start]![1]);
    Future.delayed(dur, () => updateThrottle(1));
  }

  /// Play the "cutoff" slice on disconnect
  Future<void> playCutoff() async {
    await updateThrottle(100);
  }

  // ─── Music API ─────────────────────────────────────
  Future<void> loadMusicAsset(String path) async {
    await _musicPlayer.setAsset(path);
  }

  Future<void> playMusic() async {
    await _musicPlayer.play();
  }

  Future<void> pauseMusic() async {
    await _musicPlayer.pause();
  }

  /// Stop engine playback
  Future<void> stopEngine() async {
    await _enginePlayer.stop();
  }

  Future<void> dispose() async {
    await _enginePlayer.dispose();
    await _musicPlayer.dispose();
  }
}

