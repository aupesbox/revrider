import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class ThrottleGauge extends StatelessWidget {
  final double value;
  const ThrottleGauge({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return SfRadialGauge(
      axes: [
        RadialAxis(
          minimum: 0,
          maximum: 100,
          showLabels: false,
          showTicks: false,
          axisLineStyle: const AxisLineStyle(thickness: 0.2, thicknessUnit: GaugeSizeUnit.factor),
          pointers: [
            RangePointer(
              value: value,
              width: 0.2,
              sizeUnit: GaugeSizeUnit.factor,
              color: Theme.of(context).colorScheme.secondary,
            ),
            NeedlePointer(value: value),
          ],
          annotations: [
            GaugeAnnotation(
              widget: Text('${value.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 18)),
              positionFactor: 0.7,
              angle: 90,
            ),
          ],
        ),
      ],
    );
  }
}
