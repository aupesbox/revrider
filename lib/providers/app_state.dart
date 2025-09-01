// lib/providers/app_state.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ble_manager.dart';
import '../services/audio_manager.dart';
import '../services/spotify_service.dart';

/// Central application state: manages BLE, audio engine, Spotify, and mix settings.
class AppState extends ChangeNotifier {
  final BleManager _ble;
  final AudioManager audio;

  // === BLE Connection ===
  BleConnectionStatus connectionStatus = BleConnectionStatus.disconnected;
  bool get isConnected => connectionStatus == BleConnectionStatus.connected;

  // === Throttle & Battery ===
  int latestAngle   = 0;
  int batteryLevel  = 100;

  // === Music & Mix Settings ===
  bool  musicEnabled    = false;
  double engineVolume   = 1.0;
  double musicVolume    = 0.5;
  double duckThreshold  = 0.75;
  double duckVolumeFactor = 0.3;
  double crossfadeRate  = 0.5;

  // === Spotify Playback ===
  bool   spotifyAuthenticated = false;
  String? currentTrack;

  AppState(this._ble)
      : audio = AudioManager() {
    // Preload default exhaust bank
    audio.loadBank('default', masterFileName: 'exhaust.mp3');

    // BLE connect/disconnect
    _ble.connectionStateStream.listen((status) {
      connectionStatus = status;
      if (status == BleConnectionStatus.connected) {
        audio.playStart();
      } else if (status == BleConnectionStatus.disconnected) {
        audio.playCutoff();
      }
      notifyListeners();
    });

    // BLE throttle updates
    _ble.throttleStream.listen((angle) {
      latestAngle = angle;
      audio.updateThrottle(angle);
      notifyListeners();
    });

  }
  void disconnectSpotify() {
    spotifyAuthenticated = false;
    currentTrack = null;
    notifyListeners();
  }

  /// Scan & connect to the BLE sensor (with permissions)
  Future<void> connect() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    if (statuses.values.any((s) => s != PermissionStatus.granted)) return;
    await _ble.connect();
  }

  /// Disconnect BLE and play cutoff
  Future<void> disconnect() async {
    await _ble.disconnect();
    audio.playCutoff();
    notifyListeners();
  }

  /// Send calibration command
  Future<void> calibrateThrottle() async {
    await _ble.calibrate();
    notifyListeners();
  }

  /// Enable/disable music channel and adjust volumes
  void setMusicMix({
    required bool enabled,
    required double engineVol,
    required double musicVol,
  }) {
    musicEnabled = enabled;
    engineVolume = engineVol;
    musicVolume  = musicVol;
    audio.setMix(
      enabled: enabled,
      engineVol: engineVolume,
      musicVol: musicVolume,
    );
    notifyListeners();
  }

  /// Set engine volume only
  void setEngineVolume(double vol) {
    engineVolume = vol;
    // audio.setMix(
    //   enabled: musicEnabled,
    //   engineVol: engineVolume,
    //   musicVol: musicVolume,
    // );
    notifyListeners();
  }

  /// Set music volume only
  void setMusicVolume(double vol) {
    musicVolume = vol;
    // audio.setMix(
    //   enabled: musicEnabled,
    //   engineVol: engineVolume,
    //   musicVol: musicVolume,
    // );
    notifyListeners();
  }

  /// Adjust throttle-percent threshold above which music ducks
  void setDuckingThreshold(double t) {
    duckThreshold = t;
    audio.duckThreshold = t;
    notifyListeners();
  }

  /// Adjust how much music volume is reduced when ducking
  void setDuckVolumeFactor(double f) {
    duckVolumeFactor = f;
    audio.duckVolumeFactor = f;
    notifyListeners();
  }

  /// Adjust segment crossfade rate
  void setCrossfadeRate(double r) {
    crossfadeRate = r;
    audio.crossfadeRate = r;
    notifyListeners();
  }

  /// Authenticate with Spotify and subscribe to "now playing" updates.
  StreamSubscription? _trackSub;

  Future<bool> authenticateSpotify() async {
    spotifyAuthenticated = await SpotifyService.instance.authenticate(
      clientId: 'befe6120515e471fa6377ae9f24763b6',
      redirectUrl: 'rydem://auth',
    );

    if (spotifyAuthenticated) {
      // Cancel previous if any
      _trackSub?.cancel();
      _trackSub = SpotifyService.instance.currentTrackStream.listen((trackName) {
        currentTrack = trackName;
        notifyListeners();
      });
    }

    notifyListeners();
    return spotifyAuthenticated;
  }



  @override
  void dispose() {
    _ble.dispose();
    audio.dispose();
    super.dispose();
  }
  final List<LocalTrack> defaultTracks = [
    const LocalTrack(id: 'road',  name: 'Ambient Road', assetPath: 'assets/music/road.mp3'),
    const LocalTrack(id: 'synth', name: 'Synth Drift',   assetPath: 'assets/music/synth.mp3'),
  ];
  String selectedLocalTrackId = 'road';

  //get spotifyService => null;
  SpotifyService get spotifyService => SpotifyService.instance;

  void setSelectedLocalTrack(String id) {
    selectedLocalTrackId = id;
    audio.loadMusicAsset(
        defaultTracks.firstWhere((t) => t.id == id).assetPath
    );
    notifyListeners();
  }

}
/// Represents a default local, royalty-free music track.
class LocalTrack {
  final String id;
  final String name;
  final String assetPath;

  const LocalTrack({required this.id, required this.name, required this.assetPath});


}
