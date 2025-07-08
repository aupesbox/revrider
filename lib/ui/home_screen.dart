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

    final connLabel = {
      BleConnectionStatus.disconnected: 'Disconnected',
      BleConnectionStatus.scanning:     'Scanning…',
      BleConnectionStatus.discovered:   'Discovered',
      BleConnectionStatus.connecting:   'Connecting…',
      BleConnectionStatus.connected:    'Connected',
    }[state.connState]!;

    final isConnected = state.connState == BleConnectionStatus.connected;

    return AppScaffold(
      title: 'RevRider',
      child: Column(
        children: [
          // 1) Real-time Throttle Gauges
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

          // 2) Connect / Disconnect button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: ElevatedButton.icon(
              icon: Icon(isConnected
                  ? Icons.bluetooth_disabled
                  : Icons.bluetooth_searching),
              label: Text(isConnected
                  ? 'Disconnect Sensor'
                  : 'Connect Sensor'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () {
                if (isConnected) {
                  context.read<AppState>().disconnectDevice();
                } else {
                  context.read<AppState>().connectDevice();
                }
              },
            ),
          ),

          // 3) Info Bar: Battery | Connection + Device | Now Playing
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Battery
                  Column(
                    children: [
                      const Icon(Icons.battery_full, color: Colors.green),
                      const SizedBox(height: 4),
                      Text('${state.battery}%',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),

                  // Connection + Device
                  Column(
                    children: [
                      const Icon(Icons.bluetooth, color: Colors.blueAccent),
                      const SizedBox(height: 4),
                      Text(
                        state.connectedDeviceName != null
                            ? '$connLabel to ${state.connectedDeviceName}'
                            : connLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  // Now Playing
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
