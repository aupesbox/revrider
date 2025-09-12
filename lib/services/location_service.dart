import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();
  static final instance = LocationService._();

  final _ctrl = StreamController<Position>.broadcast();
  Stream<Position> get stream => _ctrl.stream;

  Position? last;
  StreamSubscription<Position>? _sub;

  Future<bool> ensurePermission() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (p == LocationPermission.deniedForever || p == LocationPermission.denied) return false;
    return true;
  }

  Future<void> start() async {
    if (!await ensurePermission()) return;
    _sub?.cancel();
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 3),
    ).listen((pos) {
      last = pos;
      _ctrl.add(pos);
    });
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
