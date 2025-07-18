// lib/ui/exhaust_studio.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'app_scaffold.dart';

/// Exhaust Studio screen: calibration, music mix, and audio preview controls.
class ExhaustStudio extends StatelessWidget {
  const ExhaustStudio({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return AppScaffold(
      title: 'Exhaust Studio',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Calibration Button
            ElevatedButton.icon(
              icon: const Icon(Icons.tune),
              label: const Text('Re-Calibrate Throttle'),
              onPressed: app.isConnected
                  ? () => app.calibrateThrottle()
                  : null,
            ),
            const SizedBox(height: 24),

            // Music Enable Switch
            SwitchListTile(
              title: const Text('Enable Music'),
              value: app.musicEnabled,
              onChanged: app.isConnected
                  ? (on) => app.setMusicMix(
                enabled: on,
                engineVol: app.engineVolume,
                musicVol: app.musicVolume,
              )
                  : null,
            ),
            const SizedBox(height: 16),

            // Engine Volume Slider
            Text('Engine Volume: ${(app.engineVolume * 100).round()}%'),
            Slider(
              value: app.engineVolume,
              min: 0,
              max: 1,
              divisions: 20,
              label: '${(app.engineVolume * 100).round()}%',
              onChanged: app.isConnected
                  ? (v) => app.setEngineVolume(v)
                  : null,
            ),
            const SizedBox(height: 16),

            // Music Volume Slider
            Text('Music Volume: ${(app.musicVolume * 100).round()}%'),
            Slider(
              value: app.musicVolume,
              min: 0,
              max: 1,
              divisions: 20,
              label: '${(app.musicVolume * 100).round()}%',
              onChanged: app.isConnected
                  ? (v) => app.setMusicVolume(v)
                  : null,
            ),
            const SizedBox(height: 24),

            // Ducking Threshold Slider
            Text('Duck Threshold: ${(app.duckThreshold * 100).round()}%'),
            Slider(
              value: app.duckThreshold,
              min: 0,
              max: 1,
              divisions: 20,
              label: '${(app.duckThreshold * 100).round()}%',
              onChanged: app.isConnected
                  ? (v) => app.setDuckingThreshold(v)
                  : null,
            ),
            const SizedBox(height: 16),

            // Duck Volume Factor Slider
            Text('Duck Volume Factor: ${(app.duckVolumeFactor * 100).round()}%'),
            Slider(
              value: app.duckVolumeFactor,
              min: 0,
              max: 1,
              divisions: 20,
              label: '${(app.duckVolumeFactor * 100).round()}%',
              onChanged: app.isConnected
                  ? (v) => app.setDuckVolumeFactor(v)
                  : null,
            ),
            const SizedBox(height: 24),

            // Crossfade Rate Slider
            Text('Crossfade Rate: ${(app.crossfadeRate * 100).round()}%'),
            Slider(
              value: app.crossfadeRate,
              min: 0,
              max: 1,
              divisions: 20,
              label: '${(app.crossfadeRate * 100).round()}%',
              onChanged: app.isConnected
                  ? (v) => app.setCrossfadeRate(v)
                  : null,
            ),
            const SizedBox(height: 24),

            // Preview Throttle Button
            ElevatedButton(
              onPressed: app.isConnected
                  ? () => app.audio.updateThrottle(50)
                  : null,
              child: const Text('Preview Throttle'),
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
// import '../providers/sound_bank_provider.dart';
// import '../models/sound_bank.dart';
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
//   String? _selectedCategory;
//   String? _selectedBrand;
//   String? _selectedModel;
//   String? _selectedTrackId;
//
//   @override
//   void initState() {
//     super.initState();
//     final app = context.read<AppState>();
//     _selectedTrackId = app.selectedLocalTrackId;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final app = context.watch<AppState>();
//     final prov = context.watch<SoundBankProvider>();
//
//     // Build category/brand/model lists
//     final categories = prov.banks;
//     final brands = _selectedCategory == null
//         ? <SoundBankBrand>[]
//         : categories.firstWhere((c) => c.id == _selectedCategory!).brands;
//     final models = _selectedBrand == null
//         ? <SoundBankModel>[]
//         : brands.firstWhere((b) => b.id == _selectedBrand!).models;
//
//     return AppScaffold(
//       title: 'Exhaust Studio',
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 1) Category Dropdown
//             const Text('Select Bike Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             DropdownButton<String>(
//               value: _selectedCategory,
//               hint: const Text('Category'),
//               isExpanded: true,
//               items: categories.map((c) => DropdownMenuItem(
//                 value: c.id,
//                 child: Text(c.name),
//               )).toList(),
//               onChanged: app.isPremium
//                   ? (value) {
//                 setState(() {
//                   _selectedCategory = value;
//                   _selectedBrand = null;
//                   _selectedModel = null;
//                 });
//               }
//                   : null,
//             ),
//             const SizedBox(height: 16),
//
//             // 2) Brand Dropdown
//             const Text('Select Brand', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             DropdownButton<String>(
//               value: _selectedBrand,
//               hint: const Text('Brand'),
//               isExpanded: true,
//               items: brands.map((b) => DropdownMenuItem(
//                 value: b.id,
//                 child: Text(b.name),
//               )).toList(),
//               onChanged: app.isPremium && _selectedCategory != null
//                   ? (value) {
//                 setState(() {
//                   _selectedBrand = value;
//                   _selectedModel = null;
//                 });
//               }
//                   : null,
//             ),
//             const SizedBox(height: 16),
//
//             // 3) Model Dropdown
//             const Text('Select Model', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             DropdownButton<String>(
//               value: _selectedModel,
//               hint: const Text('Model'),
//               isExpanded: true,
//               items: models.map((m) => DropdownMenuItem(
//                 value: m.id,
//                 child: Text(m.name),
//               )).toList(),
//               onChanged: app.isPremium && _selectedBrand != null
//                   ? (value) {
//                 setState(() {
//                   _selectedModel = value;
//                 });
//                 final model = models.firstWhere((m) => m.id == value);
//                 app.setSelectedBank(
//                   model.id,
//                   localPath: prov.localPathFor(model.id),
//                   masterFileName: model.masterFileName,
//                 );
//               }
//                   : null,
//             ),
//             const SizedBox(height: 24),
//
//             // 4) Music Track Dropdown
//             const Text('Select Music Track', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             DropdownButton<String>(
//               value: app.spotifyAuthenticated ? 'spotify' : _selectedTrackId,
//               isExpanded: true,
//               items: [
//                 ...app.defaultTracks.map((t) => DropdownMenuItem(
//                   value: t.id,
//                   child: Text(t.name),
//                 )),
//                 if (app.spotifyAuthenticated)
//                   const DropdownMenuItem(
//                     value: 'spotify',
//                     child: Text('Spotify Playback'),
//                   ),
//               ],
//               onChanged: (val) {
//                 if (val == 'spotify') {
//                   app.authenticateSpotify();
//                   app.setMusicMix(
//                     enabled: true,
//                     engineVol: app.engineVolume,
//                     musicVol: app.musicVolume,
//                   );
//                 } else if (val != null) {
//                   setState(() => _selectedTrackId = val);
//                   app.setSelectedLocalTrack(val);
//                 }
//               },
//             ),
//             const SizedBox(height: 16),
//
//             // 5) Enable Music Switch
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text('Enable Music'),
//                 Switch(
//                   value: app.musicEnabled,
//                   onChanged: (on) => app.setMusicMix(
//                     enabled: on,
//                     engineVol: app.engineVolume,
//                     musicVol: app.musicVolume,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//
//             // 6) Volume Sliders
//             Text('Engine Volume: ${(app.engineVolume * 100).round()}%'),
//             Slider(
//               value: app.engineVolume,
//               min: 0,
//               max: 1,
//               divisions: 20,
//               onChanged: app.isPremium
//                   ? (v) => app.setMusicMix(
//                 enabled: app.musicEnabled,
//                 engineVol: v,
//                 musicVol: app.musicVolume,
//               )
//                   : null,
//             ),
//             const SizedBox(height: 16),
//             Text('Music Volume: ${(app.musicVolume * 100).round()}%'),
//             Slider(
//               value: app.musicVolume,
//               min: 0,
//               max: 1,
//               divisions: 20,
//               onChanged: app.isPremium
//                   ? (v) => app.setMusicMix(
//                 enabled: app.musicEnabled,
//                 engineVol: app.engineVolume,
//                 musicVol: v,
//               )
//                   : null,
//             ),
//             const SizedBox(height: 24),
//
//             // 7) Ducking Controls
//             Text('Duck Threshold: ${(app.duckThreshold * 100).round()}%'),
//             Slider(
//               value: app.duckThreshold,
//               min: 0,
//               max: 1,
//               divisions: 20,
//               onChanged:
//               app.isPremium ? (v) => app.setDuckingThreshold(v) : null,
//             ),
//             const SizedBox(height: 12),
//             Text('Duck Volume Factor: ${(app.duckVolumeFactor * 100).round()}%'),
//             Slider(
//               value: app.duckVolumeFactor,
//               min: 0,
//               max: 1,
//               divisions: 20,
//               onChanged:
//               app.isPremium ? (v) => app.setDuckVolumeFactor(v) : null,
//             ),
//             const SizedBox(height: 12),
//             Text('Crossfade Rate: ${(app.crossfadeRate * 100).round()}%'),
//             // Slider(
//             //   value: app.crossfadeRate,
//             //   min: 0,
//             //   max: 1,
//             //   divisions: 20,
//             //   //onChanged:
//             //   //app.isPremium ? (v) => app.setCrossfadeRate(v) : null,
//             // ),
//             const SizedBox(height: 24),
//
//             // 8) Preview Throttle Button
//             Center(
//               child: ElevatedButton(
//                 onPressed: () async {
//                   app.audio.playStart();
//                   // // Ensure the default bank+file are loaded first:
//                   // await context.read<AppState>().audio.loadBank('default');
//                   // // Give the engine a moment to bind the source:
//                   // await Future.delayed(const Duration(milliseconds: 100));
//                   // // Then kick off throttle=50%
//                   // await context.read<AppState>().audio.updateThrottle(50);
//                 },
//                 child: const Text('Preview Throttle'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }