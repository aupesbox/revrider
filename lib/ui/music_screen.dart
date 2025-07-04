// lib/ui/music_screen.dart
import 'package:flutter/material.dart';
import 'app_scaffold.dart';

class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Music Mode',
      child: Center(
        child: Text('Spotify sync coming soon…'),
      ),
    );
  }
}
