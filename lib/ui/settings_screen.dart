// lib/ui/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'app_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv    = context.watch<ThemeProvider>();
    //final purchaseProv = context.watch<PurchaseProvider>();

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


          // ...any other settings
          const Divider(),
          // Existing calibration tile...
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Re-calibrate Throttle'),
            subtitle: const Text('Set current grip position as zero'),
            onTap: () {
              // Re-Calibrate button (premium only)
              // if (purchaseProv.isPremium) {
              //   ElevatedButton.icon(
              //     icon: const Icon(Icons.tune),
              //     label: const Text('Re-Calibrate Throttle'),
              //     onPressed: () => context.read<AppState>()
              //         .calibrateThrottle(),
              //   );
              // }
            },
          ),
        ],
      ),
    );
  }
}
