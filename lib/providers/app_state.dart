// lib/providers/app_state.dart

import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
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
  final SettingsSyncService _prefsSync = SettingsSyncService();

  BleConnectionStatus connectionStatus = BleConnectionStatus.disconnected;
  bool get isConnected =>
      debugBypass || connectionStatus == BleConnectionStatus.connected;

  int latestAngle = 0;   // 0..100 expected
  int batteryLevel = 100;
  double engineVolume = 1.0;

  bool spotifyAuthenticated = false;
  String? currentTrack;
  StreamSubscription<String?>? _trackSub;

  String? selectedRecordingPath;

  bool debugBypass = true;
  void setDebugBypass(bool on) async {
    debugBypass = on;
    await _prefsSync.writeThrough(debugBypass: debugBypass);

    if (on) {
      audio.playStart();
    } else {
      if (connectionStatus != BleConnectionStatus.connected) {
        // cutoff alias to shutdown via shim in AudioManager
        audio.playShutdown();
      }
    }
    notifyListeners();
  }

  final String builtInBase = 'assets/sounds';
  List<String> builtInBanks = [];
  String selectedBuiltInBank = 'default';

  final _uuid = const Uuid();
  List<ExhaustPack> installedPacks = [];
  String? selectedPackId;

  static const _kProfileKey = 'user_profile_v1';
  UserProfile _profile = const UserProfile();
  UserProfile get profile => _profile;

  // Reconnect metrics
  DateTime? _lastDisconnect;
  DateTime? _lastReconnect;
  Duration? lastReconnectLatency;
  int reconnectCount = 0;
  Duration totalReconnectLatency = Duration.zero;

  AppState(this._ble) : audio = AudioManager() {
    _initBuiltIns();
    _loadProfile();

    // Connection listener + reconnect metrics
    _ble.connectionStateStream.listen((status) {
      connectionStatus = status;

      if (status == BleConnectionStatus.connected) {
        audio.playStart();

        if (_lastDisconnect != null) {
          _lastReconnect = DateTime.now();
          lastReconnectLatency = _lastReconnect!.difference(_lastDisconnect!);
          reconnectCount++;
          totalReconnectLatency += lastReconnectLatency!;
        }
      } else if (status == BleConnectionStatus.disconnected) {
        // ensure any looping layers stop and play shutdown one-shot
        audio.playShutdown();
        audio.stopAll();
        _lastDisconnect = DateTime.now();
      }

      notifyListeners();
    });

    // Throttle listener (must stay!)
    _ble.throttleStream.listen((angle) {
      latestAngle = angle;
      if (connectionStatus == BleConnectionStatus.connected || debugBypass) {
        debugPrint("🔊 Updating throttle: $angle");
        audio.updateThrottle(angle.clamp(0, 100));
      }
      notifyListeners();
    });

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await _prefsSync.reconcile();
        final sp = await SharedPreferences.getInstance();
        engineVolume = sp.getDouble('engineVolume') ?? engineVolume;
        selectedBuiltInBank =
            sp.getString('selectedBuiltInBank') ?? selectedBuiltInBank;
        selectedPackId = sp.getString('selectedPackId');
        selectedRecordingPath = sp.getString('selectedRecordingPath');
        debugBypass = sp.getBool('debugBypass') ?? debugBypass;
        notifyListeners();
      }
    });
  }

  void resetReconnectMetrics() {
    lastReconnectLatency = null;
    reconnectCount = 0;
    totalReconnectLatency = Duration.zero;
    _lastDisconnect = null;
    _lastReconnect = null;
    notifyListeners();
  }

  double get averageReconnectLatencySec {
    if (reconnectCount == 0) return 0.0;
    return totalReconnectLatency.inMilliseconds / reconnectCount / 1000.0;
  }

  String get reconnectLatencyLabel {
    if (lastReconnectLatency == null) return "N/A";
    return "${(lastReconnectLatency!.inMilliseconds / 1000.0).toStringAsFixed(2)}s";
  }

  Future<void> init() async {
    await _prefsSync.reconcile();
    final sp = await SharedPreferences.getInstance();
    engineVolume = sp.getDouble('engineVolume') ?? engineVolume;
    selectedBuiltInBank =
        sp.getString('selectedBuiltInBank') ?? selectedBuiltInBank;
    selectedPackId = sp.getString('selectedPackId');
    selectedRecordingPath = sp.getString('selectedRecordingPath');
    debugBypass = sp.getBool('debugBypass') ?? debugBypass;

    try {
      // Load the 6-clip default pack by default
      await audio.loadFullPack(
        startPath: "assets/sounds/default/start.wav",
        idlePath: "assets/sounds/default/idle1.wav",
        gear1Path: "assets/sounds/default/first_gear.wav",
        gear2Path: "assets/sounds/default/second_gear.wav",
        gear3Path: "assets/sounds/default/third_gear.wav",
        shutdownPath: "assets/sounds/default/shutdown.wav",
      );
      audio.setEngineVolume(engineVolume);

      // If user selected a standalone recording earlier, keep that flow working:
      if (selectedRecordingPath != null && selectedRecordingPath!.isNotEmpty) {
        //await audio.loadSingleMasterFile(selectedRecordingPath!);
        audio.setEngineVolume(engineVolume);
      }
    } catch (e) {
      debugPrint("Audio init failed: $e");
    }

    notifyListeners();
  }

  Future<void> setEngineVolume(double v) async {
    engineVolume = v.clamp(0.0, 1.0);
    // prefer new API
    audio.setEngineVolume(engineVolume);
    // keep old API call working if shim exists (harmless if present)
    try {
      // ignore: deprecated_member_use_from_same_package
     // audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
    } catch (_) {}
    await _prefsSync.writeThrough(engineVolume: engineVolume);
    notifyListeners();
  }

  Future<void> _initBuiltIns() async {
    await refreshBuiltInBanks();
    if (!builtInBanks.contains(selectedBuiltInBank) && builtInBanks.isNotEmpty) {
      selectedBuiltInBank = builtInBanks.first;
    }
    // Preload default bank using 6-clip pack
    await audio.loadFullPack(
      startPath: "assets/sounds/default/start.wav",
      idlePath: "assets/sounds/default/idle1.wav",
      gear1Path: "assets/sounds/default/first_gear.wav",
      gear2Path: "assets/sounds/default/second_gear.wav",
      gear3Path: "assets/sounds/default/third_gear.wav",
      shutdownPath: "assets/sounds/default/shutdown.wav",
    );
    audio.setEngineVolume(engineVolume);
    notifyListeners();
  }

  Future<void> refreshBuiltInBanks() async {
    try {
      final manifestRaw = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = jsonDecode(manifestRaw);
      final set = <String>{};
      // Treat any folder under assets/sounds/* that contains an idle1.wav as a bank
      for (final key in manifest.keys) {
        if (key.contains('idle1.wav')) {
          final parts = key.split('/');
          if (parts.length >= 3) set.add(parts[2]);
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
    selectedRecordingPath = null;

    await audio.loadFullPack(
      startPath: "assets/sounds/default/start.wav",
      idlePath: "assets/sounds/default/idle1.wav",
      gear1Path: "assets/sounds/default/first_gear.wav",
      gear2Path: "assets/sounds/default/second_gear.wav",
      gear3Path: "assets/sounds/default/third_gear.wav",
      shutdownPath: "assets/sounds/default/shutdown.wav",
    );
    audio.setEngineVolume(engineVolume);

    await _prefsSync.writeThrough(
      builtInBank: bank,
      packId: '',
      recordingPath: '',
    );
    notifyListeners();
  }

  Future<void> selectRecordingFile(String filePath) async {
    selectedRecordingPath = filePath;
    selectedPackId = null;
    //await audio.loadSingleMasterFile(filePath);
    audio.setEngineVolume(engineVolume);
    await _prefsSync.writeThrough(
      recordingPath: filePath,
      builtInBank: '',
      packId: '',
    );
    notifyListeners();
  }

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
    selectedRecordingPath = null;

    if (id == null) {
      await selectBuiltInBank(selectedBuiltInBank);
    } else {
      // For now, load the default 6-clip pack (replace with pack file paths if you store them)
      await audio.loadFullPack(
        startPath: "assets/sounds/default/start.wav",
        idlePath: "assets/sounds/default/idle1.wav",
        gear1Path: "assets/sounds/default/first_gear.wav",
        gear2Path: "assets/sounds/default/second_gear.wav",
        gear3Path: "assets/sounds/default/third_gear.wav",
        shutdownPath: "assets/sounds/default/shutdown.wav",
      );
      audio.setEngineVolume(engineVolume);

      await _prefsSync.writeThrough(
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
      midUrl: midUrl,
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
      midUrl: Uri.file(midPath),
      highUrl: Uri.file(highPath),
      source: 'ai',
      version: 1,
    );
    await refreshInstalledPacks();
    await selectExhaustPack(id);
  }

  // --- Spotify Integration ---
  Future<bool> authenticateSpotify() async {
    spotifyAuthenticated = await SpotifyService.instance.authenticate(
      clientId: 'befe6120515e471fa6377ae9f24763b6',
      redirectUrl: 'rydem://auth',
    );
    try {
      // keep compatibility if shim exists
      // ignore: deprecated_member_use_from_same_package
      //audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
    } catch (_) {}
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
    try {
      // ignore: deprecated_member_use_from_same_package
      //audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
    } catch (_) {}
    notifyListeners();
  }

  SpotifyService get spotifyService => SpotifyService.instance;

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
    // keep the legacy call name if any code still expects it
    try {
      audio.playShutdown();
    } catch (_) {
      audio.playShutdown();
    }
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

  // --- Google Sign In ---
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

  // --- Local Profile ---
  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kProfileKey);
      if (raw != null) {
        _profile = UserProfile.fromJson(raw);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProfileKey, _profile.toJson());
    } catch (_) {}
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

  // --- Local Music ---
  final List<LocalTrack> defaultTracks = const [
    LocalTrack(id: 'road',  name: 'Ambient Road', assetPath: 'assets/music/road.wav'),
    LocalTrack(id: 'synth', name: 'Synth Drift',  assetPath: 'assets/music/synth.wav'),
  ];
  String selectedLocalTrackId = 'road';
  void setSelectedLocalTrack(String id) {
    selectedLocalTrackId = id;
    //audio.loadMusicAsset(defaultTracks.firstWhere((t) => t.id == id).assetPath);
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
// import 'package:firebase_auth/firebase_auth.dart';
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
//   final SettingsSyncService _prefsSync = SettingsSyncService();
//
//   BleConnectionStatus connectionStatus = BleConnectionStatus.disconnected;
//   bool get isConnected => debugBypass || connectionStatus == BleConnectionStatus.connected;
//
//   int latestAngle = 0;   // 0..100 expected
//   int batteryLevel = 100;
//   double engineVolume = 1.0;
//
//   bool spotifyAuthenticated = false;
//   String? currentTrack;
//   StreamSubscription<String?>? _trackSub;
//
//   String? selectedRecordingPath;
//
//   bool debugBypass = true;
//   void setDebugBypass(bool on) async {
//     debugBypass = on;
//     await _prefsSync.writeThrough(debugBypass: debugBypass);
//
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
//   final String builtInBase = 'assets/sounds';
//   List<String> builtInBanks = [];
//   String selectedBuiltInBank = 'default';
//
//   final _uuid = const Uuid();
//   List<ExhaustPack> installedPacks = [];
//   String? selectedPackId;
//
//   static const _kProfileKey = 'user_profile_v1';
//   UserProfile _profile = const UserProfile();
//   UserProfile get profile => _profile;
//   DateTime? _lastDisconnect;
//   DateTime? _lastReconnect;
//   Duration? lastReconnectLatency;
//   int reconnectCount = 0;
//   Duration totalReconnectLatency = Duration.zero;
//
//   AppState(this._ble) : audio = AudioManager() {
//     _initBuiltIns();
//     _loadProfile();
//
//     // _ble.connectionStateStream.listen((status) {
//     //   connectionStatus = status;
//     //   if (status == BleConnectionStatus.connected) {
//     //     audio.playStart();
//     //   } else if (status == BleConnectionStatus.disconnected) {
//     //     audio.playCutoff();
//     //   }
//     //   notifyListeners();
//     // });
//     //
//     // _ble.throttleStream.listen((angle) {
//     //   latestAngle = angle;
//     //   if (connectionStatus == BleConnectionStatus.connected || debugBypass) {
//     //     audio.updateThrottle(angle.clamp(0, 100));
//     //   }
//     //   notifyListeners();
//     // });
//     // Connection listener + reconnect metrics
//     _ble.connectionStateStream.listen((status) {
//       connectionStatus = status;
//
//       if (status == BleConnectionStatus.connected) {
//         audio.playStart();
//
//         if (_lastDisconnect != null) {
//           _lastReconnect = DateTime.now();
//           lastReconnectLatency =
//               _lastReconnect!.difference(_lastDisconnect!);
//
//           reconnectCount++;
//           totalReconnectLatency += lastReconnectLatency!;
//         }
//       } else if (status == BleConnectionStatus.disconnected) {
//         audio.playCutoff();audio.playCutoff();
//         audio.stopAll(); // 🔧 new: force stop idle/mid/high layers if any looping
//         _lastDisconnect = DateTime.now();
//         _lastDisconnect = DateTime.now();
//       }
//
//       notifyListeners();
//     });
//
// // Throttle listener (must stay!)
//     _ble.throttleStream.listen((angle) {
//       latestAngle = angle;
//       if (connectionStatus == BleConnectionStatus.connected || debugBypass) {
//         audio.updateThrottle(angle.clamp(0, 100));
//       }
//       notifyListeners();
//     });
//
//
//     FirebaseAuth.instance.authStateChanges().listen((user) async {
//       if (user != null) {
//         await _prefsSync.reconcile();
//         final sp = await SharedPreferences.getInstance();
//         engineVolume = sp.getDouble('engineVolume') ?? engineVolume;
//         selectedBuiltInBank = sp.getString('selectedBuiltInBank') ?? selectedBuiltInBank;
//         selectedPackId = sp.getString('selectedPackId');
//         selectedRecordingPath = sp.getString('selectedRecordingPath');
//         debugBypass = sp.getBool('debugBypass') ?? debugBypass;
//         notifyListeners();
//       }
//     });
//   }
//   void resetReconnectMetrics() {
//     lastReconnectLatency = null;
//     reconnectCount = 0;
//     totalReconnectLatency = Duration.zero;
//     _lastDisconnect = null;
//     _lastReconnect = null;
//     notifyListeners();
//   }
//
//   double get averageReconnectLatencySec {
//     if (reconnectCount == 0) return 0.0;
//     return totalReconnectLatency.inMilliseconds / reconnectCount / 1000.0;
//   }
//   // Expose a safe getter
//   String get reconnectLatencyLabel {
//     if (lastReconnectLatency == null) return "N/A";
//     return "${(lastReconnectLatency!.inMilliseconds / 1000.0).toStringAsFixed(2)}s";
//   }
//
//
//
//   Future<void> init() async {
//     await _prefsSync.reconcile();
//     final sp = await SharedPreferences.getInstance();
//     engineVolume = sp.getDouble('engineVolume') ?? engineVolume;
//     selectedBuiltInBank = sp.getString('selectedBuiltInBank') ?? selectedBuiltInBank;
//     selectedPackId = sp.getString('selectedPackId');
//     selectedRecordingPath = sp.getString('selectedRecordingPath');
//     debugBypass = sp.getBool('debugBypass') ?? debugBypass;
//
//     try {
//       audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
//       if (selectedRecordingPath != null) {
//         await audio.loadSingleMasterFile(selectedRecordingPath!);
//       } else if (selectedPackId == null) {
//         await audio.loadBank(selectedBuiltInBank, masterFileName: 'exhaust.wav');
//       }
//       audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
//     } catch (_) {}
//
//     notifyListeners();
//   }
//
//   Future<void> setEngineVolume(double v) async {
//     engineVolume = v.clamp(0.0, 1.0);
//     audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
//     await _prefsSync.writeThrough(engineVolume: engineVolume);
//     notifyListeners();
//   }
//
//   Future<void> _initBuiltIns() async {
//     await refreshBuiltInBanks();
//     if (!builtInBanks.contains(selectedBuiltInBank) && builtInBanks.isNotEmpty) {
//       selectedBuiltInBank = builtInBanks.first;
//     }
//     await audio.loadBank(selectedBuiltInBank, masterFileName: 'exhaust.wav');
//     audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
//     notifyListeners();
//   }
//
//   Future<void> refreshBuiltInBanks() async {
//     try {
//       final manifestRaw = await rootBundle.loadString('AssetManifest.json');
//       final Map<String, dynamic> manifest = jsonDecode(manifestRaw);
//       final set = <String>{};
//       for (final key in manifest.keys) {
//         if (key.startsWith('$builtInBase/') && key.endsWith('/exhaust.wav')) {
//           final parts = key.split('/');
//           if (parts.length >= 3) set.add(parts[2]);
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
//     selectedRecordingPath = null;
//     await audio.loadBank(bank, masterFileName: 'exhaust.wav');
//     audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
//     await _prefsSync.writeThrough(
//       builtInBank: bank,
//       packId: '',
//       recordingPath: '',
//     );
//     notifyListeners();
//   }
//
//   Future<void> selectRecordingFile(String filePath) async {
//     selectedRecordingPath = filePath;
//     selectedPackId = null;
//     await audio.loadSingleMasterFile(filePath);
//     audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
//     await _prefsSync.writeThrough(
//       recordingPath: filePath,
//       builtInBank: '',
//       packId: '',
//     );
//     notifyListeners();
//   }
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
//     selectedRecordingPath = null;
//     if (id == null) {
//       await selectBuiltInBank(selectedBuiltInBank);
//     } else {
//       final pack = installedPacks.firstWhere(
//             (p) => p.id == id,
//         orElse: () => installedPacks.first,
//       );
//       //old
//       // await audio.loadPackFromFiles(
//       //   idlePath: pack.idlePath,
//       //   midPath: pack.midPath,
//       //   highPath: pack.highPath,
//       // );
//       await audio.loadFullPack(
//         startPath: "assets/sounds/default/start.wav3",
//         idlePath: "assets/sounds/default/idle1.wav",
//         gear1Path: "assets/sounds/default/first_gear.wav",
//         gear2Path: "assets/sounds/default/second_gear.wav",
//         gear3Path: "assets/sounds/default/third_gear.wav",
//         //cruisePath: "assets/sounds/default/cruise.wav",
//         shutdownPath: "assets/sounds/default/shutdown.wav",
//       );
//
//       audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
//       await _prefsSync.writeThrough(
//         packId: id,
//         builtInBank: '',
//         recordingPath: '',
//       );
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
//       midUrl: midUrl,
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
//       midUrl: Uri.file(midPath),
//       highUrl: Uri.file(highPath),
//       source: 'ai',
//       version: 1,
//     );
//     await refreshInstalledPacks();
//     await selectExhaustPack(id);
//   }
//
//   // --- Spotify Integration ---
//   Future<bool> authenticateSpotify() async {
//     spotifyAuthenticated = await SpotifyService.instance.authenticate(
//       clientId: 'befe6120515e471fa6377ae9f24763b6',
//       redirectUrl: 'rydem://auth',
//     );
//     audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
//     _trackSub?.cancel();
//     if (spotifyAuthenticated) {
//       _trackSub = SpotifyService.instance.currentTrackStream.listen((trackName) {
//         currentTrack = trackName;
//         notifyListeners();
//       });
//     } else {
//       currentTrack = null;
//     }
//     notifyListeners();
//     return spotifyAuthenticated;
//   }
//
//   void disconnectSpotify() {
//     spotifyAuthenticated = false;
//     currentTrack = null;
//     _trackSub?.cancel();
//     _trackSub = null;
//     audio.setMix(enabled: false, engineVol: engineVolume, musicVol: 0);
//     notifyListeners();
//   }
//
//   SpotifyService get spotifyService => SpotifyService.instance;
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
//     audio.playCutoff();
//     notifyListeners();
//   }
//
//   Future<void> calibrateThrottle() async {
//     await _ble.calibrate();
//     notifyListeners();
//   }
//
//   @override
//   void dispose() {
//     _trackSub?.cancel();
//     _ble.dispose();
//     audio.dispose();
//     super.dispose();
//   }
//
//   // --- Google Sign In ---
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
//   // --- Local Profile ---
//   Future<void> _loadProfile() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final raw = prefs.getString(_kProfileKey);
//       if (raw != null) {
//         _profile = UserProfile.fromJson(raw);
//         notifyListeners();
//       }
//     } catch (_) {}
//   }
//
//   Future<void> _saveProfile() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString(_kProfileKey, _profile.toJson());
//     } catch (_) {}
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
//   // --- Local Music ---
//   final List<LocalTrack> defaultTracks = const [
//     LocalTrack(id: 'road',  name: 'Ambient Road', assetPath: 'assets/music/road.wav'),
//     LocalTrack(id: 'synth', name: 'Synth Drift',  assetPath: 'assets/music/synth.wav'),
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
