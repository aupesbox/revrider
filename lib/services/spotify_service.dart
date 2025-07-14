// lib/services/spotify_service.dart

import 'package:flutter/foundation.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

/// Singleton service to interact with the Spotify SDK.
class SpotifyService {
  SpotifyService._internal();
  static final SpotifyService instance = SpotifyService._internal();

  /// Authenticate the user with Spotify (to be called on app start or when needed)
  Future<bool> authenticate() async {
    try {
      final accessToken = await SpotifySdk.getAuthenticationToken(
        clientId: '<YOUR_SPOTIFY_CLIENT_ID>',
        redirectUrl: '<YOUR_APP_REDIRECT_URI>',
        scope: 'app-remote-control,streaming,playlist-read-private',
      );
      return accessToken != null;
    } catch (e) {
      debugPrint('Spotify auth error: \$e');
      return false;
    }
  }

  /// Play a Spotify track or playlist URI
  Future<void> play(String uri) async {
    try {
      await SpotifySdk.play(spotifyUri: uri);
    } catch (e) {
      debugPrint('Spotify play error: \$e');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await SpotifySdk.pause();
    } catch (e) {
      debugPrint('Spotify pause error: \$e');
    }
  }

// Note: Volume control via Spotify SDK is not supported in this plugin version.
}
