// lib/providers/app_state.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ble_manager.dart';
import '../services/audio_manager.dart';
import '../services/settings_sync_service.dart';
import '../services/spotify_service.dart';

// Packs (optional store/AI)
import 'package:uuid/uuid.dart';
import '../models/exhaust_pack.dart';
import '../services/sound_bank_service.dart';

// ✅ Profile + Google (local-only MVP)
import '../models/user_profile.dart';
import '../services/google_auth_service.dart';

class AppState extends ChangeNotifier {
  final BleManager _ble;
  final AudioManager audio;

  // === BLE Connection ===
  BleConnectionStatus connectionStatus = BleConnectionStatus.disconnected;
  bool get isConnected => debugBypass || connectionStatus == BleConnectionStatus.connected;

  // === Live telemetry ===
  int latestAngle = 0;   // 0..100 expected
  int batteryLevel = 100;

  // === Engine volume only (MVP)
  double engineVolume = 1.0;

  // === Spotify (MVP controls)
  bool spotifyAuthenticated = false;
  String? currentTrack;
  StreamSubscription<String?>? _trackSub;

  // === Recording selection (single-master override)
  String? selectedRecordingPath;

  // === Demo mode (keeps UI enabled without BLE)
  bool debugBypass = true;
  void setDebugBypass(bool on) async {
    debugBypass = on;
    // persist + cloud
    await _sync.writeThrough(debugBypass: debugBypass);

    if (on) {
      audio.playStart();
    } else {
      if (connectionStatus != BleConnectionStatus.connected) {
        audio.playCutoff();
      }
    }
    notifyListeners();
  }

  // === Built-in banks in assets/sounds/<bank>/exhaust.mp3
  final String builtInBase = 'assets/sounds';
  List<String> builtInBanks = [];
  String selectedBuiltInBank = 'default';

  // === Installed packs (AI/store)
  final _uuid = const Uuid();
  List<ExhaustPack> installedPacks = [];
  String? selectedPackId;

  // === Profile (persisted locally)
  static const _kProfileKey = 'user_profile_v1';
  UserProfile _profile = const UserProfile();
  UserProfile get profile => _profile;

  AppState(this._ble) : audio = AudioManager() {
    _initBuiltIns();
    _loadProfile(); // load saved profile (Google/name/email/phone/etc)

    // BLE connect/disconnect
    _ble.connectionStateStream.listen((status) {
      connectionStatus = status;
      if (status == BleConnectionStatus.connected) {
        audio.playStart();
      } else if (status == BleConnectionStatus.disconnected) {
        audio.playCutoff();
      }
      notifyListeners();
    });

    // BLE throttle updates — gated by connection state (or demo bypass)
    _ble.throttleStream.listen((angle) {
      latestAngle = angle;
      if (connectionStatus == BleConnectionStatus.connected || debugBypass) {
        audio.updateThrottle(angle.clamp(0, 100));
      }
      notifyListeners();
    });
  }

  // ─────────────────────────────────────────────────────
  // Persistence + Cloud Sync
  // ─────────────────────────────────────────────────────

  final _sync = SettingsSyncService();

  Future<void> init() async {
    // First, reconcile local<->cloud (if signed in)
    await _sync.reconcile();

    // Then read back the local prefs (last-write-wins)
    final sp = await SharedPreferences.getInstance();
    engineVolume = sp.getDouble('engineVolume') ?? engineVolume;
    selectedBuiltInBank = sp.getString('selectedBuiltInBank') ?? selectedBuiltInBank;
    selectedPackId = sp.getString('selectedPackId');
    selectedRecordingPath = sp.getString('selectedRecordingPath');
    debugBypass = sp.getBool('debugBypass') ?? debugBypass;

    // Apply audio state
    try {
      audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);

      if (selectedRecordingPath != null) {
        await audio.loadSingleMasterFile(selectedRecordingPath!);
      } else if (selectedPackId != null) {
        // you'll load pack once installed list is refreshed; safe to ignore here
      } else {
        await audio.loadBank(selectedBuiltInBank, masterFileName: 'exhaust.mp3');
      }
      audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
    } catch (_) {}

