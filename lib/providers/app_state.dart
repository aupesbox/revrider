import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/ble_manager.dart';
import '../services/audio_manager.dart';

class AppState extends ChangeNotifier {
  AppState(this._ble) {
    _init();
  }

  final BleManager _ble;
  final AudioManager audio = AudioManager();

  // Premium flag
  bool isPremium = false;
  void setPremium(bool v) {
    isPremium = v;
    notifyListeners();
  }

  // Connection & device info
  BleConnectionStatus connState        = BleConnectionStatus.disconnected;
  String?               connectedDeviceName;

  // Sensor data
  int throttle = 0;
  int battery  = 100;  // ← placeholder until you wire up a real battery characteristic

  // Music
  String? currentTrack;

  /// Called by “Connect Sensor” button
  Future<void> connectDevice() async {
    if (Platform.isAndroid) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
    }
    await _ble.startScan();
  }

  /// Called by “Disconnect” button
  Future<void> disconnectDevice() async {
    await _ble.disconnect();
    audio.playCutoff();
    setThrottle(0);
  }

  Future<void> _init() async {
    // 1️⃣ Preload engine sounds (don’t start yet)
    try {
      await audio.init();
    } catch (e, st) {
      debugPrint('Audio init failed: $e\n$st');
    }

    // 2️⃣ BLE connection updates
    _ble.connectionStateStream.listen((status) {
      connState = status;

      if (status == BleConnectionStatus.discovered) {
        connectedDeviceName = _ble.deviceName;
      }
      if (status == BleConnectionStatus.disconnected) {
        connectedDeviceName = null;
      }

      // play start/cutoff at transitions
      if (status == BleConnectionStatus.connected) {
        audio.playStart();
      } else if (status == BleConnectionStatus.disconnected) {
        audio.playCutoff();
        setThrottle(0);
      }

      notifyListeners();

      // auto-connect once discovered
      if (status == BleConnectionStatus.discovered) {
        _ble.connect().catchError((e) {
          debugPrint('BLE connect error: $e');
        });
      }
    }, onError: (e) => debugPrint('BLE status error: $e'));

    // 3️⃣ Throttle value updates (only when connected)
    _ble.throttleStream.listen((value) {
      if (connState == BleConnectionStatus.connected) {
        setThrottle(value);
      }
    }, onError: (e) => debugPrint('BLE throttle error: $e'));
  }

  void setThrottle(int v) {
    throttle = v.clamp(0, 100);
    audio.updateThrottle(throttle.toDouble());
    notifyListeners();
  }

  Future<bool> calibrateThrottle() async {
    try {
      await _ble.calibrateZero();
      return true;
    } catch (e) {
      debugPrint('Calibration failed: $e');
      return false;
    }
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
