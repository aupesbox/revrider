// lib/models/sound_bank.dart

/// Represents a single sound bank model (e.g., a specific bike model)
class SoundBankModel {
  final String id;
  final String name;
  final bool purchased;
  /// Master exhaust filename within this bank's folder
  final String masterFileName;
  final String zipUrl;

  SoundBankModel({
    required this.id,
    required this.name,
    required this.purchased,
    this.masterFileName = 'exhaust_all.mp3',
    required this.zipUrl,
  });

  factory SoundBankModel.fromJson(Map<String, dynamic> json) {
    return SoundBankModel(
      id: json['id'] as String,
      name: json['name'] as String,
      purchased: json['purchased'] as bool? ?? false,
      masterFileName: json['masterFileName'] as String? ?? 'exhaust_all.mp3',
      zipUrl: json['zipUrl'] as String,
    );
  }
}


/// Represents a brand containing multiple models
class SoundBankBrand {
  final String id;
  final String name;
  final List<SoundBankModel> models;

  SoundBankBrand({
    required this.id,
    required this.name,
    required this.models,
  });

  factory SoundBankBrand.fromJson(Map<String, dynamic> json) {
    return SoundBankBrand(
      id: json['id'] as String,
      name: json['name'] as String,
      models: (json['models'] as List)
          .map((item) => SoundBankModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}


/// Represents a top-level category (e.g., bike type) containing multiple brands
class SoundBankCategory {
  final String id;
  final String name;
  final List<SoundBankBrand> brands;

  SoundBankCategory({
    required this.id,
    required this.name,
    required this.brands,
  });

  factory SoundBankCategory.fromJson(Map<String, dynamic> json) {
    return SoundBankCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      brands: (json['brands'] as List)
          .map((item) => SoundBankBrand.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}