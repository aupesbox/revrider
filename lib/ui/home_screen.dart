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

/// The main Home screen with swipeable gauges, connection controls, and status info.
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final connLabel = <BleConnectionStatus, String>{
      BleConnectionStatus.disconnected: 'Disconnected',
      BleConnectionStatus.scanning:     'Scanning…',
      BleConnectionStatus.discovered:   'Discovered',
      BleConnectionStatus.connecting:   'Connecting…',
      BleConnectionStatus.connected:    'Connected',
    }[appState.connectionStatus] ?? 'Unknown';


    // Build gauges plus a premium‐teaser page if needed
    final gaugePages = <Widget>[
      ThrottleGauge(value: appState.latestAngle.toDouble()),
      LinearThrottleGauge(value: appState.latestAngle.toDouble()),
      RangeThrottleGauge(value: appState.latestAngle.toDouble()),
      TwinThrottleGauge(value: appState.latestAngle.toDouble()),
    ];

    if (!appState.isPremium) {
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
      title: 'Aupesbox RevMimic',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[

            // 1) Connection Controls
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.bluetooth),
                      label: const Text('Connect'),
                      onPressed: appState.isConnected ? null
                          : () async {
                        final ok = await appState.connect();
                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bluetooth permission denied or connection failed')),
                          );
                        }
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.bluetooth_disabled),
                      label: const Text('Disconnect'),
                      onPressed: appState.isConnected ? () { appState.disconnect(); } : null,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2) Swipeable Gauges Carousel
            SizedBox(
              height: 480,
              child: PageView(children: gaugePages)),
                      const SizedBox(height: 24),

            // 3) Status Information
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
                  Text('${appState.batteryLevel}%', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),

              // Connection Status (+ device name)
              Column(
                children: [
                  const Icon(Icons.bluetooth, color: Colors.blueAccent),
                  const SizedBox(height: 4),
                  Text(connLabel, style: Theme.of(context).textTheme.bodySmall),
                  if (appState.isConnected == BleConnectionStatus.connected &&
                      appState.connectedDeviceName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      appState.connectedDeviceName!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),

              // Now Playing or Premium Crown
              Column(
                children: [
                  Icon(
                    appState.isPremium ? Icons.workspace_premium : Icons.music_note,
                    color: appState.isPremium ? Colors.amber : Colors.purpleAccent,
                  ),
                  const SizedBox(height: 4),
                  if (!appState.isPremium)
                    const Text('Premium', style: TextStyle(fontSize: 12))
                  else
                    Text(
                      appState.currentTrack ?? 'None',
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
    ),
    );
  }
}

