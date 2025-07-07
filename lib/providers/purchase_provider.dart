// lib/providers/purchase_provider.dart

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseProvider extends ChangeNotifier {
  bool _isPremium    = false;
  bool _devOverride  = false;   // new
  Offerings? _offerings;

  /// True if real-purchase or developer override is enabled
  bool get isPremium => _isPremium || _devOverride;

  /// Expose devOverride so we can bind it to a switch
  bool get devOverride => _devOverride;

  Offerings? get offerings => _offerings;

  PurchaseProvider() {
    _init();
  }

  Future<void> _init() async {
    Purchases.addCustomerInfoUpdateListener((info) {
      _isPremium = info.entitlements.all["premium"]?.isActive ?? false;
      notifyListeners();
    });
    try {
      _offerings = await Purchases.getOfferings();
      final info = await Purchases.getCustomerInfo();
      _isPremium = info.entitlements.all["premium"]?.isActive ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching offerings: $e");
    }
  }

  Future<void> purchasePremium() async {
    if (_offerings?.current == null) return;
    final pkg = _offerings!.current!.getPackage("premium_upgrade");
    if (pkg == null) return;
    try {
      await Purchases.purchasePackage(pkg);
    } catch (e) {
      debugPrint("Purchase failed: $e");
    }
  }

  Future<void> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
    } catch (e) {
      debugPrint("Restore failed: $e");
    }
  }

  /// Developer-only: force premium features on/off
  void setDevOverride(bool value) {
    _devOverride = value;
    notifyListeners();
  }
}

// // lib/providers/purchase_provider.dart
//
// import 'package:flutter/foundation.dart';
// import 'package:purchases_flutter/purchases_flutter.dart';
//
// class PurchaseProvider extends ChangeNotifier {
//   bool _isPremium = false;
//   Offerings? _offerings;
//
//   bool get isPremium => _isPremium;
//   Offerings? get offerings => _offerings;
//
//   PurchaseProvider() {
//     _init();
//   }
//
//   Future<void> _init() async {
//     // Listen for any customer info changes (purchase/restore)
//     Purchases.addCustomerInfoUpdateListener((info) {
//       _isPremium = info.entitlements.all["premium"]?.isActive ?? false;
//       notifyListeners();
//     });
//
//     // Fetch current offerings
//     try {
//       _offerings = await Purchases.getOfferings();
//       final info = await Purchases.getCustomerInfo();
//       _isPremium = info.entitlements.all["premium"]?.isActive ?? false;
//       notifyListeners();
//     } catch (e) {
//       debugPrint("Error fetching offerings: $e");
//     }
//   }
//
//   Future<void> purchasePremium() async {
//     if (_offerings == null) return;
//     final premiumOffering = _offerings!.current;
//     final package = premiumOffering?.getPackage("premium_upgrade");
//     if (package == null) return;
//     try {
//       await Purchases.purchasePackage(package);
//       // RevenueCat listener will update _isPremium
//     } catch (e) {
//       debugPrint("Purchase failed: $e");
//     }
//   }
//
//   Future<void> restorePurchases() async {
//     try {
//       await Purchases.restorePurchases();
//     } catch (e) {
//       debugPrint("Restore failed: $e");
//     }
//   }
// }
