// lib/ui/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/ble_manager.dart';
import 'app_scaffold.dart';
import 'throttle_gauge.dart';
import 'linear_throttle_gauge.dart';
import 'range_throttle_gauge.dart';
import 'twin_throttle_gauge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // connection label
    final connLabel = {
      BleConnectionStatus.disconnected: 'Disconnected',
      BleConnectionStatus.scanning:     'Scanning…',
      BleConnectionStatus.discovered:   'Found device',
      BleConnectionStatus.connecting:   'Connecting…',
      BleConnectionStatus.connected:    'Connected',
    }[state.connState]!;

    return AppScaffold(
      title: 'RevRider',
      child: Column(
        children: [
          // 🔧 Gauges
          Expanded(
            child: PageView(
              children: [
                ThrottleGauge(value: state.throttle.toDouble()),
                LinearThrottleGauge(value: state.throttle.toDouble()),
                RangeThrottleGauge(value: state.throttle.toDouble()),
                TwinThrottleGauge(value: state.throttle.toDouble()),
              ],
            ),
          ),

          // 🔗 Connect / Disconnect
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ElevatedButton.icon(
              icon: Icon(state.connState == BleConnectionStatus.connected
                  ? Icons.bluetooth_disabled
                  : Icons.bluetooth_searching),
              label: Text(state.connState == BleConnectionStatus.connected
                  ? 'Disconnect Sensor'
                  : 'Connect Sensor'),
              onPressed: () {
                if (state.connState == BleConnectionStatus.connected) {
                  context.read<AppState>().disconnectDevice();
                } else {
                  context.read<AppState>().connectDevice();
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ),

          // ℹ️ Info card: battery | connection | now playing
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.battery_full, color: Colors.green),
                      const SizedBox(height: 4),
                      Text('${state.battery}%', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.bluetooth, color: Colors.blueAccent),
                      const SizedBox(height: 4),
                      Text(connLabel, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.music_note, color: Colors.purpleAccent),
                      const SizedBox(height: 4),
                      Text(
                        state.currentTrack ?? 'None',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
