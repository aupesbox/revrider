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
  final FlutterReactiveBle _ble;

  /// UUIDs must match your ESP32 firmware
  final Uuid _serviceUuid      = Uuid.parse("12345678-1234-5678-1234-56789abcdef0");
  final Uuid _throttleCharUuid = Uuid.parse("12345678-1234-5678-1234-56789abcdef1");
  final Uuid _calibCharUuid    = Uuid.parse("12345678-1234-5678-1234-56789abcdef2");

  // Exposed streams
  final _connStatusCtrl = StreamController<BleConnectionStatus>.broadcast();
  Stream<BleConnectionStatus> get connectionStateStream => _connStatusCtrl.stream;

  final _throttleCtrl = StreamController<int>.broadcast();
  Stream<int> get throttleStream => _throttleCtrl.stream;

  // Internals
  StreamSubscription<DiscoveredDevice>?      _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  QualifiedCharacteristic?                   _throttleChar;
  QualifiedCharacteristic?                   _calibChar;
  String?                                    _deviceId;
  String?                                    _deviceName;

  BleManager([FlutterReactiveBle? ble]) : _ble = ble ?? FlutterReactiveBle();

  /// Last discovered device name
  String? get deviceName => _deviceName;

  /// Start scanning for RevRiderSensor / aupesbox
  Future<void> startScan() async {
    _connStatusCtrl.add(BleConnectionStatus.scanning);
    await _scanSub?.cancel();

    _scanSub = _ble
        .scanForDevices(withServices: [_serviceUuid])
        .listen((device) {
      if (device.name == "aupesbox" || device.name == "RevRiderSensor") {
        _deviceId   = device.id;
        _deviceName = device.name;
        _connStatusCtrl.add(BleConnectionStatus.discovered);
        _scanSub?.cancel();
        _prepareConnection();
      }
    }, onError: (_) {
      _connStatusCtrl.add(BleConnectionStatus.disconnected);
    });
  }

  void _prepareConnection() {
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

  /// Connect + subscribe to throttle notifications
  Future<void> connect() async {
    _connStatusCtrl.add(BleConnectionStatus.connecting);
    await _connSub?.cancel();

    _connSub = _ble
        .connectToDevice(
      id: _deviceId!,
      connectionTimeout: const Duration(seconds: 5),
    )
        .listen((update) {
      if (update.connectionState == DeviceConnectionState.connected) {
        _connStatusCtrl.add(BleConnectionStatus.connected);
        // subscribe to throttle
        _ble
            .subscribeToCharacteristic(_throttleChar!)
            .listen((data) {
          if (data.isNotEmpty) _throttleCtrl.add(data[0]);
        }, onError: (_) {});
      } else if (update.connectionState == DeviceConnectionState.disconnected) {
        _connStatusCtrl.add(BleConnectionStatus.disconnected);
      }
    }, onError: (_) {
      _connStatusCtrl.add(BleConnectionStatus.disconnected);
    });
  }

  /// Disconnect by cancelling the connection subscription
  Future<void> disconnect() async {
    await _connSub?.cancel();
    _connSub = null;
    _connStatusCtrl.add(BleConnectionStatus.disconnected);
  }

  /// Send “zero-throttle” command
  Future<void> calibrateZero() async {
    if (_calibChar == null) {
      throw StateError("Not connected to device");
    }
    await _ble.writeCharacteristicWithoutResponse(
      _calibChar!,
      value: [1],
    );
  }

  /// Clean up
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _connStatusCtrl.close();
    _throttleCtrl.close();
  }
}
