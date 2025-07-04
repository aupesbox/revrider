import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_scaffold.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return AppScaffold(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme toggle
          SwitchListTile(
            title: const Text('Dark Theme (Unix)'),
            subtitle: const Text('Toggle between dark & light modes'),
            value: themeProvider.mode == ThemeMode.dark,
            onChanged: (_) => themeProvider.toggle(),
            secondary: const Icon(Icons.brightness_6),
          ),

          const Divider(),

          // Existing calibration tile...
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Re-calibrate Throttle'),
            subtitle: const Text('Set current grip position as zero'),
            onTap: () {
              // your existing calibrate logic
            },
          ),

          // …other settings…
        ],
      ),
    );
  }
}
