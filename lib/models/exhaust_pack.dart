// lib/models/exhaust_pack.dart
class ExhaustPack {
  final String id;       // stable id, e.g., product id or UUID
  final String name;     // display name
  final String dirPath;  // absolute directory path
  final String source;   // "store" | "ai" | "local"
  final int version;

  ExhaustPack({
    required this.id,
    required this.name,
    required this.dirPath,
    required this.source,
    required this.version,
  });

  String get idlePath => '$dirPath/idle1.wav';
  String get midPath  => '$dirPath/mid.mp3';
  String get highPath => '$dirPath/high.mp3';
}
