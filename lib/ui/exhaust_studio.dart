// lib/ui/exhaust_studio.dart

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../services/audio_manager.dart';
import 'app_scaffold.dart';

class ExhaustStudio extends StatefulWidget {
  const ExhaustStudio({Key? key}) : super(key: key);

  @override
  _ExhaustStudioState createState() => _ExhaustStudioState();
}

class _ExhaustStudioState extends State<ExhaustStudio> {
  // only visible in premium
  final List<String> profiles = ['default', 'sport', 'cruiser'];
  String selectedProfile = 'default';
  static const Map<ThrottleSegment, List<int>> _segmentBounds = {
    ThrottleSegment.start:     [0,    2500],
    ThrottleSegment.idle:      [2500, 4500],
    ThrottleSegment.firstGear: [4500, 6500],
    ThrottleSegment.secondGear:[6500, 8500],
    ThrottleSegment.thirdGear: [8500, 10500],
    ThrottleSegment.cruise:    [10500,12500],
    ThrottleSegment.cutoff:    [12500,14500],
  };
  UriAudioSource get _masterSource => AudioSource.asset(
    'assets/sounds/$selectedProfile/exhaust_all.mp3',
  );
  // pitch & master volume always available
  double pitchSens = 1.0;
  double volume    = 1.0;

  // preview slider + toggle
  double previewThrottle = 0.0;
  bool   isPreviewing    = false;

  AudioManager get audio => context.read<AppState>().audio;
  bool get isPremium     => context.watch<AppState>().isPremium;

  @override
  void initState() {
    super.initState();
    // preload segments but don’t start
    audio.init();
  }

  void _togglePreview() {
    if (isPreviewing) {
      audio.playCutoff();
    } else {
      audio.playStart();
      audio.updateThrottle(previewThrottle);
    }
    setState(() => isPreviewing = !isPreviewing);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Exhaust Studio',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1) Profile dropdown (premium only)
            if (isPremium) ...[
              Text('Sound Profile', style: Theme.of(context).textTheme.titleMedium),
              DropdownButton<String>(
                value: selectedProfile,
                items: profiles
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase())))
                    .toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => selectedProfile = v);
                  await audio.switchProfile(v);
                },
              ),
              const SizedBox(height: 24),
            ],

            // 2) Pitch Sensitivity
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

            // 3) Master Volume
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

            // 4) Preview Throttle slider
            Text('Preview Throttle: ${previewThrottle.toInt()}%'),
            Slider(
              value: previewThrottle,
              min: 0,
              max: 100,
              divisions: 100,
              label: '${previewThrottle.toInt()}%',
              onChanged: (v) {
                setState(() => previewThrottle = v);
                if (isPreviewing) {
                  ThrottleSegment seg;
                  if (v == 0) seg = ThrottleSegment.idle;
                  else if (v < 20) seg = ThrottleSegment.firstGear;
                  else if (v < 40) seg = ThrottleSegment.secondGear;
                  else if (v < 60) seg = ThrottleSegment.thirdGear;
                  else if (v < 80) seg = ThrottleSegment.cruise;
                  else seg = ThrottleSegment.cutoff;
                  //audio.updateThrottle(v);
                }
              },
            ),
            const SizedBox(height: 24),

            // 5) Preview button toggles start/stop
            ElevatedButton.icon(
              icon: Icon(isPreviewing ? Icons.stop : Icons.play_arrow),
              label: Text(isPreviewing ? 'Stop Preview' : 'Start Preview'),
              onPressed: _togglePreview,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),

            const SizedBox(height: 32),

            // 6) Calibration (shared)
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.tune),
                label: Text(isPremium ? 'Re-Calibrate Throttle' : 'Calibrate Throttle'),
                onPressed: () async {
                  final ok = await context.read<AppState>().calibrateThrottle();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'Calibrated!' : 'Calibration Failed')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// // lib/ui/exhaust_studio.dart
