import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';

class TripCard extends StatefulWidget {
  const TripCard({super.key});
  @override
  State<TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<TripCard> {
  StreamSubscription<Position>? _sub;
  Position? _prev;
  double _distanceM = 0.0;
  Duration _elapsed = Duration.zero;
  bool _tracking = false;
  Timer? _timer;
  Position? _last;

  @override
  void initState() {
    super.initState();
    _sub = LocationService.instance.stream.listen((pos) {
      _last = pos;
      if (_tracking) {
        if (_prev != null) _distanceM += _haversine(_prev!, pos);
        _prev = pos;
        setState(() {}); // update speed readout
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  double _speedKmh() {
    final s = _last?.speed ?? 0.0; // m/s
    return s.isFinite ? s * 3.6 : 0.0;
  }

  String _fmtTime(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  double _haversine(Position a, Position b) {
    const R = 6371000.0; // meters
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final la1 = _deg2rad(a.latitude);
    final la2 = _deg2rad(b.latitude);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(la1) * math.cos(la2) * math.pow(math.sin(dLon / 2), 2);
    return 2 * R * math.asin(math.min(1, math.sqrt(h)));
  }

  double _deg2rad(double d) => d * math.pi / 180.0;

  void _start() {
    setState(() {
      _tracking = true;
      _prev = LocationService.instance.last;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  void _pause() {
    setState(() => _tracking = false);
    _timer?.cancel();
    _prev = null;
  }

  void _reset() {
    setState(() {
      _tracking = false;
      _distanceM = 0.0;
      _elapsed = Duration.zero;
      _prev = null;
    });
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final km = _distanceM / 1000.0;
    final speed = _speedKmh().toStringAsFixed(0);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _metric('Speed', speed, 'km/h'),
            const SizedBox(width: 14),
            _metric('Distance', km.toStringAsFixed(2), 'km'),
            const SizedBox(width: 14),
            _metric('Time', _fmtTime(_elapsed), ''),
            const Spacer(),
            if (!_tracking)
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: _start,
                tooltip: 'Start',
              )
            else
              IconButton(
                icon: const Icon(Icons.pause),
                onPressed: _pause,
                tooltip: 'Pause',
              ),
            IconButton(
              icon: const Icon(Icons.replay),
              onPressed: _reset,
              tooltip: 'Reset',
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            if (unit.isNotEmpty) const SizedBox(width: 4),
            if (unit.isNotEmpty) Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}
