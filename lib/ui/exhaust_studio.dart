import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/activation_provider.dart';
import '../services/audio_manager.dart';
import 'app_scaffold.dart';

class ExhaustStudio extends StatefulWidget {
  const ExhaustStudio({super.key});

  @override
  _ExhaustStudioState createState() => _ExhaustStudioState();
}

class _ExhaustStudioState extends State<ExhaustStudio> {
  final AudioManager audio = AudioManager();
  final List<String> allProfiles = ['default', 'sport', 'cruiser'];

  String selected = 'default';
  double crossfade = 1.0;
  double pitchSens = 1.0;
  double volume = 1.0;

  @override
  void initState() {
    super.initState();
    audio.init().then((_) {
      audio.setMasterVolume(volume);
      audio.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<ActivationProvider>().isPremium;
    // Only default for non-premium users
    final profiles = isPremium ? allProfiles : ['default'];
    // ensure selected is valid
    if (!profiles.contains(selected)) {
      selected = profiles.first;
    }

    return AppScaffold(
      title: 'Exhaust Studio',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile selector
            DropdownButton<String>(
              value: selected,
              items: profiles
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase())))
                  .toList(),
              onChanged: (v) async {
                selected = v!;
                await audio.switchProfile(selected);
                setState(() {});
              },
            ),
            const SizedBox(height: 24),

            // Crossfade Rate
            Text('Crossfade Rate: ${crossfade.toStringAsFixed(2)}'),
            Slider(
              value: crossfade,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: crossfade.toStringAsFixed(2),
              onChanged: (v) {
                setState(() => crossfade = v);
                audio.setCrossfadeRate(v);
              },
            ),
            const SizedBox(height: 16),

            // Pitch Sensitivity
            Text('Pitch Sensitivity: ${pitchSens.toStringAsFixed(2)}'),
            Slider(
              value: pitchSens,
              min: 0.5,
              max: 3.0,
              divisions: 25,
              label: pitchSens.toStringAsFixed(2),
              onChanged: (v) {
                setState(() => pitchSens = v);
                audio.setPitchSensitivity(v);
              },
            ),
            const SizedBox(height: 16),

            // Master Volume
            Text('Master Volume: ${(volume * 100).toInt()}%'),
            Slider(
              value: volume,
              min: 0.0,
              max: 1.0,
              divisions: 100,
              label: '${(volume * 100).toInt()}%',
              onChanged: (v) {
                setState(() => volume = v);
                audio.setMasterVolume(v);
              },
            ),
            const SizedBox(height: 24),

            // Preview Button
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Preview'),
              onPressed: () {
                audio.play();
              },
            ),
          ],
        ),
      ),
    );
  }
}
