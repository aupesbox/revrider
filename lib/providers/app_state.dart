// lib/providers/app_state.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config.dart';
import '../services/ble_manager.dart';
import '../services/audio_manager.dart';

/// Drives the audio engine and (optionally) BLE; demoMode toggles BLE.
class AppState extends ChangeNotifier {
  AppState(this._ble) {
    _init();
  }

  final BleManager _ble;
  final AudioManager _audio = AudioManager();

  int throttle = 0;
  int battery  = 100;
  BleConnectionStatus connState = BleConnectionStatus.disconnected;

  /// HomeScreen slider or BLE updates call this
  void setThrottle(int value) {
    throttle = value.clamp(0, 100);
    _audio.updateThrottle(throttle.toDouble());
    notifyListeners();
  }

  /// Request Android runtime permissions
  Future<void> _ensurePermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      statuses.forEach((perm, status) {
        debugPrint('Permission $perm: $status');
      });
    }
  }

  Future<void> _init() async {
    // 1️⃣ Always start the audio loops
    try {
      await _audio.init();
      await _audio.play();
    } catch (e, st) {
      debugPrint('Audio init/play failed: $e\n$st');
    }

    // 2️⃣ Only start BLE when demoMode is off
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
          debugPrint('BLE status error: $e');
        });

        _ble.throttleStream.listen((value) {
          setThrottle(value);
        }, onError: (e) {
          debugPrint('BLE throttle error: $e');
        });

        _ble.batteryStream.listen((value) {
          battery = value.clamp(0, 100);
          notifyListeners();
        }, onError: (e) {
          debugPrint('BLE battery error: $e');
        });

        await _ble.startScan().catchError((e) {
          debugPrint('BLE scan error: $e');
        });
      } catch (e, st) {
        debugPrint('BLE init failed: $e\n$st');
      }
    }
  }
// lib/providers/app_state.dart

  /// Add this inside your AppState class, below _init() and above dispose():

  /// Manually trigger BLE permission request and scanning/connection.
  Future<void> connectDevice() async {
    if (demoMode) return; // skip in demo

    try {
      // 1) Ask for permissions
      await _ensurePermissions();

      // 2) Start listening to BLE updates (if not already)
      //    You can optionally move these subscriptions here
      _ble.connectionStateStream.listen((status) {
        connState = status;
        notifyListeners();
        if (status == BleConnectionStatus.discovered) {
          _ble.connect().catchError((e) {
            debugPrint('BLE connect error: $e');
          });
        }
      }, onError: (e) {
        debugPrint('BLE status error: $e');
      });
      _ble.throttleStream.listen(setThrottle, onError: (e) {
        debugPrint('BLE throttle error: $e');
      });
      _ble.batteryStream.listen((value) {
        battery = value.clamp(0, 100);
        notifyListeners();
      }, onError: (e) {
        debugPrint('BLE battery error: $e');
      });

      // 3) Kick off scanning
      await _ble.startScan().catchError((e) {
        debugPrint('BLE scan error: $e');
      });
    } catch (e, st) {
      debugPrint('connectDevice failed: $e\n$st');
    }
  }

  @override
  void dispose() {
    if (!demoMode) {
      try {
        _ble.dispose();
      } catch (e) {
        debugPrint('BLE dispose error: $e');
      }
    }
    _audio.dispose();
    super.dispose();
  }
}