//
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../providers/app_state.dart';
// import 'app_scaffold.dart';
//
// class ExhaustStudio extends StatefulWidget {
//   const ExhaustStudio({super.key});
//
//   @override
//   _ExhaustStudioState createState() => _ExhaustStudioState();
// }
//
// class _ExhaustStudioState extends State<ExhaustStudio> {
//   final profiles = ['default', 'sport', 'cruiser'];
//   String selected    = 'default';
//   double crossfade   = 1.0;
//   double pitchSens   = 1.0;
//   double volume      = 1.0;
//   double previewThr  = 0.0;
//
//   @override
//   Widget build(BuildContext context) {
//     final appState  = context.watch<AppState>();
//     final audio     = appState.audio;
//     final isPremium = appState.isPremium;
//
//     return AppScaffold(
//       title: 'Exhaust Studio',
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//
//             // ── Premium-only: Profile selector & Preview ─────────────
//             if (isPremium) ...[
//               DropdownButton<String>(
//                 value: selected,
//                 items: profiles
//                     .map((p) => DropdownMenuItem(
//                   value: p,
//                   child: Text(p.toUpperCase()),
//                 ))
//                     .toList(),
//                 onChanged: (p) async {
//                   if (p == null) return;
//                   setState(() => selected = p);
//                   // only one argument:
//                   await audio.switchProfile(p);
//                 },
//               ),
//               const SizedBox(height: 16),
//
//               Text('Preview Throttle: ${previewThr.toInt()}%'),
//               Slider(
//                 value: previewThr,
//                 min: 0,
//                 max: 100,
//                 divisions: 100,
//                 label: '${previewThr.toInt()}%',
//                 onChanged: (v) {
//                   setState(() => previewThr = v);
//                   audio.updateThrottle(v);
//                 },
//               ),
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.play_arrow),
//                 label: const Text('Preview'),
//                 onPressed: () {
//                   audio.playStart();
//                   audio.updateThrottle(previewThr);
//                 },
//               ),
//               const Divider(height: 32),
//             ],
//
//             // ── Shared Sliders ───────────────────────────────────────
//             Text('Crossfade Rate: ${crossfade.toStringAsFixed(2)}'),
//             Slider(
//               value: crossfade,
//               min: 0.1,
//               max: 2.0,
//               divisions: 19,
//               label: crossfade.toStringAsFixed(2),
//               onChanged: (v) {
//                 setState(() => crossfade = v);
//                 audio.setCrossfadeRate(v);
//               },
//             ),
//             const SizedBox(height: 16),
//
//             Text('Pitch Sensitivity: ${pitchSens.toStringAsFixed(2)}'),
//             Slider(
//               value: pitchSens,
//               min: 0.1,
//               max: 3.0,
//               divisions: 29,
//               label: pitchSens.toStringAsFixed(2),
//               onChanged: (v) {
//                 setState(() => pitchSens = v);
//                 audio.setPitchSensitivity(v);
//               },
//             ),
//             const SizedBox(height: 16),
//
//             Text('Master Volume: ${(volume * 100).toInt()}%'),
//             Slider(
//               value: volume,
//               min: 0.0,
//               max: 1.0,
//               divisions: 100,
//               label: '${(volume * 100).toInt()}%',
//               onChanged: (v) {
//                 setState(() => volume = v);
//                 audio.setMasterVolume(v);
//               },
//             ),
//             const SizedBox(height: 32),
//
//             // ── Calibration Button ───────────────────────────────────
//             Center(
//               child: ElevatedButton.icon(
//                 icon: const Icon(Icons.tune),
//                 label: Text(isPremium ? 'Re-Calibrate Throttle' : 'Calibrate Throttle'),
//                 onPressed: () async {
//                   final ok = await appState.calibrateThrottle();
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text(ok ? 'Calibrated!' : 'Calibration failed')),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
