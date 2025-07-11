// lib/providers/sound_bank_provider.dart

import 'package:flutter/foundation.dart';
import '../models/sound_bank.dart';
import '../services/sound_bank_service.dart';
import 'purchase_provider.dart';

class SoundBankProvider extends ChangeNotifier {
  final SoundBankService _svc = SoundBankService();
  late PurchaseProvider _purchaseProvider;

  List<SoundBank> banks = [];

  SoundBankProvider(this._purchaseProvider);

  /// Called by ProxyProvider when PurchaseProvider changes
  void updatePurchaseProvider(PurchaseProvider p) {
    _purchaseProvider = p;
    // update each bank’s purchased flag
    for (var b in banks) {
      b.purchased = _purchaseProvider.isItemPurchased(b.id);
    }
    notifyListeners();
  }

  /// Loads all banks from your backend or local JSON.
  Future<void> loadBanks() async {
    banks = await _svc.fetchAvailableBanks();
    // mark which are already purchased
    for (var b in banks) {
      b.purchased = _purchaseProvider.isItemPurchased(b.id);
    }
    notifyListeners();
  }

  /// Buy the given bank via IAP, then download it.
  Future<void> purchaseAndDownload(SoundBank bank) async {
    await _purchaseProvider.purchaseItem(bank.id);
    bank.purchased = true;
    notifyListeners();
    await _svc.downloadBank(bank);
    notifyListeners();
  }

  /// Whether the user owns that bank
  bool isPurchased(String bankId) => _purchaseProvider.isItemPurchased(bankId);
}
