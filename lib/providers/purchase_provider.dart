// lib/providers/purchase_provider.dart

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseProvider extends ChangeNotifier {
  bool _isPremium   = true;
  bool _devOverride = true;   // allow QA / dev to override
  Offerings? _offerings;
  CustomerInfo? _customerInfo;
  CustomerInfo? get customerInfo => _customerInfo;
  /// Tracks all active entitlement IDs
  final Set<String> _purchasedItems = {};

  /// true if user has purchased the “premium” entitlement or devOverride==true
  bool get isPremium => _isPremium || _devOverride;

  /// Developer toggle to force premium (for testing)
  //bool get devOverride => _devOverride;

  // Minimal local state to track entitlements if you don’t already have it.
  final Set<String> _ownedProductIds = <String>{};

// UI helper: does the user own this product?
  bool isPurchased(String productId) {
    return _ownedProductIds.contains(productId);
  }

// UI helper: buy a product (stub for now; integrate your real IAP here)
  Future<bool> purchase(String productId) async {
    try {
      // TODO: replace with real in-app purchase flow.
      // Mark owned for UI so things update:
      _ownedProductIds.add(productId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Available offerings (packages/prices) from RevenueCat
  Offerings? get offerings => _offerings;

  /// True if this [itemId] entitlement is active
  bool isItemPurchased(String itemId) {
    return _purchasedItems.contains(itemId);
  }

  PurchaseProvider() {
    _init();
  }

  Future<void> _init() async {
    // Listen to any remote entitlement changes (e.g. restores)
    Purchases.addCustomerInfoUpdateListener((info) {
      _syncCustomerInfo(info);
    });

    try {
      // Fetch your product offerings
      _offerings = await Purchases.getOfferings();
      // And fetch current purchaser info
      final info = await Purchases.getCustomerInfo();
      _syncCustomerInfo(info);
    } catch (e) {
      debugPrint('⚠️ RevenueCat init error: $e');
    }
  }

  void _syncCustomerInfo(CustomerInfo info) {
    // Your “premium” entitlement ID in RevenueCat
    _isPremium = info.entitlements.all['premium']?.isActive ?? false;

    // Keep track of every active entitlement
    _purchasedItems
      ..clear()
      ..addAll(info.entitlements.active.keys);

    notifyListeners();
  }

  /// Purchase the one‐time “premium_upgrade” package
  Future<bool> purchasePremium() async {
    final offering = _offerings?.current;
    if (offering == null) return false;
    final pkg = offering.getPackage('premium_upgrade');
    if (pkg == null) return false;

    try {
      final info = await Purchases.purchasePackage(pkg);
      _syncCustomerInfo(info);
      return isPremium;
    } on PurchasesError catch (e) {
      debugPrint('❌ PurchasePremium failed: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Unknown error purchasing premium: $e');
      return false;
    }
  }

  /// Purchase any entitlement/product by its identifier
  Future<bool> purchaseItem(String itemId) async {
    try {
      final info = await Purchases.purchaseProduct(itemId);
      _syncCustomerInfo(info);
      return isItemPurchased(itemId);
    } on PurchasesError catch (e) {
      debugPrint('❌ purchaseItem($itemId) failed: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Unknown error purchasing $itemId: $e');
      return false;
    }
  }

  /// Restore all previously made purchases
  Future<void> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      _syncCustomerInfo(info);
    } catch (e) {
      debugPrint('❌ RestorePurchases failed: $e');
    }
  }

  /// Developer‐only: force premium features on/off
  void setDevOverride(bool value) {
    _devOverride = value;
    notifyListeners();
  }
// lib/providers/purchase_provider.dart

// … existing code …

  /// Track arbitrary product entitlements (e.g. sound‐bank IDs).
  final Set<String> _ownedItems = {};

  /// Purchase a single item by ID.




}
