// lib/ui/shop_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ui/app_scaffold.dart';
import '../providers/sound_bank_provider.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final soundProv = context.watch<SoundBankProvider>();
    final banks = soundProv.banks;

    return AppScaffold(
      title: 'Shop Sounds',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: banks.map((category) {
          return ExpansionTile(
            title: Text(category.name),
            children: category.brands.map((brand) {
              return ExpansionTile(
                title: Text(brand.name),
                children: brand.models.map((model) {
                  final installed = soundProv.localPathFor(model.id) != null;
                  return ListTile(
                    title: Text(model.name),
                    trailing: ElevatedButton(
                      onPressed: installed
                          ? null
                          : () async {
                        // supply both bankId and the ZIP URL
                        await soundProv.purchaseAndDownload(
                          model.id,
                          model.zipUrl,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Downloaded ${model.name}'),
                          ),
                        );
                      },
                      child: Text(installed ? 'Installed' : 'Buy'),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

}
