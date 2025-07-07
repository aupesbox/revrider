// lib/providers/app_state.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config.dart';
import '../services/ble_manager.dart';
import '../services/audio_manager.dart';

class AppState extends ChangeNotifier {
  AppState(this._ble) {
    _init();
  }

  final BleManager _ble;

  /// Single, shared audio engine
  final AudioManager audio = AudioManager();

  bool _testPremium = false;
  bool get testPremium => _testPremium;
  set testPremium(bool v) {
    _testPremium = v;
    notifyListeners();
  }

  int throttle = 0;
  int battery  = 100;  // stub for now
  BleConnectionStatus connState = BleConnectionStatus.disconnected;

  /// Currently playing music track (filename)
  String? currentTrack;

  /// Call this whenever you load or start a new track
  void setCurrentTrack(String? track) {
    currentTrack = track;
    notifyListeners();
  }

  /// Request runtime permissions then start scanning
  Future<void> connectDevice() async {
    if (demoMode) return;
    if (Platform.isAndroid) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
    }
    await _ble.startScan();
  }

  Future<void> _init() async {
    // 1️⃣ Initialize & start audio once
    try {
      await audio.init();
      await audio.play();
    } catch (e, st) {
      debugPrint('Audio init/play failed: $e\n$st');
    }

    // 2️⃣ BLE: only if not in demo
    if (!demoMode) {
      _ble.connectionStateStream.listen((status) {
        connState = status;
        notifyListeners();
        if (status == BleConnectionStatus.discovered) {
          _ble.connect().catchError((e) {
            debugPrint('BLE connect error: $e');
          });
        }
      }, onError: (e) {
        debugPrint('BLE connectionStateStream error: $e');
      });

      _ble.throttleStream.listen((value) {
        setThrottle(value);
      }, onError: (e) {
        debugPrint('BLE throttleStream error: $e');
      });

      await _ble.startScan().catchError((e) {
        debugPrint('BLE startScan error: $e');
      });
    }
  }

  void setThrottle(int value) {
    throttle = value.clamp(0, 100);
    audio.updateThrottle(throttle.toDouble());
    notifyListeners();
  }

  Future<bool> calibrateThrottle(BuildContext context) async {
    try {
      await _ble.calibrateZero();
      return true;
    } catch (e) {
      debugPrint('Calibration failed: $e');
      return false;
    }
  }

  @override
  void dispose() {
    if (!demoMode) _ble.dispose();
    audio.dispose();
    super.dispose();
  }
}
