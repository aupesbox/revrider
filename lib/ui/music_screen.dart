// lib/ui/music_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'app_scaffold.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});
  @override
  _MusicScreenState createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final tracks = ['demo_song.mp3'];
  String selectedTrack = 'demo_song.mp3';
  double musicVol = 0.5;

  Future<void> _loadAndPlay(String track, AppState appState) async {
    appState.setCurrentTrack(track);
    final audio = appState.audio;
    await audio.loadMusicAsset('assets/music/$track');
    await audio.playMusic();
    audio.setMusicMix(musicVol);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isPremium = appState.isPremium;
    final nowTrack  = appState.currentTrack ?? 'None';

    return AppScaffold(
      title: 'Music Mode',
      child: isPremium
          ? Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Now Playing:\n$nowTrack', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),

          // Track selector
          DropdownButton<String>(
            value: selectedTrack,
            items: tracks.map((t) =>
                DropdownMenuItem(value: t, child: Text(t))
            ).toList(),
            onChanged: (t) {
              if (t == null) return;
              setState(() => selectedTrack = t);
              _loadAndPlay(t, appState);
            },
          ),
          const SizedBox(height: 24),

          // Mix slider
          Text('Music / Engine Mix: ${(musicVol * 100).toInt()}%'),
          Slider(
            value: musicVol,
            min: 0, max: 1, divisions: 100,
            label: '${(musicVol * 100).toInt()}%',
            onChanged: (v) {
              setState(() => musicVol = v);
              appState.audio.setMusicMix(v);
            },
          ),
          const SizedBox(height: 24),

          Row(children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play Music'),
              onPressed: () => _loadAndPlay(selectedTrack, appState),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.pause),
              label: const Text('Pause Music'),
              onPressed: () => appState.audio.pauseMusic(),
            ),
          ]),
        ]),
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
