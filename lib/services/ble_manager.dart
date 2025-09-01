// lib/services/ble_manager.dart

import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Represents the BLE connection state for the throttle sensor.
enum BleConnectionStatus {
  disconnected,
  scanning,
  discovered,
  connecting,
  connected,
}

/// Manages scanning, connecting, calibration, and notification subscriptions for the throttle BLE device.
class BleManager {
  // UUIDs must match the Arduino firmware
  static const _serviceUuid = '12345678-1234-5678-1234-56789abcdef0';
  static const _throttleUuid = '12345678-1234-5678-1234-56789abcdef1';
  static const _calibUuid = '12345678-1234-5678-1234-56789abcdef2';

  final FlutterReactiveBle _ble = FlutterReactiveBle();

  // Streams for connection updates and throttle values
  final _connectionCtrl = StreamController<BleConnectionStatus>.broadcast();
  final _throttleCtrl = StreamController<int>.broadcast();

  /// Broadcast stream of connection state changes.
  Stream<BleConnectionStatus> get connectionStateStream => _connectionCtrl.stream;

  /// Broadcast stream of throttle percentage (0–100).
  Stream<int> get throttleStream => _throttleCtrl.stream;

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _notifySub;
  String? _deviceId;

  /// Starts scanning and connects to the first device advertising our service.
  Future<void> connect() async {
    _connectionCtrl.add(BleConnectionStatus.scanning);
    _scanSub = _ble
        .scanForDevices(
      withServices: [Uuid.parse(_serviceUuid)],
      scanMode: ScanMode.lowLatency,
    )
        .listen((device) {
      // Always connect to first discovered device with matching service
      _scanSub?.cancel();
      _connectionCtrl.add(BleConnectionStatus.discovered);
      _deviceId = device.id;
      _connectToDevice(device.id);
    }, onError: (_) {
      _connectionCtrl.add(BleConnectionStatus.disconnected);
    });
  }

  void _connectToDevice(String id) {
    _connectionCtrl.add(BleConnectionStatus.connecting);
    _connSub = _ble.connectToDevice(
      id: id,
      connectionTimeout: const Duration(seconds: 5),
    ).listen((event) async {
      if (event.connectionState == DeviceConnectionState.connected) {
        _connectionCtrl.add(BleConnectionStatus.connected);
        _subscribeToThrottle(id);
      } else if (event.connectionState == DeviceConnectionState.disconnected) {
        // 🔧 Full cleanup on disconnect
        await _notifySub?.cancel();
        _notifySub = null;
        await _connSub?.cancel();
        _connSub = null;
        _deviceId = null;

        _connectionCtrl.add(BleConnectionStatus.disconnected);

        // 🔁 Auto-reconnect after short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_connectionCtrl.isClosed) {
            connect();
          }
        });
      }
    }, onError: (_) {
      _connectionCtrl.add(BleConnectionStatus.disconnected);
    });
  }

  void _subscribeToThrottle(String deviceId) {
    final char = QualifiedCharacteristic(
      serviceId: Uuid.parse(_serviceUuid),
      characteristicId: Uuid.parse(_throttleUuid),
      deviceId: deviceId,
    );
    _notifySub = _ble.subscribeToCharacteristic(char).listen((data) {
      if (data.isNotEmpty) {
        final raw = data[0].clamp(0, 255);
        final pct = (raw * 100 / 255).round();
        _throttleCtrl.add(pct);
      }
    });
  }

  /// Send a calibration command (0x01) to reset zero offset on the device.
  Future<void> calibrate() async {
    if (_deviceId == null) return;
    final char = QualifiedCharacteristic(
      serviceId: Uuid.parse(_serviceUuid),
      characteristicId: Uuid.parse(_calibUuid),
      deviceId: _deviceId!,
    );
    await _ble.writeCharacteristicWithoutResponse(
      char,
      value: [1],
    );
  }

  /// Disconnects and cleans up all subscriptions.
  Future<void> disconnect() async {
    await _scanSub?.cancel();
    await _connSub?.cancel();
    await _notifySub?.cancel();
    _deviceId = null; // 🔧 NEW
    _connectionCtrl.add(BleConnectionStatus.disconnected);
  }

  /// Dispose streams when no longer needed.
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _notifySub?.cancel();
    _connectionCtrl.close();
    _throttleCtrl.close();
  }
}


