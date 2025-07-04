import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class RangeThrottleGauge extends StatelessWidget {
  final double value;
  const RangeThrottleGauge({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return SfRadialGauge(
      axes: [
        RadialAxis(
          minimum: 0,
          maximum: 100,
          showTicks: false,
          showLabels: false,
          ranges: [
            GaugeRange(startValue: 0, endValue: 50, color: Colors.greenAccent, startWidth: 10, endWidth: 10),
            GaugeRange(startValue: 50, endValue: 80, color: Colors.yellowAccent, startWidth: 10, endWidth: 10),
            GaugeRange(startValue: 80, endValue: 100, color: Colors.redAccent, startWidth: 10, endWidth: 10),
          ],
          pointers: [
            NeedlePointer(
              value: value,
              needleColor: Colors.cyanAccent,
              knobStyle: const KnobStyle(color: Colors.cyanAccent, knobRadius: 0.06, sizeUnit: GaugeSizeUnit.factor),
            ),
          ],
        ),
      ],
    );
  }
}
