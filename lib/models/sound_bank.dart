// lib/models/sound_bank.dart
class SoundBank {
  final String id;          // “cruiser_power”, matches your IAP SKU
  final String name;        // “Cruiser – Power”
  final String zipUrl;      // CDN URL to download bank.zip
  bool purchased;           // from your PurchaseProvider
  bool downloaded;          // true once unpacked locally
  String? localPath;        // folder under documentsDir/

  SoundBank({
    required this.id,
    required this.name,
    required this.zipUrl,
    this.purchased = false,
    this.downloaded = false,
    this.localPath,
  });
}
