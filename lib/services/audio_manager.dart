import 'package:just_audio/just_audio.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:flutter/foundation.dart';

enum ThrottleSegment { start, idle, firstGear, secondGear, thirdGear, cruise, cutoff }

class AudioManager {
  final AudioPlayer _enginePlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  String _bankId = 'default';
  String? _localPath;
  String _fileName = 'exhaust_all.mp3';

  double _engineVolume = 1.0;
  double _pitchSens = 1.0;

  // Ducking + crossfade
  double duckThreshold = 0.75;
  double duckVolumeFactor = 0.3;
  double crossfadeRate = 0.5;

  static const Map<ThrottleSegment, List<int>> _bounds = {
    ThrottleSegment.start: [0, 2500],
    ThrottleSegment.idle: [2500, 4500],
    ThrottleSegment.firstGear: [4500, 6500],
    ThrottleSegment.secondGear: [6500, 8500],
    ThrottleSegment.thirdGear: [8500,10500],
    ThrottleSegment.cruise: [10500,12500],
    ThrottleSegment.cutoff: [12500,14500],
  };

  /// Load a new bank & file
  Future<void> loadBank(String bankId, {String? localPath, required String masterFileName}) async {
    _bankId = bankId;
    _localPath = localPath;
    _fileName = masterFileName;
  }

  Future<void> setEngineVolume(double v) async {
    _engineVolume = v;
    await _enginePlayer.setVolume(v);
  }

  void setPitchSensitivity(double s) => _pitchSens = s;

  UriAudioSource get _masterSource {
    if (_localPath != null) {
      return AudioSource.uri(Uri.file('$_localPath/$_fileName'));
    }
    return AudioSource.asset('assets/sounds/$_bankId/$_fileName');
  }

  Future<void> updateThrottle(int angle) async {
    final t = (angle/100).clamp(0,1);
    final seg = _mapSegment(t.toDouble());
    await _enginePlayer.play();
    // ducking
    final vol = t > duckThreshold ? duckVolumeFactor : 1.0;
    await FlutterVolumeController.setVolume(vol);

    final b = _bounds[seg]!;
    try {
      await _enginePlayer.setAudioSource(
        ClippingAudioSource(
          start: Duration(milliseconds: b[0]),
          end: Duration(milliseconds: b[1]),
          child: _masterSource,
        ),
      );
      await _enginePlayer.setVolume(_engineVolume);
      await _enginePlayer.setSpeed(0.8 + t*_pitchSens);

    } catch (e) {
      debugPrint('AudioManager error: $e');
    }
  }

  ThrottleSegment _mapSegment(double t) {
    if (t==0) return ThrottleSegment.start;
    if (t<0.1) return ThrottleSegment.idle;
    if (t<0.33) return ThrottleSegment.firstGear;
    if (t<0.66) return ThrottleSegment.secondGear;
    if (t<0.9) return ThrottleSegment.thirdGear;
    return ThrottleSegment.cutoff;
  }
  Future<void> loadMusicAsset(String path) => _musicPlayer.setAsset(path);
  Future<void> playMusic()    => _musicPlayer.play();
  Future<void> pauseMusic() => _musicPlayer.pause();

  Future<void> stopEngine() => _enginePlayer.stop();
  Future<void> dispose() => _enginePlayer.dispose();
}