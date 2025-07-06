// lib/ui/upgrade_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/purchase_provider.dart';
import 'app_scaffold.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final purchase = context.watch<PurchaseProvider>();
    final isPremium = purchase.isPremium;
    final offering  = purchase.offerings?.current;
    final package   = offering?.getPackage("premium_upgrade");

    return AppScaffold(
      title: 'Upgrade to Premium',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isPremium) ...[
              const Icon(Icons.verified, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'You are a Premium user!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ] else if (offering == null) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading offer…'),
            ] else ...[
              Text(
                'Unlock all premium features for',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                package!.storeProduct.priceString,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => purchase.purchasePremium(),
                child: Text('Buy Now — ${package.storeProduct.priceString}'),
              ),
              TextButton(
                onPressed: () => purchase.restorePurchases(),
                child: const Text('Restore Purchases'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
