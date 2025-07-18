// lib/providers/app_state.dart

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
    audio.loadBank('default', masterFileName: 'exhaust_all.mp3');

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
    // audio.setMix(
    //   enabled: enabled,
    //   engineVol: engineVolume,
    //   musicVol: musicVolume,
    // );
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
    //audio.duckThreshold = t;
    notifyListeners();
  }

  /// Adjust how much music volume is reduced when ducking
  void setDuckVolumeFactor(double f) {
    duckVolumeFactor = f;
    //audio.duckVolumeFactor = f;
    notifyListeners();
  }

  /// Adjust segment crossfade rate
  void setCrossfadeRate(double r) {
    crossfadeRate = r;
   // audio.crossfadeRate = r;
    notifyListeners();
  }

  /// Authenticate with Spotify and subscribe to "now playing" updates.
  Future<void> authenticateSpotify() async {
    spotifyAuthenticated = await SpotifyService.instance.authenticate(clientId: 'befe6120515e471fa6377ae9f24763b6', redirectUrl: 'revrider://callback');
    if (spotifyAuthenticated) {
      SpotifyService.instance.currentTrackStream.listen((trackName) {
        currentTrack = trackName;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ble.dispose();
    audio.dispose();
    super.dispose();
  }
}

// // lib/providers/app_state.dart
//
// import 'package:flutter/foundation.dart';
// import 'package:permission_handler/permission_handler.dart';
// import '../services/ble_manager.dart';
// import '../services/audio_manager.dart';
// import '../services/spotify_service.dart';
//
// /// Central application state: manages BLE, audio engine, and mix settings.
// class AppState extends ChangeNotifier {
//   final BleManager _ble;
//   final AudioManager audio;
//
//   // === BLE Connection State ===
//   BleConnectionStatus connectionStatus = BleConnectionStatus.disconnected;
//   bool get isConnected => connectionStatus == BleConnectionStatus.connected;
//
//   // === Throttle & Battery ===
//   int latestAngle = 0;
//   int batteryLevel = 100; // stub for future battery read
//
//   // === Music & Engine Mix Settings ===
//   bool musicEnabled = false;
//   double engineVolume = 1.0;
//   double musicVolume = 0.5;
//   double duckThreshold = 0.75;
//   double duckVolumeFactor = 0.3;
//   double crossfadeRate = 0.5;
//
//   bool spotifyAuthenticated = false;
//
//
//   AppState(this._ble) : audio = AudioManager() {
//     // Preload default exhaust bank
//     audio.loadBank('default', masterFileName: 'exhaust_all.mp3');
//
//     // BLE connection updates
//     _ble.connectionStateStream.listen((status) {
//       connectionStatus = status;
//       if (status == BleConnectionStatus.connected) {
//         audio.playStart();
//       } else if (status == BleConnectionStatus.disconnected) {
//         audio.playCutoff();
//       }
//       notifyListeners();
//     });
//
//     // BLE throttle updates
//     _ble.throttleStream.listen((angle) {
//       latestAngle = angle;
//       audio.updateThrottle(angle);
//       notifyListeners();
//     });
//   }
//   Future<void> authenticateSpotify() async {
//     spotifyAuthenticated = await SpotifyService.instance.authenticate();
//     notifyListeners();
//   }
//   /// Scan/connect to BLE device (requests permissions).
//   Future<void> connect() async {
//     final statuses = await [
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.locationWhenInUse,
//     ].request();
//     if (statuses.values.any((s) => s != PermissionStatus.granted)) return;
//     await _ble.connect();
//   }
//
//   /// Disconnect BLE and play cutoff.
//   Future<void> disconnect() async {
//     await _ble.disconnect();
//     audio.playCutoff();
//     notifyListeners();
//   }
//
//   /// Send calibration command to the device.
//   Future<void> calibrateThrottle() async {
//     await _ble.calibrate();
//     notifyListeners();
//   }
//
//   /// Enable/disable music and set volumes.
//   void setMusicMix({
//     required bool enabled,
//     required double engineVol,
//     required double musicVol,
//   }) {
//     musicEnabled = enabled;
//     engineVolume = engineVol;
//     musicVolume = musicVol;
//     audio.setMix(
//       enabled: enabled,
//       engineVol: engineVolume,
//       musicVol: musicVolume,
//     );
//     notifyListeners();
//   }
//
//   /// Adjust engine volume only.
//   void setEngineVolume(double vol) {
//     engineVolume = vol;
//     audio.setMix(
//       enabled: musicEnabled,
//       engineVol: engineVolume,
//       musicVol: musicVolume,
//     );
//     notifyListeners();
//   }
//
//   /// Adjust music volume only.
//   void setMusicVolume(double vol) {
//     musicVolume = vol;
//     audio.setMix(
//       enabled: musicEnabled,
//       engineVol: engineVolume,
//       musicVol: musicVolume,
//     );
//     notifyListeners();
//   }
//
//   /// Set the throttle % above which music ducks.
//   void setDuckingThreshold(double t) {
//     duckThreshold = t;
//     audio.duckThreshold = t;
//     notifyListeners();
//   }
//
//   /// Set how low music volume goes when ducking.
//   void setDuckVolumeFactor(double f) {
//     duckVolumeFactor = f;
//     audio.duckVolumeFactor = f;
//     notifyListeners();
//   }
//
//   /// Adjust crossfade rate between engine segments.
//   void setCrossfadeRate(double r) {
//     crossfadeRate = r;
//     audio.crossfadeRate = r;
//     notifyListeners();
//   }
//
//   @override
//   void dispose() {
//     _ble.dispose();
//     audio.dispose();
//     super.dispose();
//   }
// }
//
// // // lib/providers/app_state.dart
// //
// // import 'package:flutter/foundation.dart';
// // import 'package:permission_handler/permission_handler.dart';
// // import '../services/ble_manager.dart';
// // import '../services/audio_manager.dart';
// //
// // /// Central application state wiring BLE to audio and UI
// // class AppState extends ChangeNotifier {
// //   final BleManager _ble;
// //   final AudioManager audio = AudioManager();
// //
// //   // BLE connection status
// //   BleConnectionStatus _bleStatus = BleConnectionStatus.disconnected;
// //   BleConnectionStatus get connectionStatus => _bleStatus;
// //   bool get isConnected => _bleStatus == BleConnectionStatus.connected;
// //
// //   // Latest throttle and battery values
// //   int latestAngle = 0;
// //   int batteryLevel = 100; // stub for future battery characteristic
// //
// //   AppState(this._ble) {
// //     _init();
// //     // Preload default exhaust bank
// //     audio.loadBank('default', masterFileName: 'exhaust_all.mp3');
// //   }
// //
// //   void _init() {
// //     // Listen for BLE connection changes
// //     _ble.connectionStateStream.listen((status) {
// //       _bleStatus = status;
// //       if (status == BleConnectionStatus.connected) {
// //         audio.playStart();
// //       } else if (status == BleConnectionStatus.disconnected) {
// //         audio.playCutoff();
// //       }
// //       notifyListeners();
// //     });
// //
// //     // Listen for throttle updates
// //     _ble.throttleStream.listen((angle) {
// //       latestAngle = angle;
// //       audio.updateThrottle(angle);
// //       notifyListeners();
// //     });
// //   }
// //
// //   /// Initiate BLE scan & connect
// //   Future<void> connect() async {
// //     // Request permissions if needed
// //     final statuses = await [
// //       Permission.bluetoothScan,
// //       Permission.bluetoothConnect,
// //       Permission.locationWhenInUse,
// //     ].request();
// //
// //     if (statuses.values.any((s) => s != PermissionStatus.granted)) {
// //       return;
// //     }
// //     await _ble.connect();
// //   }
// //
// //   /// Disconnect BLE and stop engine
// //   Future<void> disconnect() async {
// //     await _ble.disconnect();
// //     audio.playCutoff();
// //     notifyListeners();
// //   }
// //
// //   @override
// //   void dispose() {
// //     _ble.dispose();
// //     audio.dispose();
// //     super.dispose();
// //   }
// // }
// //
// //
// // // // lib/providers/app_state.dart
// // //
// // // import 'dart:async';
// // // import 'package:flutter/foundation.dart';
// // // import 'package:permission_handler/permission_handler.dart';
// // //
// // // import '../services/ble_manager.dart';
// // // import '../services/audio_manager.dart';
// // // import '../services/spotify_service.dart';
// // //
// // // /// Represents a default local, royalty-free music track.
// // // class LocalTrack {
// // //   final String id;
// // //   final String name;
// // //   final String assetPath;
// // //
// // //   const LocalTrack({required this.id, required this.name, required this.assetPath});
// // // }
// // //
// // // class AppState extends ChangeNotifier {
// // //   // at top of AppState:
// // //   String selectedBankId = 'default';
// // //   String? _masterFileName = 'exhaust.mp3';
// // //   String? _localBankPath;
// // //
// // //   AppState(this._ble) {
// // //     _init();
// // //     // Initialize audio and default settings
// // //     audio.loadBank(selectedBankId, masterFileName: 'exhaust.mp3');
// // //     //audio.setEngineVolume();
// // //     // Load default local music
// // //     loadLocalMusic();
// // //   }
// // //
// // //   // Ducking & crossfade settings:
// // //   double duckThreshold    = 0.75;  // above 75% throttle
// // //   double duckVolumeFactor = 0.3;   // music ducked to 30%
// // //   double crossfadeRate    = 0.5;   // 0.0 = instant, 1.0 = full 1s fade
// // //
// // //   // Called by UI sliders:
// // //   void setDuckingThreshold(double t) {
// // //     duckThreshold = t;
// // //     audio.duckThreshold = t;
// // //     notifyListeners();
// // //   }
// // //   void setDuckVolumeFactor(double f) {
// // //     duckVolumeFactor = f;
// // //     audio.duckVolumeFactor = f;
// // //     notifyListeners();
// // //   }
// // //
// // //   final BleManager _ble;
// // //   final AudioManager audio = AudioManager();
// // //
// // //   // === Local Music ===
// // //   final List<LocalTrack> defaultTracks = const [
// // //      LocalTrack(id: 'demo',  name: 'Demo Song',    assetPath: 'assets/music/demo_song.mp3'),
// // //   ];
// // //   String selectedLocalTrackId = 'demo';
// // //
// // //   Future<void> loadLocalMusic() async {
// // //     final track = defaultTracks.firstWhere((t) => t.id == selectedLocalTrackId);
// // //     await audio.loadMusicAsset(track.assetPath);
// // //     if (musicEnabled) audio.playMusic();
// // //     notifyListeners();
// // //   }
// // //
// // //   void setSelectedLocalTrack(String id) {
// // //     selectedLocalTrackId = id;
// // //     loadLocalMusic();
// // //   }
// // //
// // //   // === Spotify Auth ===
// // //   bool spotifyAuthenticated = false;
// // //   Future<void> authenticateSpotify() async {
// // //     spotifyAuthenticated = await SpotifyService.instance.authenticate();
// // //     notifyListeners();
// // //   }
// // //
// // //   // === BLE Connection ===
// // //   BleConnectionStatus _bleStatus = BleConnectionStatus.disconnected;
// // //   BleConnectionStatus get connectionStatus => _bleStatus;
// // //   bool get isConnected => _bleStatus == BleConnectionStatus.connected;
// // //   String? connectedDeviceName;
// // //
// // //   Future<bool> connect() async {
// // //     final statuses = await [
// // //       Permission.bluetoothScan,
// // //       Permission.bluetoothConnect,
// // //       Permission.locationWhenInUse,
// // //     ].request();
// // //
// // //     if (statuses.values.any((s) => s != PermissionStatus.granted)) {
// // //       return false;
// // //     }
// // //     try {
// // //       await _ble.startScan();
// // //       await _ble.connect();
// // //       // Capture connected device name if BleManager exposes it
// // //       connectedDeviceName = _ble.deviceName;
// // //
// // //       return true;
// // //     } catch (_) {
// // //       return false;
// // //     }
// // //   }
// // //
// // //   Future<void> disconnect() async {
// // //     await _ble.disconnect();
// // //     await audio.stopEngine();
// // //     connectedDeviceName = null;
// // //     notifyListeners();
// // //   }
// // //
// // //   // === Throttle Calibration ===
// // //   Future<void> calibrateThrottle() async {
// // //     await _ble.calibrate();
// // //     notifyListeners();
// // //   }
// // //
// // //   // === Throttle & Battery ===
// // //   int latestAngle = 0;
// // //   int batteryLevel = 100;
// // //
// // //   // === Track Info ===
// // //   String get currentTrack =>
// // //       spotifyAuthenticated ? 'Spotify Track' : defaultTracks
// // //           .firstWhere((t) => t.id == selectedLocalTrackId)
// // //           .name;
// // //
// // //   // === Premium ===
// // //   bool isPremium = false;
// // //   void setPremium(bool v) {
// // //     isPremium = v;
// // //     notifyListeners();
// // //   }
// // //
// // //   void setSelectedBank(String bankId, {
// // //     String? localPath,
// // //     required String masterFileName
// // //   }) {
// // //     selectedBankId = bankId;
// // //     _localBankPath = localPath;
// // //     _masterFileName = masterFileName;
// // //     audio.loadBank(bankId,
// // //       localPath: localPath,
// // //       masterFileName: masterFileName,
// // //     );
// // //     notifyListeners();
// // //   }
// // //
// // //   // === Music Mix Settings ===
// // //   bool musicEnabled = false;
// // //   double engineVolume = 1.0;
// // //   double musicVolume = 0.5;
// // //
// // //   void setMusicMix({required bool enabled, required double engineVol, required double musicVol}) {
// // //     musicEnabled = enabled;
// // //     engineVolume = engineVol;
// // //     musicVolume = musicVol;
// // //     //audio.setMix(engineVolume, musicVolume, musicEnabled);
// // //     notifyListeners();
// // //   }
// // //
// // //   // === Initialization ===
// // //   void _init() {
// // //       _ble.connectionStateStream.listen((status) {
// // //         _bleStatus = status;
// // //         if (status == BleConnectionStatus.connected) {
// // //           audio.playStart();      // <-- This will load “start” then idle
// // //         } else if (status == BleConnectionStatus.disconnected) {
// // //           audio.playCutoff();
// // //           audio.stopEngine();
// // //
// // //         }
// // //         notifyListeners();
// // //       });
// // //    _ble.throttleStream.listen((angle) {
// // //       latestAngle = angle;
// // //       audio.updateThrottle(angle);
// // //       notifyListeners();
// // //     });
// // //
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     _ble.dispose();
// // //     audio.dispose();
// // //     super.dispose();
// // //   }
// // // }
