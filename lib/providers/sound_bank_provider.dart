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

  /// In‐memory map of downloaded bank IDs to their on‐disk folder
  final Map<String, String> _localPaths = {};

  /// The full hierarchy of categories → brands → models
  final List<SoundBankCategory> banks;

  SoundBankProvider(this._service, this._purchases, this.banks) {
    _loadLocalPaths();
  }

  Future<void> _loadLocalPaths() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('localBankPaths') ?? '{}';
    _localPaths
      ..clear()
      ..addAll(Map<String, String>.from(jsonDecode(jsonStr)));
    notifyListeners();
  }

  /// Download & unzip a bank, then persist its local path
  // Future<void> purchaseAndDownload(String bankId, String zipUrl) async {
  //   final dirPath = await _service.downloadAndUnzip(bankId, zipUrl);
  //   if (dirPath != null) {
  //     _localPaths[bankId] = dirPath;
  //     final prefs = await SharedPreferences.getInstance();
  //     prefs.setString('localBankPaths', jsonEncode(_localPaths));
  //     notifyListeners();
  //   }
  // }

  /// Look up the local path for a bank, if downloaded
  String? localPathFor(String bankId) => _localPaths[bankId];
}