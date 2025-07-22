// lib/ui/shop_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/models/offering_wrapper.dart';

import '../ui/app_scaffold.dart';
import '../providers/sound_bank_provider.dart';
import '../providers/purchase_provider.dart';
import '../models/sound_bank.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final Map<String, bool> _isLoading = {};

  @override
  Widget build(BuildContext context) {
    final soundProv    = context.watch<SoundBankProvider>();
    final purchaseProv = context.watch<PurchaseProvider>();
    // Offerings? → Offering?
    final offering     = purchaseProv.offerings?.current;
    final banks        = soundProv.banks;

    return AppScaffold(
      title: 'Shop Sounds',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final category in banks) ...[
            ExpansionTile(
              title: Text(category.name),
              children: [
                for (final brand in category.brands) ExpansionTile(
                  title: Text(brand.name),
                  children: [
                    for (final model in brand.models)
                      ListTile(
                        title: Text(model.name),
                        trailing: _actionButton(model, purchaseProv, soundProv, offering),
                      ),
                  ],
                )
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _actionButton(
      SoundBankModel model,
      PurchaseProvider purchaseProv,
      SoundBankProvider soundProv,
      Offering? offering,
      ) {
    final id          = model.id;
    final isPurchased = purchaseProv.isItemPurchased(id);
    final isInstalled = soundProv.localPathFor(id) != null;
    final isBusy      = _isLoading[id] == true;

    // getPackage is defined on Offering, not Offerings
    final pkg = offering?.getPackage(id);
    final price = pkg?.storeProduct.priceString ?? 'Buy';

    return ElevatedButton(
      onPressed: (isPurchased || isBusy)
          ? null
          : () async {
        setState(() => _isLoading[id] = true);
        try {
          // first purchase
          final bought = await purchaseProv.purchaseItem(id);
          if (!bought) throw Exception('Purchase failed');
          // then download & unzip
          await soundProv.purchaseAndDownload(id, model.zipUrl);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        } finally {
          setState(() => _isLoading[id] = false);
        }
      },
      child: isBusy
          ? const SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : Text(isInstalled ? 'Installed' : price),
    );
  }
}

// // lib/ui/shop_screen.dart
//
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:purchases_flutter/models/offerings_wrapper.dart';
//
// import '../ui/app_scaffold.dart';
// import '../providers/sound_bank_provider.dart';
// import '../providers/purchase_provider.dart';
// import '../models/sound_bank.dart';
//
// class ShopScreen extends StatefulWidget {
//   const ShopScreen({Key? key}) : super(key: key);
//
//   @override
//   State<ShopScreen> createState() => _ShopScreenState();
// }
//
// class _ShopScreenState extends State<ShopScreen> {
//   // Track which model is currently purchasing
//   final Map<String, bool> _isLoading = {};
//
//   @override
//   Widget build(BuildContext context) {
//     final soundProv    = context.watch<SoundBankProvider>();
//     final purchaseProv = context.watch<PurchaseProvider>();
//     final offering     = purchaseProv.offerings?.current;
//     final banks        = soundProv.banks;
//
//     return AppScaffold(
//       title: 'Shop Sounds',
//       child: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           for (final category in banks) ...[
//             ExpansionTile(
//               title: Text(category.name),
//               children: [
//                 for (final brand in category.brands) ExpansionTile(
//                   title: Text(brand.name),
//                   children: [
//                     for (final model in brand.models) ListTile(
//                       title: Text(model.name),
//                       trailing: _buildActionButton(model, purchaseProv, soundProv, offering),
//                     )
//                   ],
//                 )
//               ],
//             )
//           ]
//         ],
//       ),
//     );
//   }
//
//   Widget _buildActionButton(
//       SoundBankModel model,
//       PurchaseProvider purchaseProv,
//       SoundBankProvider soundProv,
//       Offerings? offering,
//       ) {
//     final id          = model.id;
//     final isPurchased = purchaseProv.isItemPurchased(id);
//     final isInstalled = soundProv.localPathFor(id) != null;
//     final isBusy      = _isLoading[id] == true;
//
//     // Find the RevenueCat package for this model (must match your Catalog package IDs)
//     final pkg = offering?.getPackage(id);
//
//     return ElevatedButton(
//       onPressed: isPurchased || isBusy
//           ? null
//           : () async {
//         setState(() => _isLoading[id] = true);
//         try {
//           // 1️⃣ Purchase via RevenueCat
//           final bought = await purchaseProv.purchaseItem(id);
//           if (!bought) throw Exception('Purchase failed');
//
//           // 2️⃣ Then download & unzip
//           await soundProv.purchaseAndDownload(id, model.zipUrl);
//         } catch (e) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Error: ${e.toString()}')),
//           );
//         } finally {
//           setState(() => _isLoading[id] = false);
//         }
//       },
//       child: isBusy
//           ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
//           : Text(
//         isInstalled
//             ? 'Installed'
//             : isPurchased
//             ? 'Download'
//             : (pkg?.storeProduct.priceString ?? 'Buy'),
//       ),
//     );
//   }
// }
//
// // // lib/ui/shop_screen.dart
// //
// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import '../providers/sound_bank_provider.dart';
// // import '../models/sound_bank.dart';
// // import 'app_scaffold.dart';
// //
// // /// Sound Bank Shop screen allows browsing and purchasing banks
// // class ShopScreen extends StatelessWidget {
// //   const ShopScreen({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final soundProv = context.watch<SoundBankProvider>();
// //     final banks = soundProv.banks;
// //
// //     return AppScaffold(
// //       title: 'Shop Sounds',
// //       child: ListView(
// //         padding: const EdgeInsets.all(16.0),
// //         children: banks.map((SoundBankCategory category) {
// //           return ExpansionTile(
// //             title: Text(category.name),
// //             children: category.brands.map((brand) {
// //               return ExpansionTile(
// //                 title: Text(brand.name),
// //                 children: brand.models.map((model) {
// //                   final installed = soundProv.localPathFor(model.id) != null;
// //                   return ListTile(
// //                     title: Text(model.name),
// //                     trailing: ElevatedButton(
// //                       onPressed: installed
// //                           ? null
// //                           : () async {
// //                         await soundProv.purchaseAndDownload(
// //                           model.id,
// //                           model.zipUrl,
// //                         );
// //                         ScaffoldMessenger.of(context).showSnackBar(
// //                           SnackBar(
// //                             content: Text('Downloaded ${model.name}'),
// //                           ),
// //                         );
// //                       },
// //                       child: Text(installed ? 'Installed' : 'Buy'),
// //                     ),
// //                   );
// //                 }).toList(),
// //               );
// //             }).toList(),
// //           );
// //         }).toList(),
// //       ),
// //     );
// //   }
// // }
// //
// // // // lib/ui/shop_screen.dart
// // //
// // // import 'package:flutter/material.dart';
// // // import 'package:provider/provider.dart';
// // //
// // // import '../ui/app_scaffold.dart';
// // // import '../providers/sound_bank_provider.dart';
// // //
// // // class ShopScreen extends StatelessWidget {
// // //   const ShopScreen({super.key});
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final soundProv = context.watch<SoundBankProvider>();
// // //     final banks = soundProv.banks;
// // //
// // //     return AppScaffold(
// // //       title: 'Shop Sounds',
// // //       child: ListView(
// // //         padding: const EdgeInsets.all(16),
// // //         children: banks.map((category) {
// // //           return ExpansionTile(
// // //             title: Text(category.name),
// // //             children: category.brands.map((brand) {
// // //               return ExpansionTile(
// // //                 title: Text(brand.name),
// // //                 children: brand.models.map((model) {
// // //                   final installed = soundProv.localPathFor(model.id) != null;
// // //                   return ListTile(
// // //                     title: Text(model.name),
// // //                     trailing: ElevatedButton(
// // //                       onPressed: installed
// // //                           ? null
// // //                           : () async {
// // //                         // supply both bankId and the ZIP URL
// // //                         await soundProv.purchaseAndDownload(
// // //                           model.id,
// // //                           model.zipUrl,
// // //                         );
// // //
// // //                         ScaffoldMessenger.of(context).showSnackBar(
// // //                           SnackBar(
// // //                             content: Text('Downloaded ${model.name}'),
// // //                           ),
// // //                         );
// // //                       },
// // //                       child: Text(installed ? 'Installed' : 'Buy'),
// // //                     ),
// // //                   );
// // //                 }).toList(),
// // //               );
// // //             }).toList(),
// // //           );
// // //         }).toList(),
// // //       ),
// // //     );
// // //   }
// // //
// // // }
