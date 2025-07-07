// lib/ui/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
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

    // Human-readable connection status
    final connLabel = {
      BleConnectionStatus.disconnected: 'Disconnected',
      BleConnectionStatus.scanning:     'Scanning…',
      BleConnectionStatus.discovered:   'Discovered',
      BleConnectionStatus.connecting:   'Connecting…',
      BleConnectionStatus.connected:    'Connected',
    }[state.connState]!;

    return AppScaffold(
      title: 'Home',
      child: Column(
        children: [
          // 1) Gauges
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

          // 2) Start / Connect button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Start'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => context.read<AppState>().connectDevice(),
            ),
          ),

          // 3) Info Bar: Battery | Connection | Now Playing
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
                      Text('${state.battery}%', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),

                  // Connection Status
                  Column(
                    children: [
                      const Icon(Icons.bluetooth, color: Colors.blueAccent),
                      const SizedBox(height: 4),
                      Text(connLabel, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),

                  // Now Playing (requires AppState.currentTrack)
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

          // 4) Demo slider (only if demoMode)
          if (demoMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  Text(
                    'Demo Throttle: ${state.throttle}%',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Slider(
                    min: 0,
                    max: 100,
                    divisions: 100,
                    value: state.throttle.toDouble(),
                    onChanged: (v) => context.read<AppState>().setThrottle(v.toInt()),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
