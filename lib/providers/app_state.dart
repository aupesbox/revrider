// lib/providers/app_state.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config.dart';
import '../services/ble_manager.dart';
import '../services/audio_manager.dart';

/// Manages throttle/battery state, drives audio engine, and manages BLE.
/// Audio always runs; BLE only when `!demoMode || testPremium`.
class AppState extends ChangeNotifier {
  AppState(this._ble) {
    _init();
  }

  final BleManager _ble;
  final AudioManager _audio = AudioManager();

  /// Current throttle 0–100
  int throttle = 0;

  /// Battery % from sensor
  int battery = 100;

  /// BLE connection state
  BleConnectionStatus connState = BleConnectionStatus.disconnected;

  /// Test‐only override for premium/demo BLE
  bool testPremium = false;

  /// Called by UI slider or BLE updates
  void setThrottle(int value) {
    throttle = value.clamp(0, 100);
    _audio.updateThrottle(throttle.toDouble());
    notifyListeners();
  }

  /// Request Android runtime permissions
  Future<void> _ensurePermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
    }
  }

  /// Manual connect action called from UI
  Future<void> connectDevice() async {
    // always ask permissions
    await _ensurePermissions();

    // Listen for BLE state updates
    _ble.connectionStatus.listen((status) {
      connState = status;
      notifyListeners();
    });

    // Listen for throttle & battery
    _ble.throttleStream.listen((value) => setThrottle(value));
    _ble.batteryStream.listen((value) {
      battery = value.clamp(0, 100);
      notifyListeners();
    });

    // Kick off scanning (which leads to connect)
    await _ble.startScan();
  }

  Future<void> _init() async {
    // 1️⃣ Audio always
    try {
      await _audio.init();
      await _audio.play();
    } catch (e, st) {
      debugPrint('Audio init/play failed: $e\n$st');
    }

    // 2️⃣ Auto‐connect if not pure demo
    if (!demoMode || testPremium) {
      connectDevice();
    }
  }

  @override
  void dispose() {
    // No explicit ble.connect() to cancel
    try {
      _ble.dispose();
    } catch (_) {}
    try {
      _audio.dispose();
    } catch (_) {}
    super.dispose();
  }
}
