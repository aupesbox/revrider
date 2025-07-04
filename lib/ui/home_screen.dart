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
    final state     = context.watch<AppState>();
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
          // 1) Throttle Gauges
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

          // 2) Demo slider (only in demoMode)
          if (demoMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  Text(
                    'Demo Throttle : ${state.throttle}%',
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

          // 3) Connect Button (only when not demoMode and not yet connected)
          if (!demoMode &&
              (state.connState == BleConnectionStatus.disconnected ||
                  state.connState == BleConnectionStatus.scanning ||
                  state.connState == BleConnectionStatus.discovered))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('Connect Sensor'),
                onPressed: () => context.read<AppState>().connectDevice(),
              ),
            ),

          // 4) Dashboard Info: Battery & Connection Status
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    const Icon(Icons.battery_full, color: Colors.cyanAccent),
                    const SizedBox(width: 4),
                    Text(
                      '${state.battery}%',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.bluetooth, color: Colors.cyanAccent),
                    const SizedBox(width: 4),
                    Text(
                      connLabel,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
