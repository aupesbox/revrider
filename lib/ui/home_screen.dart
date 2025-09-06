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
      title: 'rydem',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── NEW: optional Google sign-in banner (no blocking) ──────────────
          if (!appState.profile.googleSignedIn)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Card(
                color: Colors.white10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.login, color: Colors.white70),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Sign in with Google to sync profile & purchases.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final ok = await context.read<AppState>().ensureGoogleSignedIn();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ok ? 'Signed in' : 'Sign-in failed')),
                            );
                          }
                        },
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

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
                status == BleConnectionStatus.connected ? 'Disconnect' : 'Connect',
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

          // Spotify Now Playing Bar (shows even if not connected)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Container(
              decoration: BoxDecoration(
                color: appState.spotifyAuthenticated ? const Color(0xFF1DB954) : Colors.white10,
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


// // lib/ui/home_screen.dart
//
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../providers/app_state.dart';
// import '../services/ble_manager.dart';
// import 'app_scaffold.dart';
// import 'throttle_gauge.dart';
// import 'linear_throttle_gauge.dart';
// import 'range_throttle_gauge.dart';
// import 'twin_throttle_gauge.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   bool _authChecked = false;
//
//   @override
//   void initState() {
//     super.initState();
//     // Run after first frame to ensure we have a context & mounted scaffold
//     WidgetsBinding.instance.addPostFrameCallback((_) => _ensureGoogle());
//   }
//
//   Future<void> _ensureGoogle() async {
//     final app = context.read<AppState>();
//     final ok = await app.ensureGoogleSignedIn();
//     if (!mounted) return;
//
//     if (!ok) {
//       // Block until user signs in; no outside tap dismiss
//       String? error;
//       await showDialog<void>(
//         context: context,
//         barrierDismissible: false,
//         builder: (ctx) {
//           return StatefulBuilder(
//             builder: (ctx, setD) {
//               Future<void> _try() async {
//                 final ok2 = await context.read<AppState>().ensureGoogleSignedIn();
//                 if (!mounted) return;
//                 if (ok2) {
//                   Navigator.of(ctx).pop(); // success
//                 } else {
//                   setD(() => error = 'Sign-in failed. Try again.');
//                 }
//               }
//
//               return AlertDialog(
//                 title: const Text('Sign in required'),
//                 content: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Text('Please sign in with Google to continue.'),
//                     if (error != null) ...[
//                       const SizedBox(height: 8),
//                       Text(error!, style: const TextStyle(color: Colors.redAccent)),
//                     ],
//                   ],
//                 ),
//                 actions: [
//                   ElevatedButton.icon(
//                     onPressed: _try,
//                     icon: const Icon(Icons.login),
//                     label: const Text('Sign in with Google'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF4285F4),
//                       foregroundColor: Colors.white,
//                     ),
//                   ),
//                 ],
//               );
//             },
//           );
//         },
//       );
//     }
//
//     if (mounted) setState(() => _authChecked = true);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final appState = context.watch<AppState>();
//     final status = appState.connectionStatus;
//     final trackText = appState.currentTrack ?? (appState.spotifyAuthenticated ? 'Loading…' : 'Engine');
//
//     const statusLabels = {
//       BleConnectionStatus.disconnected: 'Disconnected',
//       BleConnectionStatus.scanning: 'Scanning…',
//       BleConnectionStatus.discovered: 'Discovered',
//       BleConnectionStatus.connecting: 'Connecting…',
//       BleConnectionStatus.connected: 'Connected',
//     };
//     final statusLabel = statusLabels[status] ?? 'Unknown';
//
//     // Build gauge pages
//     final gauges = <Widget>[
//       ThrottleGauge(value: appState.latestAngle.toDouble()),
//       LinearThrottleGauge(value: appState.latestAngle.toDouble()),
//       RangeThrottleGauge(value: appState.latestAngle.toDouble()),
//       TwinThrottleGauge(value: appState.latestAngle.toDouble()),
//     ];
//
//     return AppScaffold(
//       title: 'rydem',
//       child: Stack(
//         children: [
//           // Original content
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Connect / Disconnect button (orange)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
//                 child: ElevatedButton.icon(
//                   icon: Icon(
//                     status == BleConnectionStatus.connected
//                         ? Icons.bluetooth_disabled
//                         : Icons.bluetooth,
//                   ),
//                   label: Text(
//                     status == BleConnectionStatus.connected ? 'Disconnect' : 'Connect',
//                   ),
//                   onPressed: status == BleConnectionStatus.connected
//                       ? () => appState.disconnect()
//                       : () => appState.connect(),
//                   style: ElevatedButton.styleFrom(
//                     minimumSize: const Size.fromHeight(48),
//                     backgroundColor: const Color(0xFFCC5500),
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//               ),
//
//               // Swipeable gauges
//               Expanded(
//                 child: PageView.builder(
//                   controller: PageController(viewportFraction: 0.85),
//                   itemCount: gauges.length,
//                   itemBuilder: (context, index) {
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
//                       child: Card(
//                         elevation: 4,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: gauges[index],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//
//               // Status Info
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Card(
//                   elevation: 2,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text('Battery: ${appState.batteryLevel}%'),
//                         Text('Status: $statusLabel'),
//                         Column(
//                           children: [
//                             Icon(
//                               appState.spotifyAuthenticated ? Icons.music_note : Icons.engineering,
//                               color: appState.spotifyAuthenticated ? Colors.purpleAccent : Colors.white,
//                             ),
//                             const SizedBox(height: 4),
//                             Text(trackText, style: Theme.of(context).textTheme.bodySmall),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//
//               // Spotify Now Playing Bar (shows even if not connected)
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: appState.spotifyAuthenticated ? const Color(0xFF1DB954) : Colors.white10,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Icon(Icons.music_note, color: Colors.white),
//                       Expanded(
//                         child: Text(
//                           appState.spotifyAuthenticated
//                               ? (appState.currentTrack ?? 'Loading...')
//                               : 'Connect Spotify to control playback',
//                           style: const TextStyle(color: Colors.white),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       if (appState.spotifyAuthenticated) ...[
//                         IconButton(
//                           icon: const Icon(Icons.skip_previous, color: Colors.white),
//                           onPressed: () => appState.spotifyService.skipPrevious(),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.play_arrow, color: Colors.white),
//                           onPressed: () => appState.spotifyService.resume(),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.skip_next, color: Colors.white),
//                           onPressed: () => appState.spotifyService.skipNext(),
//                         ),
//                       ] else ...[
//                         TextButton(
//                           onPressed: () async {
//                             final ok = await appState.authenticateSpotify();
//                             if (!mounted) return;
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(content: Text(ok ? 'Spotify connected' : 'Spotify authorization failed')),
//                             );
//                           },
//                           child: const Text('Connect', style: TextStyle(color: Colors.orange)),
//                         )
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//
//           // Blocking overlay until auth complete (prevents interaction jitter)
//           if (!_authChecked)
//             Container(
//               color: Colors.black.withOpacity(0.5),
//               child: const Center(child: CircularProgressIndicator()),
//             ),
//         ],
//       ),
//     );
//   }
// }
//
// // // lib/ui/home_screen.dart
// //
// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// //
// // import '../providers/app_state.dart';
// // import '../services/ble_manager.dart';
// // import 'app_scaffold.dart';
// // import 'throttle_gauge.dart';
// // import 'linear_throttle_gauge.dart';
// // import 'range_throttle_gauge.dart';
// // import 'twin_throttle_gauge.dart';
// //
// // /// The main home screen showing BLE connect controls, swipeable gauges, and status info.
// // class HomeScreen extends StatelessWidget {
// //   const HomeScreen({super.key});
// //
// //   static const _darkOrange = Color(0xFFCC5500);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final appState = context.watch<AppState>();
// //     final status = appState.connectionStatus;
// //     final connected = appState.spotifyAuthenticated;
// //     final trackText = appState.currentTrack ?? (connected ? 'Loading…' : 'Engine');
// //
// //     const statusLabels = {
// //       BleConnectionStatus.disconnected: 'Disconnected',
// //       BleConnectionStatus.scanning: 'Scanning…',
// //       BleConnectionStatus.discovered: 'Discovered',
// //       BleConnectionStatus.connecting: 'Connecting…',
// //       BleConnectionStatus.connected: 'Connected',
// //     };
// //     final statusLabel = statusLabels[status] ?? 'Unknown';
// //
// //     // Build gauge pages
// //     final gauges = <Widget>[
// //       ThrottleGauge(value: appState.latestAngle.toDouble()),
// //       LinearThrottleGauge(value: appState.latestAngle.toDouble()),
// //       RangeThrottleGauge(value: appState.latestAngle.toDouble()),
// //       TwinThrottleGauge(value: appState.latestAngle.toDouble()),
// //     ];
// //
// //     return AppScaffold(
// //       title: 'Rydem',
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.stretch,
// //         children: [
// //           // Connect / Disconnect button (now dark orange)
// //           Padding(
// //             padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
// //             child: ElevatedButton.icon(
// //               icon: Icon(
// //                 status == BleConnectionStatus.connected
// //                     ? Icons.bluetooth_disabled
// //                     : Icons.bluetooth,
// //               ),
// //               label: Text(
// //                 status == BleConnectionStatus.connected
// //                     ? 'Disconnect'
// //                     : 'Connect',
// //               ),
// //               onPressed: status == BleConnectionStatus.connected
// //                   ? () => appState.disconnect()
// //                   : () => appState.connect(),
// //               style: ElevatedButton.styleFrom(
// //                 minimumSize: const Size.fromHeight(48),
// //                 backgroundColor: _darkOrange,
// //                 foregroundColor: Colors.white,
// //                 disabledBackgroundColor: Colors.grey,
// //                 disabledForegroundColor: Colors.white70,
// //               ),
// //             ),
// //           ),
// //
// //           // Swipeable gauges
// //           Expanded(
// //             child: PageView.builder(
// //               controller: PageController(viewportFraction: 0.85),
// //               itemCount: gauges.length,
// //               itemBuilder: (context, index) {
// //                 return Padding(
// //                   padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
// //                   child: Card(
// //                     elevation: 4,
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(16),
// //                     ),
// //                     child: Padding(
// //                       padding: const EdgeInsets.all(16.0),
// //                       child: gauges[index],
// //                     ),
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //
// //           // Status Info
// //           Padding(
// //             padding: const EdgeInsets.all(16.0),
// //             child: Card(
// //               elevation: 2,
// //               shape: RoundedRectangleBorder(
// //                 borderRadius: BorderRadius.circular(12),
// //               ),
// //               child: Padding(
// //                 padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
// //                 child: Row(
// //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                   children: [
// //                     Text('Battery: ${appState.batteryLevel}%'),
// //                     Text('Status: $statusLabel'),
// //                     Column(
// //                       children: [
// //                         Icon(
// //                           connected ? Icons.music_note : Icons.engineering,
// //                           color: connected ? Colors.purpleAccent : Colors.white,
// //                         ),
// //                         const SizedBox(height: 4),
// //                         Text(trackText, style: Theme.of(context).textTheme.bodySmall),
// //                       ],
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //
// //           // Spotify Now Playing Bar — ALWAYS visible
// //           Padding(
// //             padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
// //             child: Container(
// //               decoration: BoxDecoration(
// //                 color: connected
// //                     ? const Color(0xFF1DB954) // Spotify green when connected
// //                     : Theme.of(context).colorScheme.surfaceVariant, // neutral when not
// //                 borderRadius: BorderRadius.circular(12),
// //               ),
// //               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
// //               child: Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                 children: [
// //                   Icon(Icons.music_note,
// //                       color: connected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant),
// //                   const SizedBox(width: 10),
// //                   Expanded(
// //                     child: Text(
// //                       connected
// //                           ? (appState.currentTrack ?? "Loading...")
// //                           : "Spotify not connected",
// //                       style: TextStyle(
// //                         color: connected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
// //                       ),
// //                       overflow: TextOverflow.ellipsis,
// //                     ),
// //                   ),
// //                   const SizedBox(width: 6),
// //                   if (connected) ...[
// //                     IconButton(
// //                       icon: const Icon(Icons.skip_previous, color: Colors.white),
// //                       onPressed: () => appState.spotifyService.skipPrevious(),
// //                     ),
// //                     IconButton(
// //                       icon: const Icon(Icons.stop, color: Colors.white),
// //                       onPressed: () => appState.spotifyService.pause(),
// //                     ),
// //                     IconButton(
// //                       icon: const Icon(Icons.play_arrow, color: Colors.white),
// //                       onPressed: () => appState.spotifyService.resume(),
// //                     ),
// //                     IconButton(
// //                       icon: const Icon(Icons.skip_next, color: Colors.white),
// //                       onPressed: () => appState.spotifyService.skipNext(),
// //                     ),
// //                   ] else ...[
// //                     ElevatedButton(
// //                       onPressed: () async {
// //                         final success = await context.read<AppState>().authenticateSpotify();
// //                         if (!context.mounted) return;
// //                         ScaffoldMessenger.of(context).showSnackBar(
// //                           SnackBar(
// //                             content: Text(
// //                               success ? 'Spotify connected' : 'Spotify authorization failed',
// //                             ),
// //                           ),
// //                         );
// //                       },
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: _darkOrange,
// //                         foregroundColor: Colors.white,
// //                       ),
// //                       child: const Text('Connect'),
// //                     ),
// //                   ],
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
