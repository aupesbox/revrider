// lib/ui/widgets/spotify_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class SpotifyBar extends StatelessWidget {
  const SpotifyBar({super.key});

  static const _darkOrange = Color(0xFFCC5500);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final connected = app.spotifyAuthenticated;
    final track = app.currentTrack ?? (connected ? 'Playing…' : 'Not connected');

    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: () {
          // Navigate to settings to (re)authorize if needed
          Navigator.of(context).pushNamed('/settings');
        },
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.music_note, color: connected ? _darkOrange : Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Spotify',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: connected ? _darkOrange : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/settings');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _darkOrange,
                  ),
                  child: Text(connected ? 'Manage' : 'Connect'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
