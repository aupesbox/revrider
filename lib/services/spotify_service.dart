// lib/services/spotify_service.dart

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_sdk/models/player_state.dart';

/// Singleton service to handle Spotify authentication and "Now Playing" updates.
class SpotifyService {
  SpotifyService._internal();
  static final SpotifyService instance = SpotifyService._internal();

  // Stream controller for the current track name
  final StreamController<String> _trackController = StreamController.broadcast();
  /// Stream of track names from Spotify's player state
  Stream<String> get currentTrackStream => _trackController.stream;

  bool _isSubscribed = false;

  /// Authenticate and start listening to player state
  Future<bool> authenticate({
    required String clientId,
    required String redirectUrl,
  }) async {
    try {
      final connected = await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUrl,
      );
      if (connected && !_isSubscribed) {
        _subscribeToPlayerState();
        _isSubscribed = true;
      }
      return connected;
    } catch (e) {
      debugPrint('Spotify auth error: $e');
      return false;
    }
  }

  /// Play a Spotify URI
  Future<void> play(String uri) async {
    try {
      await SpotifySdk.play(spotifyUri: uri);
    } catch (e) {
      debugPrint('Spotify play error: $e');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await SpotifySdk.pause();
    } catch (e) {
      debugPrint('Spotify pause error: $e');
    }
  }

  void _subscribeToPlayerState() {
    SpotifySdk.subscribePlayerState().listen((PlayerState state) {
      final trackName = state.track?.name;
      if (trackName != null) {
        _trackController.add(trackName);
      }
    }, onError: (e) {
      debugPrint('Spotify subscribe error: $e');
    });
  }

  /// Dispose the stream controller
  void dispose() {
    _trackController.close();
  }
}
