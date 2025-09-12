import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';

class MapPanel extends StatefulWidget {
  const MapPanel({super.key});
  @override
  State<MapPanel> createState() => _MapPanelState();
}

class _MapPanelState extends State<MapPanel> {
  GoogleMapController? _gm;
  StreamSubscription<Position>? _sub;
  bool _follow = true;

  static const _fallback = CameraPosition(
    target: LatLng(18.5204, 73.8567), // Pune default
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    LocationService.instance.start();
    _sub = LocationService.instance.stream.listen((pos) {
      if (_gm != null && _follow) {
        _gm!.animateCamera(CameraUpdate.newLatLng(
          LatLng(pos.latitude, pos.longitude),
        ));
      }
      setState(() {}); // to update speed pill
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  double _speedKmh() {
    final p = LocationService.instance.last;
    if (p == null) return 0;
    // Position.speed is m/s
    return (p.speed.isFinite ? p.speed : 0) * 3.6;
  }

  @override
  Widget build(BuildContext context) {
    final speed = _speedKmh();

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GoogleMap(
            initialCameraPosition: _fallback,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: false,
            onMapCreated: (c) => _gm = c,
            onCameraMoveStarted: () {
              // if user pans the map, stop following
              setState(() => _follow = false);
            },
          ),
        ),
        // speed pill
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${speed.toStringAsFixed(0)} km/h', style: const TextStyle(color: Colors.white)),
          ),
        ),
        // follow toggle
        Positioned(
          left: 8,
          top: 8,
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => setState(() => _follow = true),
            child: const Text('Follow'),
          ),
        ),
      ],
    );
  }
}
