// lib/ui/widgets/map_panel.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPanel extends StatelessWidget {
  const MapPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: const GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(18.5204, 73.8567), // Pune as a neutral default
          zoom: 14,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        compassEnabled: true,
        mapToolbarEnabled: false,
      ),
    );
  }
}
