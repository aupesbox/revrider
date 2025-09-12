import 'dart:async';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/ble_manager.dart';

class TestHarnessScreen extends StatefulWidget {
  const TestHarnessScreen({super.key});
  @override
  State<TestHarnessScreen> createState() => _TestHarnessScreenState();
}

class _TestHarnessScreenState extends State<TestHarnessScreen> {
  late final AppState app;
  late final BleManager ble;

  DateTime? connectStart;
  Duration? connectDuration;
  DateTime? lastDisconnect;
  Duration? lastReconnectDuration;
  List<int> throttleTimestamps = [];

  StreamSubscription<BleConnectionStatus>? _connSub;
  StreamSubscription<int>? _thrSub;

  int dropCount = 0;
  DateTime? sessionStart;

  @override
  void initState() {
    super.initState();
    app = context.read<AppState>();
    ble = context.read<BleManager>();
    sessionStart = DateTime.now();

    _connSub = ble.connectionStateStream.listen((s) {
      final now = DateTime.now();
      if (s == BleConnectionStatus.connecting) {
        connectStart = now;
      } else if (s == BleConnectionStatus.connected) {
        if (connectStart != null) {
          connectDuration = now.difference(connectStart!);
        }
        if (lastDisconnect != null) {
          lastReconnectDuration = now.difference(lastDisconnect!);
          lastDisconnect = null;
        }
      } else if (s == BleConnectionStatus.disconnected) {
        lastDisconnect = now;
        dropCount += 1;
      }
      setState(() {});
    });

    _thrSub = ble.throttleStream.listen((_) {
      throttleTimestamps.add(DateTime.now().millisecondsSinceEpoch);
      if (throttleTimestamps.length > 300) {
        throttleTimestamps.removeAt(0); // keep last 300
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _thrSub?.cancel();
    super.dispose();
  }

  double throttleRateHz() {
    if (throttleTimestamps.length < 2) return 0;
    final dt = throttleTimestamps.last - throttleTimestamps.first;
    return dt > 0 ? (throttleTimestamps.length - 1) * 1000 / dt : 0;
  }

  double throttleJitterMs() {
    if (throttleTimestamps.length < 3) return 0;
    final diffs = <int>[];
    for (var i = 1; i < throttleTimestamps.length; i++) {
      diffs.add(throttleTimestamps[i] - throttleTimestamps[i - 1]);
    }
    final mean = diffs.reduce((a, b) => a + b) / diffs.length;
    final sq = diffs.map((d) => (d - mean) * (d - mean)).reduce((a, b) => a + b) / diffs.length;
    return sq.sqrt();
  }

  String fmt(Duration? d) => d == null ? '--' : '${d.inMilliseconds} ms';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final elapsedMins = sessionStart != null ? now.difference(sessionStart!).inMinutes : 0;
    final dropRate = elapsedMins > 0 ? (dropCount * 60 / elapsedMins) : 0;

    final rate = throttleRateHz();
    final jitter = throttleJitterMs();

    return Scaffold(
      appBar: AppBar(title: const Text('BLE Test Harness')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Session Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _row('Connect time', fmt(connectDuration), connectDuration != null && connectDuration!.inMilliseconds <= 120),
          _row('Reconnect time', fmt(lastReconnectDuration), lastReconnectDuration != null && lastReconnectDuration!.inSeconds <= 3),
          _row('BLE Drops (last $elapsedMins min)', '$dropCount', dropRate < 5),
          _row('Throttle rate', '${rate.toStringAsFixed(1)} Hz', rate >= 9),
          _row('Throttle jitter', '${jitter.toStringAsFixed(1)} ms', jitter <= 20),
          Text("Last reconnect latency: ${app.reconnectLatencyLabel}",
              style: const TextStyle(fontSize: 16)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Last reconnect latency: ${app.reconnectLatencyLabel}"),
              Text("Average reconnect latency: ${app.averageReconnectLatencySec.toStringAsFixed(2)}s"),
              Text("Reconnect count: ${app.reconnectCount}"),
            ],
          ),

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => context.read<AppState>().resetReconnectMetrics(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Reset Metrics"),
          ),

        ],
      ),
    );
  }

  Widget _row(String label, String value, bool pass) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: TextStyle(color: pass ? Colors.green : Colors.red)),
          const SizedBox(width: 8),
          Icon(pass ? Icons.check_circle : Icons.cancel, color: pass ? Colors.green : Colors.red),
        ],
      ),
    );
  }
}

extension on double {
  double sqrt() => (this < 0) ? 0 : Math.sqrt(this);
}
