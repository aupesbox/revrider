import 'package:flutter/foundation.dart';
import '../services/activation_service.dart';

class ActivationProvider extends ChangeNotifier {
  final ActivationService _service = ActivationService();

  Map<String, dynamic>? _activation;
  bool get isActivated => _activation != null;
  bool get isPremium   => _activation?['tier'] == 'premium';

  /// Load activation from storage
  Future<void> load() async {
    _activation = await _service.getActivation();
    notifyListeners();
  }

  /// Save a new activation payload
  Future<void> activate(Map<String, dynamic> data) async {
    await _service.saveActivation(data);
    _activation = data;
    notifyListeners();
  }

  /// Clear activation (for testing)
  Future<void> clear() async {
    await _service.clearActivation();
    _activation = null;
    notifyListeners();
  }

  /// Expose data if you need details
  String? get deviceId      => _activation?['deviceId'] as String?;
  String? get tier          => _activation?['tier'] as String?;
  String? get activatedDate => _activation?['activatedDate'] as String?;
}