    notifyListeners();
  }

  Future<void> setEngineVolume(double v) async {
    engineVolume = v.clamp(0.0, 1.0);
    audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
    await _sync.writeThrough(engineVolume: engineVolume);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────
  // Built-ins
  // ─────────────────────────────────────────────────────

  Future<void> _initBuiltIns() async {
    await refreshBuiltInBanks();

    if (!builtInBanks.contains(selectedBuiltInBank) && builtInBanks.isNotEmpty) {
      selectedBuiltInBank = builtInBanks.first;
    }

    // Load single-master bank (segment logic)
    await audio.loadBank(selectedBuiltInBank, masterFileName: 'exhaust.mp3');

    // Apply engine volume only
    audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);

    notifyListeners();
  }

  Future<void> refreshBuiltInBanks() async {
    try {
      final manifestRaw = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = jsonDecode(manifestRaw);
      final set = <String>{};
      for (final key in manifest.keys) {
        if (key.startsWith('$builtInBase/') && key.endsWith('/exhaust.mp3')) {
          final parts = key.split('/');
          if (parts.length >= 3) set.add(parts[2]); // <bank>
        }
      }
      builtInBanks = set.toList()..sort();
      notifyListeners();
    } catch (_) {
      builtInBanks = ['default'];
      notifyListeners();
    }
  }

  Future<void> selectBuiltInBank(String bank) async {
    selectedBuiltInBank = bank;
    selectedPackId = null;
    selectedRecordingPath = null; // clear recording selection
    await audio.loadBank(bank, masterFileName: 'exhaust.mp3');
    audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
    await _sync.writeThrough(
      builtInBank: bank,
      packId: '',
      recordingPath: '',
    );
    notifyListeners();
  }

  // NEW: select a recorded single-master file
  Future<void> selectRecordingFile(String filePath) async {
    selectedRecordingPath = filePath;
    selectedPackId = null; // clear pack selection
    // keep built-in selection as-is for display; recording overrides audio source
    await audio.loadSingleMasterFile(filePath); // ensure AudioManager has this
    audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
    await _sync.writeThrough(
      recordingPath: filePath,
      builtInBank: '',
      packId: '',
    );
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────
  // Packs (AI/store) — 3 files (idle/mid/high)
  // ─────────────────────────────────────────────────────

  Future<void> refreshInstalledPacks() async {
    try {
      installedPacks = await SoundBankService.instance.listInstalled();
      if (selectedPackId != null &&
          installedPacks.indexWhere((p) => p.id == selectedPackId) == -1) {
        selectedPackId = null;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> selectExhaustPack(String? id) async {
    selectedPackId = id;
    selectedRecordingPath = null; // clear recording selection when choosing a pack
    if (id == null) {
      await selectBuiltInBank(selectedBuiltInBank);
    } else {
      final pack = installedPacks.firstWhere(
            (p) => p.id == id,
        orElse: () => installedPacks.first,
      );
      await audio.loadPackFromFiles(
        idlePath: pack.idlePath,
        midPath:  pack.midPath,
        highPath: pack.highPath,
      );
      audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
      await _sync.writeThrough(
        packId: id,
        builtInBank: '',
        recordingPath: '',
      );
    }
    notifyListeners();
  }

  Future<void> installPurchasedPack({
    required String productId,
    required String displayName,
    required Uri idleUrl,
    required Uri midUrl,
    required Uri highUrl,
  }) async {
    await SoundBankService.instance.installFromUrls(
      id: productId,
      name: displayName,
      idleUrl: idleUrl,
      midUrl:  midUrl,
      highUrl: highUrl,
      source: 'store',
      version: 1,
    );
    await refreshInstalledPacks();
    await selectExhaustPack(productId);
  }

  Future<void> installAiProcessedPack({
    required String name,
    required String idlePath,
    required String midPath,
    required String highPath,
  }) async {
    final id = 'ai_${_uuid.v4()}';
    await SoundBankService.instance.installFromUrls(
      id: id,
      name: name,
      idleUrl: Uri.file(idlePath),
      midUrl:  Uri.file(midPath),
      highUrl: Uri.file(highPath),
      source: 'ai',
      version: 1,
    );
    await refreshInstalledPacks();
    await selectExhaustPack(id);
  }

  // ─────────────────────────────────────────────────────
  // Spotify (auth + minimal controls)
  // ─────────────────────────────────────────────────────

  Future<bool> authenticateSpotify() async {
    spotifyAuthenticated = await SpotifyService.instance.authenticate(
      clientId: 'befe6120515e471fa6377ae9f24763b6',
      redirectUrl: 'rydem://auth',
    );

    // Apply engine volume only (no music mix)
    audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);

    // Subscribe to now playing
    _trackSub?.cancel();
    if (spotifyAuthenticated) {
      _trackSub = SpotifyService.instance.currentTrackStream.listen((trackName) {
        currentTrack = trackName;
        notifyListeners();
      });
    } else {
      currentTrack = null;
    }

    notifyListeners();
    return spotifyAuthenticated;
  }

  void disconnectSpotify() {
    spotifyAuthenticated = false;
    currentTrack = null;
    _trackSub?.cancel();
    _trackSub = null;

    // Keep engine volume applied
    audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
    notifyListeners();
  }

  // Expose service for Home’s buttons (prev/stop/play/next)
  SpotifyService get spotifyService => SpotifyService.instance;

  // ─────────────────────────────────────────────────────
  // BLE
  // ─────────────────────────────────────────────────────

  Future<void> connect() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    if (statuses.values.any((s) => s != PermissionStatus.granted)) return;
    await _ble.connect();
  }

  Future<void> disconnect() async {
    await _ble.disconnect();
    audio.playCutoff(); // immediate silence
    notifyListeners();
  }

  Future<void> calibrateThrottle() async {
    await _ble.calibrate();
    notifyListeners();
  }

  @override
  void dispose() {
    _trackSub?.cancel();
    _ble.dispose();
    audio.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────
  // Profile + Google (local-only MVP)
  // ─────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kProfileKey);
      if (raw != null) {
        _profile = UserProfile.fromJson(raw);
        notifyListeners();
      }
    } catch (_) {/* ignore */}
  }

  Future<void> _saveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProfileKey, _profile.toJson());
    } catch (_) {/* ignore */}
  }

  void updateProfile({
    required String name,
    required String alias,
    required String email,
    required String phone,
    required bool marketingOptIn,
  }) {
    _profile = _profile.copyWith(
      name: name,
      alias: alias,
      email: email,
      phone: phone,
      marketingOptIn: marketingOptIn,
    );
    _saveProfile();
    notifyListeners();
  }

  /// Force user to be signed in with Google.
  Future<bool> ensureGoogleSignedIn() async {
    final silent = await GoogleAuthService.instance.signInSilently();
    final acct = silent ?? await GoogleAuthService.instance.signIn();
    final user = acct ?? GoogleAuthService.instance.currentUser;
    if (user == null) return false;

    _profile = _profile.copyWith(
      name: user.displayName ?? _profile.name,
      email: user.email,
      googleSignedIn: true,
      googlePhotoUrl: user.photoUrl,
    );
    await _saveProfile();
    notifyListeners();
    return true;
  }

  Future<bool> signInWithGoogle() async {
    final acct = await GoogleAuthService.instance.signIn();
    if (acct == null) return false;
    _profile = _profile.copyWith(
      name: acct.displayName ?? _profile.name,
      email: acct.email,
      googleSignedIn: true,
      googlePhotoUrl: acct.photoUrl,
    );
    await _saveProfile();
    notifyListeners();
    return true;
  }

  Future<void> signOutGoogle() async {
    await GoogleAuthService.instance.signOut();
    _profile = _profile.copyWith(googleSignedIn: false, googlePhotoUrl: null);
    await _saveProfile();
    notifyListeners();
  }

  // Local tracks (optional demo music)
  final List<LocalTrack> defaultTracks = const [
    LocalTrack(id: 'road',  name: 'Ambient Road', assetPath: 'assets/music/road.mp3'),
    LocalTrack(id: 'synth', name: 'Synth Drift',  assetPath: 'assets/music/synth.mp3'),
  ];
  String selectedLocalTrackId = 'road';
  void setSelectedLocalTrack(String id) {
    selectedLocalTrackId = id;
    audio.loadMusicAsset(defaultTracks.firstWhere((t) => t.id == id).assetPath);
    notifyListeners();
  }
}

