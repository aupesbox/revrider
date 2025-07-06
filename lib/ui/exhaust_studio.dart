// lib/ui/exhaust_studio.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_manager.dart';
import '../providers/purchase_provider.dart';
import 'app_scaffold.dart';

class ExhaustStudio extends StatefulWidget {
  const ExhaustStudio({Key? key}) : super(key: key);

  @override
  _ExhaustStudioState createState() => _ExhaustStudioState();
}

class _ExhaustStudioState extends State<ExhaustStudio> {
  final AudioManager audio = AudioManager();

  // full list; we’ll filter based on premium entitlement
  final List<String> allProfiles = ['default', 'sport', 'cruiser'];
  String selected = 'default';

  double crossfade = 1.0;
  double pitchSens = 1.0;
  double volume    = 1.0;

  // slider to preview throttle % in-app
  double previewThrottle = 0.0;

  @override
  void initState() {
    super.initState();
    audio.init().then((_) {
      audio.setMasterVolume(volume);
      audio.setCrossfadeRate(crossfade);
      audio.setPitchSensitivity(pitchSens);
      audio.updateThrottle(previewThrottle);
      audio.play();
    });
  }

  @override
  void dispose() {
    audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PurchaseProvider>().isPremium;
    // only show non-default profiles if user is premium
    final profiles = isPremium
        ? allProfiles
        : ['default'];

    // ensure current selection is valid
    if (!profiles.contains(selected)) {
      selected = profiles.first;
    }

    return AppScaffold(
      title: 'Exhaust Studio',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Selector
            DropdownButton<String>(
              value: selected,
              items: profiles
                  .map((p) => DropdownMenuItem(
                value: p,
                child: Text(p.toUpperCase()),
              ))
                  .toList(),
              onChanged: (v) async {
                if (v == null) return;
                setState(() => selected = v);
                await audio.switchProfile(selected);
              },
            ),
            const SizedBox(height: 24),

            // Crossfade Rate
            Text('Crossfade Rate: ${crossfade.toStringAsFixed(2)}'),
            Slider(
              value: crossfade,
              min: 0.1,
              max: 2.0,
              divisions: 19,
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
              min: 0.1,
              max: 3.0,
              divisions: 29,
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

            // Throttle Preview Slider
            Text('Preview Throttle: ${previewThrottle.toInt()}%'),
            Slider(
              value: previewThrottle,
              min: 0,
              max: 100,
              divisions: 100,
              label: previewThrottle.toInt().toString(),
              onChanged: (v) {
                setState(() => previewThrottle = v);
                audio.updateThrottle(v);
              },
            ),
            const SizedBox(height: 24),

            // Preview Button
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Preview'),
              onPressed: () {
                audio.play();
                audio.updateThrottle(previewThrottle);
              },
            ),
          ],
        ),
      ),
    );
  }
}
