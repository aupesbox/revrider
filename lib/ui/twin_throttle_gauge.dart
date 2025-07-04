import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class TwinThrottleGauge extends StatelessWidget {
  final double value;
  const TwinThrottleGauge({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return SfRadialGauge(
      axes: [
        RadialAxis(
          minimum: 0,
          maximum: 100,
          interval: 20,
          showTicks: true,
          showLabels: true,
          axisLineStyle: const AxisLineStyle(thickness: 0.1, thicknessUnit: GaugeSizeUnit.factor),
          pointers: [
            RangePointer(
              value: value,
              width: 0.1,
              sizeUnit: GaugeSizeUnit.factor,
              color: Colors.pinkAccent,
            ),
            NeedlePointer(
              value: value,
              needleColor: Colors.cyanAccent,
              knobStyle: const KnobStyle(color: Colors.cyanAccent),
            ),
          ],
          annotations: [
            GaugeAnnotation(
              widget: Text(
                '${value.toInt()}%',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.cyanAccent,
                  fontFamily: 'RobotoMono',
                  fontWeight: FontWeight.bold,
                ),
              ),
              angle: 90,
              positionFactor: 0.6,
            ),
          ],
        ),
      ],
    );
  }
}
