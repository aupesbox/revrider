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
  BleConnectionStatus connState = BleConnectionStatus.disconnected;
  String? connectedDeviceName;

  // Sensor data
  int throttle = 0;
  int battery  = 100;

  // Music
  String? currentTrack;

  /// Request runtime permissions (Android) then start scan
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

  Future<void> disconnectDevice() async {
    await _ble.disconnect();
  }

  Future<void> _init() async {
    // 1️⃣ Audio engine
    try {
      await audio.init();
      await audio.play();
    } catch (e, st) {
      debugPrint('Audio init/play failed: $e\n$st');
    }

    // 2️⃣ BLE streams
    _ble.connectionStateStream.listen((status) {
      connState = status;

      // capture device name when discovered
      if (status == BleConnectionStatus.discovered) {
        connectedDeviceName = _ble.deviceName;
      }
      // clear on full disconnect
      if (status == BleConnectionStatus.disconnected) {
        connectedDeviceName = null;
      }

      notifyListeners();

      // auto-connect on discovery
      if (status == BleConnectionStatus.discovered) {
        _ble.connect().catchError((e) {
          debugPrint('BLE connect error: $e');
        });
      }
    }, onError: (e) => debugPrint('BLE status error: $e'));

    _ble.throttleStream.listen((value) {
      throttle = value.clamp(0, 100);
      audio.updateThrottle(throttle.toDouble());
      notifyListeners();
    }, onError: (e) => debugPrint('BLE throttle error: $e'));
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

  void setCurrentTrack(String? track) {
    currentTrack = track;
    notifyListeners();
  }

  @override
  void dispose() {
    _ble.dispose();
    audio.dispose();
    super.dispose();
  }
}