// // lib/services/ble_manager.dart
//
// import 'dart:async';
// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
//
// /// Represents the BLE connection state for the throttle sensor.
// enum BleConnectionStatus { disconnected, scanning, discovered, connecting, connected }
//
// /// Manages scanning, connecting, calibration, and notification subscriptions for the throttle BLE device.
// class BleManager {
//   // UUIDs must match the Arduino firmware
//   static const _serviceUuid    = '12345678-1234-5678-1234-56789abcdef0';
//   static const _throttleUuid   = '12345678-1234-5678-1234-56789abcdef1';
//   static const _calibUuid      = '12345678-1234-5678-1234-56789abcdef2';
//
//   final FlutterReactiveBle _ble = FlutterReactiveBle();
//
//   // Streams for connection updates and throttle values
//   final _connectionCtrl = StreamController<BleConnectionStatus>.broadcast();
//   final _throttleCtrl   = StreamController<int>.broadcast();
//
//   /// Broadcast stream of connection state changes.
//   Stream<BleConnectionStatus> get connectionStateStream => _connectionCtrl.stream;
//
//   /// Broadcast stream of throttle percentage (0–100).
//   Stream<int> get throttleStream => _throttleCtrl.stream;
//
//   StreamSubscription<DiscoveredDevice>?    _scanSub;
//   StreamSubscription<ConnectionStateUpdate>? _connSub;
//   StreamSubscription<List<int>>?           _notifySub;
//   String?                                  _deviceId;
//
//   /// Starts scanning and connects to the first device advertising our service.
//   Future<void> connect() async {
//     _connectionCtrl.add(BleConnectionStatus.scanning);
//     _scanSub = _ble.scanForDevices(
//       withServices: [Uuid.parse(_serviceUuid)],
//       scanMode:      ScanMode.lowLatency,
//     ).listen((device) {
//       // Filter by name if desired
//       if (device.name.toLowerCase() == 'aupesbox' || device.name.isEmpty) {
//         _scanSub?.cancel();
//         _connectionCtrl.add(BleConnectionStatus.discovered);
//         _deviceId = device.id;
//         _connectToDevice(device.id);
//       }
//     }, onError: (_) {
//       _connectionCtrl.add(BleConnectionStatus.disconnected);
//     });
//   }
//
//   void _connectToDevice(String id) {
//     _connectionCtrl.add(BleConnectionStatus.connecting);
//     _connSub = _ble.connectToDevice(
//       id: id,
//       connectionTimeout: const Duration(seconds: 5),
//     ).listen((event) {
//       if (event.connectionState == DeviceConnectionState.connected) {
//         _connectionCtrl.add(BleConnectionStatus.connected);
//         _subscribeToThrottle(id);
//       } else {
//         _connectionCtrl.add(BleConnectionStatus.disconnected);
//       }
//     }, onError: (_) {
//       _connectionCtrl.add(BleConnectionStatus.disconnected);
//     });
//   }
//
//   void _subscribeToThrottle(String deviceId) {
//     final char = QualifiedCharacteristic(
//       serviceId:        Uuid.parse(_serviceUuid),
//       characteristicId: Uuid.parse(_throttleUuid),
//       deviceId:         deviceId,
//     );
//     _notifySub = _ble.subscribeToCharacteristic(char).listen((data) {
//       if (data.isNotEmpty) {
//         final raw = data[0].clamp(0, 255);
//         final pct = (raw * 100 / 255).round();
//         _throttleCtrl.add(pct);
//       }
//     });
//   }
//
//   /// Send a calibration command (0x01) to reset zero offset on the device.
//   Future<void> calibrate() async {
//     if (_deviceId == null) return;
//     final char = QualifiedCharacteristic(
//       serviceId:        Uuid.parse(_serviceUuid),
//       characteristicId: Uuid.parse(_calibUuid),
//       deviceId:         _deviceId!,
//     );
//     await _ble.writeCharacteristicWithoutResponse(
//       char,
//       value: [1],
//     );
//   }
//
//   /// Disconnects and cleans up all subscriptions.
//   Future<void> disconnect() async {
//     await _scanSub?.cancel();
//     await _connSub?.cancel();
//     await _notifySub?.cancel();
//     _connectionCtrl.add(BleConnectionStatus.disconnected);
//   }
//
//   /// Dispose streams when no longer needed.
//   void dispose() {
//     _scanSub?.cancel();
//     _connSub?.cancel();
//     _notifySub?.cancel();
//     _connectionCtrl.close();
//     _throttleCtrl.close();
//   }
// }
