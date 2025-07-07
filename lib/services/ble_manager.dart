// lib/services/ble_manager.dart

import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Simplified BLE states for your app
enum BleConnectionStatus {
  disconnected,
  scanning,
  discovered,
  connecting,
  connected,
}

class BleManager {
  // 1️⃣ Core BLE instance
  final FlutterReactiveBle _ble;

  // 2️⃣ Your service + characteristic UUIDs (must match the ESP32 firmware)
  final Uuid _serviceUuid       = Uuid.parse("12345678-1234-5678-1234-56789abcdef0");
  final Uuid _throttleCharUuid  = Uuid.parse("12345678-1234-5678-1234-56789abcdef1");
  final Uuid _calibCharUuid     = Uuid.parse("12345678-1234-5678-1234-56789abcdef2");

  // 3️⃣ Streams exposed to UI/state
  final _connStatusCtrl = StreamController<BleConnectionStatus>.broadcast();
  Stream<BleConnectionStatus> get connectionStateStream => _connStatusCtrl.stream;

  final _throttleCtrl = StreamController<int>.broadcast();
  Stream<int> get throttleStream => _throttleCtrl.stream;

  // 4️⃣ Internals for scan/connect
  StreamSubscription<DiscoveredDevice>?     _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  QualifiedCharacteristic?                 _throttleChar;
  QualifiedCharacteristic?                 _calibChar;
  String?                                  _deviceId;

  BleManager([FlutterReactiveBle? ble])
      : _ble = ble ?? FlutterReactiveBle();

  /// Start scanning for your RevRiderSensor
  Future<void> startScan() async {
    _connStatusCtrl.add(BleConnectionStatus.scanning);

    _scanSub = _ble
        .scanForDevices(withServices: [_serviceUuid])
        .listen((device) {
      if (device.name == "RevRiderSensor") {
        _connStatusCtrl.add(BleConnectionStatus.discovered);
        _scanSub?.cancel();
        _deviceId = device.id;
        _prepareConnection();
      }
    }, onError: (_) {
      _connStatusCtrl.add(BleConnectionStatus.disconnected);
    });
  }

  void _prepareConnection() {
    // Prepare the QualifiedCharacteristic instances
    _throttleChar = QualifiedCharacteristic(
      serviceId:        _serviceUuid,
      characteristicId: _throttleCharUuid,
      deviceId:         _deviceId!,
    );
    _calibChar = QualifiedCharacteristic(
      serviceId:        _serviceUuid,
      characteristicId: _calibCharUuid,
      deviceId:         _deviceId!,
    );
    connect();
  }

  /// Connect and subscribe to throttle notifications
  Future<void> connect() async {
    _connStatusCtrl.add(BleConnectionStatus.connecting);

    _connSub = _ble
        .connectToDevice(
      id: _deviceId!,
      connectionTimeout: const Duration(seconds: 5),
    )
        .listen((update) {
      if (update.connectionState == DeviceConnectionState.connected) {
        _connStatusCtrl.add(BleConnectionStatus.connected);

        // Subscribe to throttle notifications
        _ble
            .subscribeToCharacteristic(_throttleChar!)
            .listen((data) {
          if (data.isNotEmpty) {
            _throttleCtrl.add(data[0]);
          }
        }, onError: (_) {
          // handle stream errors if needed
        });
      } else if (update.connectionState == DeviceConnectionState.disconnected) {
        _connStatusCtrl.add(BleConnectionStatus.disconnected);
      }
    }, onError: (_) {
      _connStatusCtrl.add(BleConnectionStatus.disconnected);
    });
  }

  /// Send the “zero-throttle” command (any value) to your device
  Future<void> calibrateZero() async {
    if (_calibChar == null) {
      throw StateError("Not connected to device");
    }
    await _ble.writeCharacteristicWithoutResponse(
      _calibChar!,
      value: [1],
    );
  }

  /// Clean up all subscriptions
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _connStatusCtrl.close();
    _throttleCtrl.close();
  }
}
