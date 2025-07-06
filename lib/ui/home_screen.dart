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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final state     = context.watch<AppState>();
    final status    = state.connState;
    final connLabel = {
      BleConnectionStatus.disconnected: 'Disconnected',
      BleConnectionStatus.scanning:     'Scanning…',
      BleConnectionStatus.discovered:   'Found!',
      BleConnectionStatus.connecting:   'Connecting…',
      BleConnectionStatus.connected:    'Connected',
    }[status]!;

    // Button is disabled while scanning/connecting or already connected
    final canConnect = status == BleConnectionStatus.disconnected;

    return AppScaffold(
      title: 'Home',
      child: Column(
        children: [
          // 0) Connection Status Indicator
          if (status == BleConnectionStatus.scanning ||
              status == BleConnectionStatus.connecting) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: LinearProgressIndicator(),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              connLabel,
              style: TextStyle(
                color: status == BleConnectionStatus.connected
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

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

          // 2) Always-on Throttle Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: [
                Text(
                  'Throttle : ${state.throttle}%',
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

          // 3) Test-only Premium Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SwitchListTile(
              title: const Text('Test Premium Mode'),
              subtitle: const Text('Enable BLE & Premium UI'),
              value: state.testPremium,
              onChanged: (val) {
                state.testPremium = val;
                setState(() {});
              },
              secondary: const Icon(Icons.upgrade),
            ),
          ),

          // 4) Connect Sensor button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Connect Sensor'),
              onPressed: canConnect
                  ? () => context.read<AppState>().connectDevice()
                  : null,
            ),
          ),

          // 5) Dashboard Info: Battery & Connection Status
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
