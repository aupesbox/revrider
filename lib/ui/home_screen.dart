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
    final state     = context.watch<AppState>();
    final isPremium = state.isPremium;

    final connLabel = {
      BleConnectionStatus.disconnected: 'Disconnected',
      BleConnectionStatus.scanning:     'Scanning…',
      BleConnectionStatus.discovered:   'Discovered',
      BleConnectionStatus.connecting:   'Connecting…',
      BleConnectionStatus.connected:    'Connected',
    }[state.connState]!;

    // Build gauges plus a premium‐teaser page if needed
    final gaugePages = <Widget>[
      ThrottleGauge(value: state.throttle.toDouble()),
      LinearThrottleGauge(value: state.throttle.toDouble()),
      RangeThrottleGauge(value: state.throttle.toDouble()),
      TwinThrottleGauge(value: state.throttle.toDouble()),
    ];
    if (!isPremium) {
      gaugePages.add(
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium, size: 64, color: Colors.amber),
              SizedBox(height: 16),
              Text(
                'More gauges\navailable\nin Premium',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'RevRider',
      child: Column(
        children: [
          // 1) Gauges
          Expanded(child: PageView(children: gaugePages)),

          // 2) Connect / Disconnect
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: ElevatedButton.icon(
              icon: Icon(
                state.connState == BleConnectionStatus.connected
                    ? Icons.bluetooth_disabled
                    : Icons.bluetooth_searching,
              ),
              label: Text(
                state.connState == BleConnectionStatus.connected
                    ? 'Disconnect Sensor'
                    : 'Connect Sensor',
              ),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () {
                if (state.connState == BleConnectionStatus.connected) {
                  context.read<AppState>().disconnectDevice();
                } else {
                  context.read<AppState>().connectDevice();
                }
              },
            ),
          ),

          // 3) Info Bar: Battery | Connection | Now Playing / Premium Crown
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

                  // Connection Status (+ device name)
                  Column(
                    children: [
                      const Icon(Icons.bluetooth, color: Colors.blueAccent),
                      const SizedBox(height: 4),
                      Text(connLabel, style: Theme.of(context).textTheme.bodySmall),
                      if (state.connState == BleConnectionStatus.connected &&
                          state.connectedDeviceName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          state.connectedDeviceName!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),

                  // Now Playing or Premium Crown
                  Column(
                    children: [
                      Icon(
                        isPremium ? Icons.workspace_premium : Icons.music_note,
                        color: isPremium ? Colors.amber : Colors.purpleAccent,
                      ),
                      const SizedBox(height: 4),
                      if (!isPremium)
                        const Text('Premium', style: TextStyle(fontSize: 12))
                      else
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
