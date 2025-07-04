import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A simple service to persist and read activation data.
class ActivationService {
  static const _key = 'activation_info';

  /// Save the parsed QR payload (must be a Map with deviceId, tier, activatedDate).
  Future<void> saveActivation(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(data);
    await prefs.setString(_key, jsonString);
  }

  /// Return null if not activated yet.
  Future<Map<String, dynamic>?> getActivation() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return null;
    final decoded = jsonDecode(jsonString);
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  }

  /// Remove activation (for testing / logout).
  Future<void> clearActivation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
