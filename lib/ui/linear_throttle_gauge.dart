import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class LinearThrottleGauge extends StatelessWidget {
  final double value;
  const LinearThrottleGauge({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return SfLinearGauge(
      orientation: LinearGaugeOrientation.horizontal,
      minimum: 0,
      maximum: 100,
      markerPointers: [LinearShapePointer(value: value)],
      barPointers: [LinearBarPointer(value: value)],
    );
  }
}
