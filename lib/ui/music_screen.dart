// lib/ui/music_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_manager.dart';
import '../providers/purchase_provider.dart';
import 'app_scaffold.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({Key? key}) : super(key: key);
  @override
  _MusicScreenState createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final AudioManager audio = AudioManager();

  // demo track list
  final List<String> tracks = ['demo_song.mp3'];
  String selectedTrack = 'demo_song.mp3';

  // 0.0 = all engine, 1.0 = all music
  double musicVol = 0.5;

  @override
  void initState() {
    super.initState();
    // initialize engine loops
    audio.init().then((_) {
      audio.play();
    });
  }

  @override
  void dispose() {
    audio.dispose();
    super.dispose();
  }

  Future<void> _loadMusic() async {
    // ensure music asset is loaded & then play
    await audio.loadMusicAsset('assets/music/$selectedTrack');
    audio.playMusic();
    audio.setMusicMix(musicVol);
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PurchaseProvider>().isPremium;

    return AppScaffold(
      title: 'Music Mode',
      child: isPremium
          ? Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Track selector
            DropdownButton<String>(
              value: selectedTrack,
              items: tracks
                  .map((t) => DropdownMenuItem(
                value: t,
                child: Text(t),
              ))
                  .toList(),
              onChanged: (t) {
                if (t == null) return;
                setState(() => selectedTrack = t);
                _loadMusic();
              },
            ),
            const SizedBox(height: 24),

            // Music vs Engine mix
            Text('Music / Engine Mix: ${(musicVol * 100).toInt()}%'),
            Slider(
              value: musicVol,
              min: 0,
              max: 1,
              divisions: 100,
              label: '${(musicVol * 100).toInt()}%',
              onChanged: (v) {
                setState(() => musicVol = v);
                audio.setMusicMix(v);
              },
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play Music'),
                  onPressed: _loadMusic,
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause Music'),
                  onPressed: () => audio.pauseMusic(),
                ),
              ],
            ),
          ],
        ),
      )
          : Center(
        child: Text(
          'Music Mode is Premium-Only.\nUpgrade to unlock.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
