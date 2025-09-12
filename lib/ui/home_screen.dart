// lib/ui/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rydem/ui/trip_card.dart';

import '../providers/app_state.dart';
import '../services/ble_manager.dart';
import 'app_scaffold.dart';
import 'map_panel.dart';
import 'throttle_gauge.dart';
import 'linear_throttle_gauge.dart';
import 'range_throttle_gauge.dart';
import 'twin_throttle_gauge.dart';

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

    // Gauges
    final gauges = <Widget>[
      ThrottleGauge(value: appState.latestAngle.toDouble()),
      LinearThrottleGauge(value: appState.latestAngle.toDouble()),
      RangeThrottleGauge(value: appState.latestAngle.toDouble()),
      TwinThrottleGauge(value: appState.latestAngle.toDouble()),
    ];

    return AppScaffold(
      title: 'Rydem',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                   child: SizedBox(
                      height: 240, // ~top half on most phones; tweak as you like
                      child: MapPanel(),
                ),
                ),
                 const Padding(
                   padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                     child: TripCard(),
                  ),
          // ── NEW: optional Google sign-in banner (no blocking) ──────────────
          // if (!appState.profile.googleSignedIn)
          //   Padding(
          //     padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          //     child: Card(
          //       color: Colors.white10,
          //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          //       child: Padding(
          //         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          //         child: Row(
          //           children: [
          //             const Icon(Icons.login, color: Colors.white70),
          //             const SizedBox(width: 12),
          //             const Expanded(
          //               child: Text(
          //                 'Sign in with Google to sync profile & purchases.',
          //                 style: TextStyle(color: Colors.white70),
          //               ),
          //             ),
          //             TextButton(
          //                 onPressed: () async {
          //                 final acc = await GoogleAuthService.instance.signIn();
          //                 final msg = (acc == null) ? 'Sign-in canceled' : 'Signed in';
          //                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          //                 },
          //
          // child: const Text('Sign in'),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),

          // Connect / Disconnect button (orange)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            child: ElevatedButton.icon(
              icon: Icon(
                status == BleConnectionStatus.connected
                    ? Icons.bluetooth_disabled
                    : Icons.bluetooth,
              ),
              label: Text(
                status == BleConnectionStatus.connected ? statusLabel : '$statusLabel - Tap to connect:',
              ),

             onPressed: status == BleConnectionStatus.connected
                  ? () => appState.disconnect()
                  : () => appState.connect(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFFCC5500),
                foregroundColor: Colors.white,
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

          // Status
          // Padding(
          //   padding: const EdgeInsets.all(16.0),
          //   child: Card(
          //     elevation: 2,
          //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          //     child: Padding(
          //       padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          //       child: Row(
          //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //         children: [
          //           Text('Battery: ${appState.batteryLevel}%'),
          //           Text('Status: $statusLabel'),
          //           Column(
          //             children: [
          //               Icon(
          //                 appState.spotifyAuthenticated ? Icons.music_note : Icons.engineering,
          //                 color: appState.spotifyAuthenticated ? Colors.purpleAccent : Colors.white,
          //               ),
          //               const SizedBox(height: 4),
          //               Text(trackText, style: Theme.of(context).textTheme.bodySmall),
          //             ],
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),

          // Spotify Now Playing Bar (shows even if not connected)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Container(
              decoration: BoxDecoration(
                color: appState.spotifyAuthenticated ? const Color(0xFF3FBCD3) : Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.music_note, color: Colors.deepOrange),
                  Expanded(
                    child: Text(
                      appState.spotifyAuthenticated
                          ? (appState.currentTrack ?? 'Loading...')
                          : 'Connect Spotify to control playback',
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (appState.spotifyAuthenticated) ...[
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: Colors.deepOrange),
                      onPressed: () => appState.spotifyService.skipPrevious(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.deepOrange),
                      onPressed: () => appState.spotifyService.resume(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop),
                      onPressed: () => appState.spotifyService.pause(),
                    ),

                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.deepOrange),
                      onPressed: () => appState.spotifyService.skipNext(),
                    ),
                  ] else ...[
                    TextButton(
                      onPressed: () async {
                        final ok = await appState.authenticateSpotify();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'Spotify connected' : 'Spotify authorization failed')),
                        );
                      },
                      child: const Text('Connect', style: TextStyle(color: Colors.deepOrange)),
                    )
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

