// lib/services/ble_manager.dart

import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Connection states for BLE UI
enum BleConnectionStatus {
  disconnected,
  scanning,
  discovered,
  connecting,
  connected,
}

class BleManager {
  final _ble = FlutterReactiveBle();

  // Public streams
  Stream<BleConnectionStatus> get connectionStatus => _connCtrl.stream;
  Stream<int>               get throttleStream    => _throttleCtrl.stream;
  Stream<int>               get batteryStream     => _batteryCtrl.stream;

  // Internal controllers
  final _connCtrl     = StreamController<BleConnectionStatus>.broadcast();
  final _throttleCtrl = StreamController<int>.broadcast();
  final _batteryCtrl  = StreamController<int>.broadcast();

  StreamSubscription<DiscoveredDevice>?      _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>?             _throttleSub;
  StreamSubscription<List<int>>?             _batterySub;

  String? _deviceId;

  // Adjust these to your sensor’s values
  final String targetName = 'ThrottleSensor';
  final Uuid   serviceUuid      = Uuid.parse('00001234-0000-1000-8000-00805f9b34fb');
  final Uuid   throttleCharUuid = Uuid.parse('00005678-0000-1000-8000-00805f9b34fb');
  final Uuid   batteryCharUuid  = Uuid.parse('00009abc-0000-1000-8000-00805f9b34fb');

  /// Scan for devices by name, auto-cancel on find
  Future<void> startScan({Duration timeout = const Duration(seconds: 5)}) async {
    _connCtrl.add(BleConnectionStatus.scanning);

    // Cancel any previous scan
    await _scanSub?.cancel();

    _scanSub = _ble.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      if (device.name == targetName) {
        _scanSub?.cancel();
        _connCtrl.add(BleConnectionStatus.discovered);
        _deviceId = device.id;
        _connectToDevice(device.id);
      }
    });

    // Safety timeout
    Future.delayed(timeout, () => _scanSub?.cancel());
  }

  void _connectToDevice(String id) {
    _connCtrl.add(BleConnectionStatus.connecting);

    // Cancel any prior connection subscription
    _connSub?.cancel();

    _connSub = _ble
        .connectToDevice(
      id: id,
      connectionTimeout: const Duration(seconds: 5),
    )
        .listen((update) {
      switch (update.connectionState) {
        case DeviceConnectionState.connecting:
          _connCtrl.add(BleConnectionStatus.connecting);
          break;
        case DeviceConnectionState.connected:
          _connCtrl.add(BleConnectionStatus.connected);
          _subscribeCharacteristics();
          break;
        case DeviceConnectionState.disconnecting:
        case DeviceConnectionState.disconnected:
          _handleDisconnect();
          break;
      }
    }, onError: (_) {
      _handleDisconnect();
    });
  }

  void _handleDisconnect() {
    // Update UI
    _connCtrl.add(BleConnectionStatus.disconnected);
    // Cancel any characteristic streams
    _throttleSub?.cancel();
    _batterySub?.cancel();
    // Retry after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (_connCtrl.hasListener) startScan();
    });
  }

  void _subscribeCharacteristics() {
    if (_deviceId == null) return;

    // Throttle notifications
    final throttleChar = QualifiedCharacteristic(
      serviceId:        serviceUuid,
      characteristicId: throttleCharUuid,
      deviceId:         _deviceId!,
    );
    _throttleSub?.cancel();
    _throttleSub = _ble.subscribeToCharacteristic(throttleChar).listen((data) {
      if (data.isNotEmpty) _throttleCtrl.add(data[0]);
    });

    // Battery notifications
    final batteryChar = QualifiedCharacteristic(
      serviceId:        serviceUuid,
      characteristicId: batteryCharUuid,
      deviceId:         _deviceId!,
    );
    _batterySub?.cancel();
    _batterySub = _ble.subscribeToCharacteristic(batteryChar).listen((data) {
      if (data.isNotEmpty) _batteryCtrl.add(data[0]);
    });
  }

  /// Clean up all streams & connections
  Future<void> dispose() async {
    await _scanSub?.cancel();
    await _connSub?.cancel();
    await _throttleSub?.cancel();
    await _batterySub?.cancel();
    await _connCtrl.close();
    await _throttleCtrl.close();
    await _batteryCtrl.close();
  }
}
