// lib/ui/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/theme_provider.dart';
import '../providers/purchase_provider.dart';
import 'app_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProv    = context.watch<ThemeProvider>();
    final appState     = context.watch<AppState>();
    final purchaseProv = context.watch<PurchaseProvider>();

    return AppScaffold(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dark/Light theme toggle
          SwitchListTile(
            title: const Text('Use Dark Theme'),
            value: themeProv.mode == ThemeMode.dark,
            onChanged: (val) => themeProv.toggleTheme(val),
          ),

          const Divider(),

          // Re-calibration (premium only)
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Re-Calibrate Throttle'),
            onTap: appState.isConnected
                ? () => appState.calibrateThrottle()
                : null,
          ),

          const Divider(),

          // Spotify Authentication
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text('Spotify Playback'),
            subtitle: Text(
              appState.spotifyAuthenticated ? 'Connected' : 'Not connected',
            ),
            trailing: ElevatedButton(
              onPressed: () => appState.authenticateSpotify(),
              child: Text(
                appState.spotifyAuthenticated ? 'Re-Auth' : 'Authorize',
              ),
            ),
          ),

          const Divider(),

          // Restore Purchases
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore Purchases'),
            onTap: () async {
              await purchaseProv.restorePurchases();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Purchases restored')),
              );
            },
          ),

          const Divider(),

          // About
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'RevRider',
              applicationVersion: '1.0.0',
              children: [
                const Text('Real-time motorcycle exhaust simulator.'),
              ],
            ),
          ),

          // (Optional) Log out Spotify
          if (appState.spotifyAuthenticated) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out Spotify'),
              onTap: () {
                appState.spotifyAuthenticated = false;
                appState.notifyListeners();
              },
            ),
          ],
        ],
      ),
    );
  }
}


// // lib/ui/settings_screen.dart
//
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/theme_provider.dart';
// import 'app_scaffold.dart';
//
// class SettingsScreen extends StatelessWidget {
//   const SettingsScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final themeProv    = context.watch<ThemeProvider>();
//     //final purchaseProv = context.watch<PurchaseProvider>();
//
//     return AppScaffold(
//       title: 'Settings',
//       child: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           // Dark/Light theme toggle
//           SwitchListTile(
//             title: const Text('Use Dark Theme'),
//             value: themeProv.mode == ThemeMode.dark,
//             onChanged: (val) => themeProv.toggleTheme(val),
//           ),
//
//           const Divider(),
//
//
//           // ...any other settings
//           const Divider(),
//           // Existing calibration tile...
//           ListTile(
//             leading: const Icon(Icons.tune),
//             title: const Text('Re-calibrate Throttle'),
//             subtitle: const Text('Set current grip position as zero'),
//             onTap: () {
//               // Re-Calibrate button (premium only)
//               // if (purchaseProv.isPremium) {
//               //   ElevatedButton.icon(
//               //     icon: const Icon(Icons.tune),
//               //     label: const Text('Re-Calibrate Throttle'),
//               //     onPressed: () => context.read<AppState>()
//               //         .calibrateThrottle(),
//               //   );
//               // }
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
