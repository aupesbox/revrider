// lib/providers/app_state.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/ble_manager.dart';
import '../services/audio_manager.dart';

class AppState extends ChangeNotifier {
  AppState(this._ble) { _init(); }

  final BleManager _ble;
  final AudioManager audio = AudioManager();

  bool isPremium = false;
  void setPremium(bool v) { isPremium = v; notifyListeners(); }

  int throttle = 0, battery = 100;
  BleConnectionStatus connState = BleConnectionStatus.disconnected;
  String? currentTrack;

  Future<void> connectDevice() async {
    if (Platform.isAndroid) {
      await [ Permission.bluetoothScan, Permission.bluetoothConnect, Permission.locationWhenInUse ]
          .request();
    }
    // start scan & connection sequence
    await _ble.startScan();
  }

  Future<void> disconnectDevice() async {
    await _ble.disconnect();
  }

  Future<void> _init() async {
    // 1️⃣ Audio preload
    await audio.init();

    // 2️⃣ BLE state handling
    _ble.connectionStateStream.listen((status) {
      connState = status;
      notifyListeners();

      if (status == BleConnectionStatus.connected) {
        // ❶ play the “start” sound once…
        audio.playStart();
      } else if (status == BleConnectionStatus.disconnected) {
        // optionally stop/pause audio loops?
      }
    });

    // 3️⃣ Throttle updates
    _ble.throttleStream.listen((val) {
      throttle = val.clamp(0,100);
      audio.updateThrottle(throttle.toDouble());
      notifyListeners();
    });

    // 4️⃣ Begin scanning in production mode
    await connectDevice();
  }

  Future<bool> calibrateThrottle() async {
    return await _ble.calibrateZero().then((_) => true).catchError((_) => false);
  }

  void setCurrentTrack(String? t) {
    currentTrack = t;
    notifyListeners();
  }

  @override
  void dispose() {
    _ble.dispose();
    audio.dispose();
    super.dispose();
  }
}
