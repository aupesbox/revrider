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

/// The main home screen showing BLE connect controls, swipeable gauges, and status info.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final status = appState.connectionStatus;
    final trackText = appState.currentTrack ?? (appState.spotifyAuthenticated ? 'Loading…' : 'Engine');

    const statusLabels = {
      BleConnectionStatus.disconnected: 'Disconnected',
      BleConnectionStatus.scanning: 'Scanning…',
      BleConnectionStatus.discovered: 'Discovered',
      BleConnectionStatus.connecting: 'Connecting…',
      BleConnectionStatus.connected: 'Connected',
    };
    final statusLabel = statusLabels[status] ?? 'Unknown';

    // Build gauge pages
    final gauges = <Widget>[
      ThrottleGauge(value: appState.latestAngle.toDouble()),
      LinearThrottleGauge(value: appState.latestAngle.toDouble()),
      RangeThrottleGauge(value: appState.latestAngle.toDouble()),
      TwinThrottleGauge(value: appState.latestAngle.toDouble()),
    ];

    return AppScaffold(
      title: 'rydem',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Connect / Disconnect button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            child: ElevatedButton.icon(
              icon: Icon(
                status == BleConnectionStatus.connected
                    ? Icons.bluetooth_disabled
                    : Icons.bluetooth,
              ),
              label: Text(
                status == BleConnectionStatus.connected
                    ? 'Disconnect'
                    : 'Connect',
              ),
              onPressed: status == BleConnectionStatus.connected
                  ? () => appState.disconnect()
                  : () => appState.connect(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),

          // Swipeable gauges
          Expanded(
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.85),
              itemCount: gauges.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: gauges[index],
                    ),
                  ),
                );
              },
            ),
          ),

          // Status Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Battery: ${appState.batteryLevel}%'),
                    Text('Status: $statusLabel'),
                    Column(
                      children: [
                        Icon(
                          appState.spotifyAuthenticated ? Icons.music_note : Icons.engineering,
                          color: appState.spotifyAuthenticated ? Colors.purpleAccent : Colors.white,
                        ),
                        const SizedBox(height: 4),
                        Text(trackText, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),

              ),
            ),

          ),
          // Spotify Now Playing Bar
          if (appState.spotifyAuthenticated) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954), // Spotify green
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.music_note, color: Colors.white),
                    Expanded(
                      child: Text(
                        appState.currentTrack ?? "Loading...",
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: Colors.white),
                      onPressed: () => appState.spotifyService.skipPrevious(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      onPressed: () => appState.spotifyService.resume(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                      onPressed: () => appState.spotifyService.skipNext(),
                    ),
                  ],
                ),
              ),
            ),
          ],

        ],
      ),
    );
  }
}
