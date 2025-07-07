// lib/providers/app_state.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config.dart';
import '../services/ble_manager.dart';
import '../services/audio_manager.dart';

/// Manages throttle, battery, BLE, test-premium toggle, and audio.
class AppState extends ChangeNotifier {
  AppState(this._ble) {
    _init();
  }

  final BleManager _ble;
  final AudioManager _audio = AudioManager();

  // —— NEW: developer toggle for Premium features
  bool _testPremium = false;
  bool get testPremium => _testPremium;
  set testPremium(bool v) {
    _testPremium = v;
    notifyListeners();
  }

  // —— EXPOSED STATE
  int throttle = 0;
  int battery  = 100; // stub for now
  BleConnectionStatus connState = BleConnectionStatus.disconnected;

  /// Called from HomeScreen’s “Connect Sensor” button
  Future<void> connectDevice() async {
    if (!demoMode) {
      try {
        await _ble.startScan();
      } catch (e) {
        debugPrint('connectDevice error: $e');
      }
    }
  }

  /// Whether to use BLE (demoMode=false) or the on-screen slider
  Future<void> _ensurePermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
    }
  }

  Future<void> _init() async {
    // 1️⃣ Audio always on
    try {
      await _audio.init();
      await _audio.play();
    } catch (e, st) {
      debugPrint('Audio init/play failed: $e\n$st');
    }

    // 2️⃣ BLE only if not in demoMode
    if (!demoMode) {
      try {
        await _ensurePermissions();

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
      } catch (e, st) {
        debugPrint('BLE init failed: $e\n$st');
      }
    }
  }

  /// Drive audio + notify
  void setThrottle(int value) {
    throttle = value.clamp(0, 100);
    _audio.updateThrottle(throttle.toDouble());
    notifyListeners();
  }

  /// Calibration (unchanged)
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
    _audio.dispose();
    super.dispose();
  }
}
