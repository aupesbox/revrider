// lib/ui/exhaust_studio.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'app_scaffold.dart';

class ExhaustStudio extends StatefulWidget {
  const ExhaustStudio({super.key});
  @override
  _ExhaustStudioState createState() => _ExhaustStudioState();
}

class _ExhaustStudioState extends State<ExhaustStudio> {
  final profiles   = ['default', 'sport', 'cruiser'];
  String selected  = 'default';
  double crossfade = 1.0;
  double pitchSens = 1.0;
  double volume    = 1.0;
  double previewThr = 0.0;

  @override
  Widget build(BuildContext context) {
    final appState  = context.watch<AppState>();
    final audio     = appState.audio;
    final isPremium = appState.isPremium;

    return AppScaffold(
      title: 'Exhaust Studio',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Premium UI
          if (isPremium) ...[
            DropdownButton<String>(
              value: selected,
              items: profiles
                  .map((p) =>
                  DropdownMenuItem(value: p, child: Text(p.toUpperCase())))
                  .toList(),
              onChanged: (v) async {
                if (v == null) return;
                setState(() => selected = v);
                await audio.switchProfile(v);
              },
            ),
            const SizedBox(height: 24),
            Text('Preview Throttle: ${previewThr.toInt()}%'),
            Slider(
              value: previewThr,
              min: 0, max: 100, divisions: 100,
              label: previewThr.toInt().toString(),
              onChanged: (v) {
                setState(() => previewThr = v);
                audio.updateThrottle(v);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Preview'),
              onPressed: () {
                audio.play();
                audio.updateThrottle(previewThr);
              },
            ),
            const Divider(height: 32),
          ],

          // Crossfade slider
          Text('Crossfade Rate: ${crossfade.toStringAsFixed(2)}'),
          Slider(
            value: crossfade,
            min: 0.1, max: 2.0, divisions: 19,
            label: crossfade.toStringAsFixed(2),
            onChanged: (v) {
              setState(() => crossfade = v);
              audio.setCrossfadeRate(v);
            },
          ),
          const SizedBox(height: 16),

          // Pitch sensitivity
          Text('Pitch Sensitivity: ${pitchSens.toStringAsFixed(2)}'),
          Slider(
            value: pitchSens,
            min: 0.1, max: 3.0, divisions: 29,
            label: pitchSens.toStringAsFixed(2),
            onChanged: (v) {
              setState(() => pitchSens = v);
              audio.setPitchSensitivity(v);
            },
          ),
          const SizedBox(height: 16),

          // Master volume
          Text('Master Volume: ${(volume * 100).toInt()}%'),
          Slider(
            value: volume,
            min: 0.0, max: 1.0, divisions: 100,
            label: '${(volume * 100).toInt()}%',
            onChanged: (v) {
              setState(() => volume = v);
              audio.setMasterVolume(v);
            },
          ),
          const SizedBox(height: 32),

          // Calibration for default/premium
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.tune),
              label: Text(isPremium ? 'Re-Calibrate Throttle' : 'Calibrate Throttle'),
              onPressed: () async {
                final ok = await appState.calibrateThrottle();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Calibrated!' : 'Calibration Failed')),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
