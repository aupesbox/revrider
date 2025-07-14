// lib/ui/prelaunch_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import 'splash_screen.dart';

/// Screen shown on app start to choose Basic or Premium testing mode.
class PreLaunchScreen extends StatelessWidget {
  const PreLaunchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Mode')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose App Mode for Testing:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.read<AppState>().setPremium(false);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SplashScreen(),
                    ),
                  );
                },
                child: const Text('Basic Mode'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  context.read<AppState>().setPremium(true);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SplashScreen(),
                    ),
                  );
                },
                child: const Text('Premium Mode'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
