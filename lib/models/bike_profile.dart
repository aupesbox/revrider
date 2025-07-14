// lib/models/bike_profile.dart

/// Top‐level category (e.g. “Sport”, “Cruiser”)
class BikeCategory {
  final String id;
  final String name;
  final List<BikeBrand> brands;

  BikeCategory({
    required this.id,
    required this.name,
    required this.brands,
  });
}

/// Brand under a category (e.g. “Yamaha”, “Harley”)
class BikeBrand {
  final String id;
  final String name;
  final List<BikeModel> models;

  BikeBrand({
    required this.id,
    required this.name,
    required this.models,
  });
}

/// Specific model (e.g. “Ninja”, “Road King”) with its asset folder
class BikeModel {
  final String id;
  final String name;
  final String assetFolder;

  BikeModel({
    required this.id,
    required this.name,
    required this.assetFolder,
  });
}