class LocalTrack {
  final String id;
  final String name;
  final String assetPath;
  const LocalTrack({required this.id, required this.name, required this.assetPath});
}

// // lib/providers/app_state.dart
//
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../services/ble_manager.dart';
// import '../services/audio_manager.dart';
// import '../services/settings_sync_service.dart';
// import '../services/spotify_service.dart';
//
// // Packs (optional store/AI)
// import 'package:uuid/uuid.dart';
// import '../models/exhaust_pack.dart';
// import '../services/sound_bank_service.dart';
//
// // ✅ Profile + Google (local-only MVP)
// import '../models/user_profile.dart';
// import '../services/google_auth_service.dart';
//
// class AppState extends ChangeNotifier {
//   final BleManager _ble;
//   final AudioManager audio;
//
//   // === BLE Connection ===
//   BleConnectionStatus connectionStatus = BleConnectionStatus.disconnected;
//   bool get isConnected => debugBypass || connectionStatus == BleConnectionStatus.connected;
//
//   // === Live telemetry ===
//   int latestAngle = 0;   // 0..100 expected
//   int batteryLevel = 100;
//
//   // === Engine volume only (MVP)
//   double engineVolume = 1.0;
//
//   // === Spotify (MVP controls)
//   bool spotifyAuthenticated = false;
//   String? currentTrack;
//   StreamSubscription<String?>? _trackSub;
//
//   // === Recording selection (single-master override)
//   String? selectedRecordingPath;
//
//   // === Demo mode (keeps UI enabled without BLE)
//   bool debugBypass = true;
//   void setDebugBypass(bool on) {
//     debugBypass = on;
//     if (on) {
//       audio.playStart();
//     } else {
//       if (connectionStatus != BleConnectionStatus.connected) {
//         audio.playCutoff();
//       }
//     }
//     notifyListeners();
//   }
//
//   // === Built-in banks in assets/sounds/<bank>/exhaust.mp3
//   final String builtInBase = 'assets/sounds';
//   List<String> builtInBanks = [];
//   String selectedBuiltInBank = 'default';
//
//   // === Installed packs (AI/store)
//   final _uuid = const Uuid();
//   List<ExhaustPack> installedPacks = [];
//   String? selectedPackId;
//
//   // === Profile (persisted locally)
//   static const _kProfileKey = 'user_profile_v1';
//   UserProfile _profile = const UserProfile();
//   UserProfile get profile => _profile;
//
//   AppState(this._ble) : audio = AudioManager() {
//     _initBuiltIns();
//     _loadProfile(); // load saved profile (Google/name/email/phone/etc)
//
//     // BLE connect/disconnect
//     _ble.connectionStateStream.listen((status) {
//       connectionStatus = status;
//       if (status == BleConnectionStatus.connected) {
//         audio.playStart();
//       } else if (status == BleConnectionStatus.disconnected) {
//         audio.playCutoff();
//       }
//       notifyListeners();
//     });
//
//     // BLE throttle updates — gated by connection state (or demo bypass)
//     _ble.throttleStream.listen((angle) {
//       latestAngle = angle;
//       if (connectionStatus == BleConnectionStatus.connected || debugBypass) {
//         audio.updateThrottle(angle.clamp(0, 100));
//       }
//       notifyListeners();
//     });
//   }
//
//
//   final _sync = SettingsSyncService();
//
//   Future<void> init() async {
//     await _sync.reconcile();
//     notifyListeners();
//   }
//
//   Future<void> setEngineVolume(double v) async {
//     engineVolume = v.clamp(0.0, 1.0);
//     AudioManager.instance.setMasterVolume(engineVolume);
//     await _sync.writeThrough(engineVolume: engineVolume);
//     notifyListeners();
//   }
//
//
//   // ─────────────────────────────────────────────────────
//   // Built-ins
//   // ─────────────────────────────────────────────────────
//
//   Future<void> _initBuiltIns() async {
//     await refreshBuiltInBanks();
//
//     if (!builtInBanks.contains(selectedBuiltInBank) && builtInBanks.isNotEmpty) {
//       selectedBuiltInBank = builtInBanks.first;
//     }
//
//     // Load single-master bank (segment logic)
//     await audio.loadBank(selectedBuiltInBank, masterFileName: 'exhaust.mp3');
//
//     // Apply engine volume only
//     audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
//
//     notifyListeners();
//   }
//
//   Future<void> refreshBuiltInBanks() async {
//     try {
//       final manifestRaw = await rootBundle.loadString('AssetManifest.json');
//       final Map<String, dynamic> manifest = jsonDecode(manifestRaw);
//       final set = <String>{};
//       for (final key in manifest.keys) {
//         if (key.startsWith('$builtInBase/') && key.endsWith('/exhaust.mp3')) {
//           final parts = key.split('/');
//           if (parts.length >= 3) set.add(parts[2]); // <bank>
//         }
//       }
//       builtInBanks = set.toList()..sort();
//       notifyListeners();
//     } catch (_) {
//       builtInBanks = ['default'];
//       notifyListeners();
//     }
//   }
//
//   Future<void> selectBuiltInBank(String bank) async {
//     selectedBuiltInBank = bank;
//     selectedPackId = null;
//     selectedRecordingPath = null; // clear recording selection
//     await audio.loadBank(bank, masterFileName: 'exhaust.mp3');
//     audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
//     notifyListeners();
//   }
//
//   // NEW: select a recorded single-master file
//   Future<void> selectRecordingFile(String filePath) async {
//     selectedRecordingPath = filePath;
//     selectedPackId = null; // clear pack selection
//     // keep built-in selection as-is for display; recording overrides audio source
//     await audio.loadSingleMasterFile(filePath); // ensure AudioManager has this
//     audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
//     notifyListeners();
//   }
//
//   // ─────────────────────────────────────────────────────
//   // Packs (AI/store) — 3 files (idle/mid/high)
//   // ─────────────────────────────────────────────────────
//
//   Future<void> refreshInstalledPacks() async {
//     try {
//       installedPacks = await SoundBankService.instance.listInstalled();
//       if (selectedPackId != null &&
//           installedPacks.indexWhere((p) => p.id == selectedPackId) == -1) {
//         selectedPackId = null;
//       }
//       notifyListeners();
//     } catch (_) {}
//   }
//
//   Future<void> selectExhaustPack(String? id) async {
//     selectedPackId = id;
//     selectedRecordingPath = null; // clear recording selection when choosing a pack
//     if (id == null) {
//       await selectBuiltInBank(selectedBuiltInBank);
//     } else {
//       final pack = installedPacks.firstWhere((p) => p.id == id, orElse: () => installedPacks.first);
//       await audio.loadPackFromFiles(
//         idlePath: pack.idlePath,
//         midPath:  pack.midPath,
//         highPath: pack.highPath,
//       );
//       audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
//     }
//     notifyListeners();
//   }
//
//   Future<void> installPurchasedPack({
//     required String productId,
//     required String displayName,
//     required Uri idleUrl,
//     required Uri midUrl,
//     required Uri highUrl,
//   }) async {
//     await SoundBankService.instance.installFromUrls(
//       id: productId,
//       name: displayName,
//       idleUrl: idleUrl,
//       midUrl:  midUrl,
//       highUrl: highUrl,
//       source: 'store',
//       version: 1,
//     );
//     await refreshInstalledPacks();
//     await selectExhaustPack(productId);
//   }
//
//   Future<void> installAiProcessedPack({
//     required String name,
//     required String idlePath,
//     required String midPath,
//     required String highPath,
//   }) async {
//     final id = 'ai_${_uuid.v4()}';
//     await SoundBankService.instance.installFromUrls(
//       id: id,
//       name: name,
//       idleUrl: Uri.file(idlePath),
//       midUrl:  Uri.file(midPath),
//       highUrl: Uri.file(highPath),
//       source: 'ai',
//       version: 1,
//     );
//     await refreshInstalledPacks();
//     await selectExhaustPack(id);
//   }
//
//   // ─────────────────────────────────────────────────────
//   // Spotify (auth + minimal controls)
//   // ─────────────────────────────────────────────────────
//
//   Future<bool> authenticateSpotify() async {
//     spotifyAuthenticated = await SpotifyService.instance.authenticate(
//       clientId: 'befe6120515e471fa6377ae9f24763b6',
//       redirectUrl: 'rydem://auth',
//     );
//
//     // Apply engine volume only (no music mix)
//     audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
//
//     // Subscribe to now playing
//     _trackSub?.cancel();
//     if (spotifyAuthenticated) {
//       _trackSub = SpotifyService.instance.currentTrackStream.listen((trackName) {
//         currentTrack = trackName;
//         notifyListeners();
//       });
//     } else {
//       currentTrack = null;
//     }
//
//     notifyListeners();
//     return spotifyAuthenticated;
//   }
//
//   void disconnectSpotify() {
//     spotifyAuthenticated = false;
//     currentTrack = null;
//     _trackSub?.cancel();
//     _trackSub = null;
//
//     // Keep engine volume applied
//     audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
//     notifyListeners();
//   }
//
//   // Expose service for Home’s buttons (prev/stop/play/next)
//   SpotifyService get spotifyService => SpotifyService.instance;
//
//   // ─────────────────────────────────────────────────────
//   // BLE
//   // ─────────────────────────────────────────────────────
//
//   Future<void> connect() async {
//     final statuses = await [
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.locationWhenInUse,
//     ].request();
//     if (statuses.values.any((s) => s != PermissionStatus.granted)) return;
//     await _ble.connect();
//   }
//
//   Future<void> disconnect() async {
//     await _ble.disconnect();
//     audio.playCutoff(); // immediate silence
//     notifyListeners();
//   }
//
//   Future<void> calibrateThrottle() async {
//     await _ble.calibrate();
//     notifyListeners();
//   }
//
//   // ─────────────────────────────────────────────────────
//   // Engine volume setter (MVP)
//   // ─────────────────────────────────────────────────────
//
//
//
//   @override
//   void dispose() {
//     _trackSub?.cancel();
//     _ble.dispose();
//     audio.dispose();
//     super.dispose();
//   }
//
//   // ─────────────────────────────────────────────────────
//   // Profile + Google (local-only MVP)
//   // ─────────────────────────────────────────────────────
//
//   Future<void> _loadProfile() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final raw = prefs.getString(_kProfileKey);
//       if (raw != null) {
//         _profile = UserProfile.fromJson(raw);
//         notifyListeners();
//       }
//     } catch (_) {/* ignore */}
//   }
//
//   Future<void> _saveProfile() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString(_kProfileKey, _profile.toJson());
//     } catch (_) {/* ignore */}
//   }
//
//   void updateProfile({
//     required String name,
//     required String alias,
//     required String email,
//     required String phone,
//     required bool marketingOptIn,
//   }) {
//     _profile = _profile.copyWith(
//       name: name,
//       alias: alias,
//       email: email,
//       phone: phone,
//       marketingOptIn: marketingOptIn,
//     );
//     _saveProfile();
//     notifyListeners();
//   }
//
//   /// Force user to be signed in with Google.
//   /// 1) Try silent sign-in (no UI).
//   /// 2) If not signed in, show interactive Google account picker.
//   /// Returns true if signed in, false if user canceled or failed.
//   Future<bool> ensureGoogleSignedIn() async {
//     final silent = await GoogleAuthService.instance.signInSilently();
//     final acct = silent ?? await GoogleAuthService.instance.signIn();
//     final user = acct ?? GoogleAuthService.instance.currentUser;
//     if (user == null) return false;
//
//     _profile = _profile.copyWith(
//       name: user.displayName ?? _profile.name,
//       email: user.email,
//       googleSignedIn: true,
//       googlePhotoUrl: user.photoUrl,
//     );
//     await _saveProfile();
//     notifyListeners();
//     return true;
//   }
//
//   Future<bool> signInWithGoogle() async {
//     final acct = await GoogleAuthService.instance.signIn();
//     if (acct == null) return false;
//     _profile = _profile.copyWith(
//       name: acct.displayName ?? _profile.name,
//       email: acct.email,
//       googleSignedIn: true,
//       googlePhotoUrl: acct.photoUrl,
//     );
//     await _saveProfile();
//     notifyListeners();
//     return true;
//   }
//
//   Future<void> signOutGoogle() async {
//     await GoogleAuthService.instance.signOut();
//     _profile = _profile.copyWith(googleSignedIn: false, googlePhotoUrl: null);
//     await _saveProfile();
//     notifyListeners();
//   }
//
//   // Local tracks (optional demo music)
//   final List<LocalTrack> defaultTracks = const [
//     LocalTrack(id: 'road',  name: 'Ambient Road', assetPath: 'assets/music/road.mp3'),
//     LocalTrack(id: 'synth', name: 'Synth Drift',  assetPath: 'assets/music/synth.mp3'),
//   ];
//   String selectedLocalTrackId = 'road';
//   void setSelectedLocalTrack(String id) {
//     selectedLocalTrackId = id;
//     audio.loadMusicAsset(defaultTracks.firstWhere((t) => t.id == id).assetPath);
//     notifyListeners();
//   }
// }
//
// class LocalTrack {
//   final String id;
//   final String name;
//   final String assetPath;
//   const LocalTrack({required this.id, required this.name, required this.assetPath});
// }
