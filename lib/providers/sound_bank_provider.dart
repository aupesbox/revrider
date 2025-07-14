// lib/providers/sound_bank_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sound_bank.dart';
import '../services/sound_bank_service.dart';
import 'purchase_provider.dart';

class SoundBankProvider extends ChangeNotifier {
  final SoundBankService _service;
  final PurchaseProvider _purchases;

  /// Persisted map: bankId → local on-disk path
  final Map<String, String> _localPaths = {};

  /// In-memory catalog hierarchy
  List<SoundBankCategory> banks = [];

  SoundBankProvider(
      this._service,
      this._purchases,
      ) {
    _loadLocalPaths();
    _loadCatalog();
  }

  Future<void> _loadLocalPaths() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('localBankPaths') ?? '{}';
    _localPaths
      ..clear()
      ..addAll(
        Map<String, String>.from(
          jsonDecode(jsonStr) as Map<String, dynamic>,
        ),
      );
    notifyListeners();
  }

  Future<void> _loadCatalog() async {
    try {
      banks = await _service.fetchCatalog();
    } catch (e) {
      debugPrint('Error loading catalog: $e');
    }
    notifyListeners();
  }

  /// Purchases and downloads a bank, then persists its path
  Future<void> purchaseAndDownload(
      String bankId,
      String zipUrl,
      ) async {
    final dir = await _service.downloadAndUnzip(bankId, zipUrl);
    if (dir != null) {
      _localPaths[bankId] = dir;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'localBankPaths',
        jsonEncode(_localPaths),
      );
      notifyListeners();
    }
  }

  /// Lookup local path for a downloaded bank (or null if not downloaded)
  String? localPathFor(String bankId) => _localPaths[bankId];
}
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/sound_bank.dart';
// import '../services/sound_bank_service.dart';
// import 'purchase_provider.dart';
//
// class SoundBankProvider extends ChangeNotifier {
//   final SoundBankService _service;
//   final PurchaseProvider _purchases;
//
//   /// In‐memory map of downloaded bank IDs to their on‐disk folder
//   final Map<String, String> _localPaths = {};
//
//   /// The full hierarchy of categories → brands → models
//   final List<SoundBankCategory> banks;
//
//   SoundBankProvider(this._service, this._purchases, this.banks) {
//     _loadLocalPaths();
//   }
//
//   Future<void> _loadLocalPaths() async {
//     final prefs = await SharedPreferences.getInstance();
//     final jsonStr = prefs.getString('localBankPaths') ?? '{}';
//     _localPaths
//       ..clear()
//       ..addAll(Map<String, String>.from(jsonDecode(jsonStr)));
//     notifyListeners();
//   }
//
//   /// Download & unzip a bank, then persist its local path
//   Future<void> purchaseAndDownload(String bankId, String zipUrl) async {
//     final dirPath = await _service.downloadAndUnzip(bankId, zipUrl);
//     if (dirPath != null) {
//       _localPaths[bankId] = dirPath;
//       final prefs = await SharedPreferences.getInstance();
//       prefs.setString('localBankPaths', jsonEncode(_localPaths));
//       notifyListeners();
//     }
//   }
//
//   /// Look up the local path for a bank, if downloaded
//   String? localPathFor(String bankId) => _localPaths[bankId];
// }