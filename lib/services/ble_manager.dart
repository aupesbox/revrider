// lib/services/ble_manager.dart

import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

enum BleConnectionStatus { disconnected, scanning, discovered, connecting, connected }

class BleManager {
  final _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;

  final _connStatus = StreamController<BleConnectionStatus>.broadcast();
  final _throttle    = StreamController<int>.broadcast();
  final _battery     = StreamController<int>.broadcast();

  late QualifiedCharacteristic _throttleChar;
  late QualifiedCharacteristic _batteryChar;

  Stream<BleConnectionStatus> get connectionStateStream => _connStatus.stream;
  Stream<int> get throttleStream  => _throttle.stream;
  Stream<int> get batteryStream   => _battery.stream;

  /// Start scanning for your device by name or service UUID
  Future<void> startScan() async {
    _connStatus.add(BleConnectionStatus.scanning);
    _scanSub = _ble.scanForDevices(
      withServices: [], // optional: filter by your service UUID
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      if (device.name == 'ThrottleSensor') {
        _connStatus.add(BleConnectionStatus.discovered);
        _scanSub?.cancel();
      }
    }, onError: (_) {
      _connStatus.add(BleConnectionStatus.disconnected);
    });
  }

  /// Connect to the first discovered device
  Future<void> connect() async {
    _connStatus.add(BleConnectionStatus.connecting);
    _connSub = _ble.connectToDevice(
      id: 'ThrottleSensor-MAC-or-ID', // replace with actual device ID
      connectionTimeout: const Duration(seconds: 10),
    ).listen((update) {
      if (update.connectionState == DeviceConnectionState.connected) {
        _connStatus.add(BleConnectionStatus.connected);
        _setupCharacteristics(update.deviceId);
      } else if (update.connectionState == DeviceConnectionState.disconnected) {
        _connStatus.add(BleConnectionStatus.disconnected);
      }
    }, onError: (_) {
      _connStatus.add(BleConnectionStatus.disconnected);
    });
  }

  void _setupCharacteristics(String deviceId) {
    // Replace with your actual service/characteristic UUIDs
    final serviceUuid      = Uuid.parse("1234");
    final throttleUuid     = Uuid.parse("5678");
    final batteryUuid      = Uuid.parse("9ABC");

    _throttleChar = QualifiedCharacteristic(serviceId: serviceUuid, characteristicId: throttleUuid, deviceId: deviceId);
    _batteryChar  = QualifiedCharacteristic(serviceId: serviceUuid, characteristicId: batteryUuid, deviceId: deviceId);

    // Listen to throttle notifications
    _ble.subscribeToCharacteristic(_throttleChar).listen((data) {
      if (data.isNotEmpty) _throttle.add(data[0]);
    }, onError: (_) {});

    // Listen to battery notifications
    _ble.subscribeToCharacteristic(_batteryChar).listen((data) {
      if (data.isNotEmpty) _battery.add(data[0]);
    }, onError: (_) {});
  }

  /// Clean up streams/subscriptions
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _connStatus.close();
    _throttle.close();
    _battery.close();
  }
}
