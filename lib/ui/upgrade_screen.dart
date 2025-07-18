// lib/ui/upgrade_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'app_scaffold.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

    Widget planCard({
      required String title,
      required String price,
      required String description,
      required String imageAsset,
      required VoidCallback onBuy,
    }) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Image.asset(imageAsset, height: 120, fit: BoxFit.contain),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(price, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onBuy,
              child: const Text('Buy Now'),
            ),
          ]),
        ),
      );
    }

    return AppScaffold(
      title: 'Upgrade to Premium',
      child: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Unlock all features:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          planCard(
            title: 'App-Only Premium',
            price: '₹599 / year',
            description: 'Get 30+ exhaust banks, calibration, and Spotify integration.',
            imageAsset: 'assets/images/app_only.png',
            onBuy: () {
              // TODO: wire real IAP
              //appState.setPremium(true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App-Only Premium Activated')),
              );
            },
          ),
          planCard(
            title: 'App + Device Bundle',
            price: '₹6,999 one-time',
            description: 'Includes premium device with clip-on throttle sensor + full app features.',
            imageAsset: 'assets/images/app_device.png',
            onBuy: () {
              // TODO: wire real IAP
              //appState.setPremium(true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bundle Purchased')),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
