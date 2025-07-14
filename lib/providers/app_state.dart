// lib/providers/app_state.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:revrider/providers/sound_bank_provider.dart';

import '../services/ble_manager.dart';
import '../services/audio_manager.dart';
import '../services/spotify_service.dart';
import '../models/sound_bank.dart';

/// Represents a default local, royalty-free music track.
class LocalTrack {
  final String id;
  final String name;
  final String assetPath;

  const LocalTrack({required this.id, required this.name, required this.assetPath});
}

class AppState extends ChangeNotifier {
  // at top of AppState:
  String selectedBankId = 'default';
  String? _masterFileName = 'exhaust_all.mp3';
  String? _localBankPath;

  AppState(this._ble) {
    _init();
    // Initialize audio and default settings
    audio.loadBank(selectedBankId, masterFileName: '');
    //audio.setEngineVolume();

    // Load default local music
    loadLocalMusic();
  }

  // Ducking & crossfade settings:
  double duckThreshold    = 0.75;  // above 75% throttle
  double duckVolumeFactor = 0.3;   // music ducked to 30%
  double crossfadeRate    = 0.5;   // 0.0 = instant, 1.0 = full 1s fade

  // Called by UI sliders:
  void setDuckingThreshold(double t) {
    duckThreshold = t;
    audio.duckThreshold = t;
    notifyListeners();
  }
  void setDuckVolumeFactor(double f) {
    duckVolumeFactor = f;
    audio.duckVolumeFactor = f;
    notifyListeners();
  }

  final BleManager _ble;
  final AudioManager audio = AudioManager();

  // === Local Music ===
  final List<LocalTrack> defaultTracks = const [
     LocalTrack(id: 'demo',  name: 'Demo Song',    assetPath: 'assets/music/demo_song.mp3'),
  ];
  String selectedLocalTrackId = 'demo';

  Future<void> loadLocalMusic() async {
    final track = defaultTracks.firstWhere((t) => t.id == selectedLocalTrackId);
    await audio.loadMusicAsset(track.assetPath);
    if (musicEnabled) audio.playMusic();
    notifyListeners();
  }

  void setSelectedLocalTrack(String id) {
    selectedLocalTrackId = id;
    loadLocalMusic();
  }

  // === Spotify Auth ===
  bool spotifyAuthenticated = false;
  Future<void> authenticateSpotify() async {
    spotifyAuthenticated = await SpotifyService.instance.authenticate();
    notifyListeners();
  }

  // === BLE Connection ===
  BleConnectionStatus _bleStatus = BleConnectionStatus.disconnected;
  BleConnectionStatus get connectionStatus => _bleStatus;
  bool get isConnected => _bleStatus == BleConnectionStatus.connected;
  String? connectedDeviceName;

  Future<bool> connect() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    if (statuses.values.any((s) => s != PermissionStatus.granted)) {
      return false;
    }
    try {
      await _ble.startScan();
      await _ble.connect();
      // Capture connected device name if BleManager exposes it
      connectedDeviceName = _ble.deviceName;

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> disconnect() async {
    await _ble.disconnect();
    await audio.stopEngine();
    connectedDeviceName = null;
    notifyListeners();
  }

  // === Throttle Calibration ===
  Future<void> calibrateThrottle() async {
    await _ble.calibrate();
    notifyListeners();
  }

  // === Throttle & Battery ===
  int latestAngle = 0;
  int batteryLevel = 100;

  // === Track Info ===
  String get currentTrack =>
      spotifyAuthenticated ? 'Spotify Track' : defaultTracks
          .firstWhere((t) => t.id == selectedLocalTrackId)
          .name;

  // === Premium ===
  bool isPremium = false;
  void setPremium(bool v) {
    isPremium = v;
    notifyListeners();
  }

  void setSelectedBank(String bankId, {
    String? localPath,
    required String masterFileName
  }) {
    selectedBankId = bankId;
    _localBankPath = localPath;
    _masterFileName = masterFileName;
    audio.loadBank(bankId,
      localPath: localPath,
      masterFileName: masterFileName,
    );
    notifyListeners();
  }

  // === Music Mix Settings ===
  bool musicEnabled = false;
  double engineVolume = 1.0;
  double musicVolume = 0.5;

  void setMusicMix({required bool enabled, required double engineVol, required double musicVol}) {
    musicEnabled = enabled;
    engineVolume = engineVol;
    musicVolume = musicVol;
    //audio.setMix(engineVolume, musicVolume, musicEnabled);
    notifyListeners();
  }

  // === Initialization ===
  void _init() {
    _ble.connectionStateStream.listen((status) {
      _bleStatus = status;
      notifyListeners();
    });
    _ble.throttleStream.listen((angle) {
      latestAngle = angle;
      audio.updateThrottle(angle);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ble.dispose();
    audio.dispose();
    super.dispose();
  }
}
