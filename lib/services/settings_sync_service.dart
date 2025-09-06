import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsSyncService {
  static const _kEngineVolumeKey = 'engineVolume';
  static const _kBuiltInBankKey  = 'selectedBuiltInBank';
  static const _kPackIdKey       = 'selectedPackId';
  static const _kRecPathKey      = 'selectedRecordingPath';
  static const _kDebugBypassKey  = 'debugBypass';
  static const _kLocalUpdatedKey = 'settings_local_updated_at';

  final _auth = FirebaseAuth.instance;
  final _fire = FirebaseFirestore.instance;

  Future<void> reconcile() async {
    final sp = await SharedPreferences.getInstance();
    final local = _readLocal(sp);

    final user = _auth.currentUser;
    if (user == null) return; // device-only until login

    final docRef = _fire.collection('users').doc(user.uid)
        .collection('settings').doc('preferences');
    final snap = await docRef.get();

    if (snap.exists) {
      final remote = snap.data()!;
      final tRemote = DateTime.tryParse(remote['updatedAt'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final tLocal  = DateTime.tryParse(local.updatedAt ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);

      if (tRemote.isAfter(tLocal)) {
        await _writeLocal(sp, remote);
      } else {
        await _writeRemote(docRef, local);
      }
    } else {
      await _writeRemote(docRef, local);
    }
  }

  Future<void> writeThrough({
    double? engineVolume,
    String? builtInBank,
    String? packId,
    String? recordingPath,
    bool? debugBypass,
  }) async {
    final sp = await SharedPreferences.getInstance();

    if (engineVolume != null) {
      sp.setDouble(_kEngineVolumeKey, engineVolume.clamp(0.0, 1.0));
    }
    if (builtInBank != null) sp.setString(_kBuiltInBankKey, builtInBank);
    if (packId != null)      sp.setString(_kPackIdKey, packId);
    if (recordingPath != null) sp.setString(_kRecPathKey, recordingPath);
    if (debugBypass != null) sp.setBool(_kDebugBypassKey, debugBypass);

    final nowIso = DateTime.now().toUtc().toIso8601String();
    sp.setString(_kLocalUpdatedKey, nowIso);

    final user = _auth.currentUser;
    if (user != null) {
      final docRef = _fire.collection('users').doc(user.uid)
          .collection('settings').doc('preferences');
      final all = _readLocal(sp);
      await _writeRemote(docRef, all);
    }
  }

  _LocalSettings _readLocal(SharedPreferences sp) => _LocalSettings(
    engineVolume: sp.getDouble(_kEngineVolumeKey) ?? 0.7,
    builtInBank:  sp.getString(_kBuiltInBankKey),
    packId:       sp.getString(_kPackIdKey),
    recordingPath: sp.getString(_kRecPathKey),
    debugBypass:  sp.getBool(_kDebugBypassKey) ?? false,
    updatedAt:    sp.getString(_kLocalUpdatedKey),
  );

  Future<void> _writeLocal(SharedPreferences sp, Map<String, dynamic> r) async {
    await sp.setDouble(_kEngineVolumeKey, (r['engineVolume'] as num?)?.toDouble() ?? 0.7);
    if (r['selectedBuiltInBank'] != null) await sp.setString(_kBuiltInBankKey, r['selectedBuiltInBank']);
    if (r['selectedPackId'] != null)      await sp.setString(_kPackIdKey, r['selectedPackId']);
    if (r['selectedRecordingPath'] != null) await sp.setString(_kRecPathKey, r['selectedRecordingPath']);
    await sp.setBool(_kDebugBypassKey, r['debugBypass'] ?? false);
    await sp.setString(_kLocalUpdatedKey, r['updatedAt'] ?? DateTime.now().toUtc().toIso8601String());
  }

  Future<void> _writeRemote(DocumentReference docRef, _LocalSettings s) async {
    await docRef.set({
      'engineVolume': s.engineVolume,
      'selectedBuiltInBank': s.builtInBank,
      'selectedPackId': s.packId,
      'selectedRecordingPath': s.recordingPath,
      'debugBypass': s.debugBypass,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

class _LocalSettings {
  final double engineVolume;
  final String? builtInBank;
  final String? packId;
  final String? recordingPath;
  final bool debugBypass;
  final String? updatedAt;
  _LocalSettings({
    required this.engineVolume,
    required this.builtInBank,
    required this.packId,
    required this.recordingPath,
    required this.debugBypass,
    required this.updatedAt,
  });
}

// // lib/services/settings_sync_service.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class SettingsSyncService {
//   static const _kEngineVolumeKey = 'engineVolume';
//   static const _kBuiltInBankKey  = 'selectedBuiltInBank';
//   static const _kPackIdKey       = 'selectedPackId';
//   static const _kRecPathKey      = 'selectedRecordingPath';
//   static const _kDebugBypassKey  = 'debugBypass';
//   static const _kLocalUpdatedKey = 'settings_local_updated_at';
//
//   final _auth = FirebaseAuth.instance;
//   final _fire = FirebaseFirestore.instance;
//
//   Future<void> reconcile() async {
//     final sp = await SharedPreferences.getInstance();
//     final local = _readLocal(sp);
//
//     final user = _auth.currentUser;
//     if (user == null) return; // offline-only until login
//
//     final docRef = _fire.collection("users").doc(user.uid).collection("settings").doc("preferences");
//     final snap = await docRef.get();
//
//     if (snap.exists) {
//       final remote = snap.data()!;
//       final remoteUpdated = DateTime.tryParse(remote["updatedAt"] ?? "") ?? DateTime.fromMillisecondsSinceEpoch(0);
//       final localUpdated  = DateTime.tryParse(local.updatedAt ?? "") ?? DateTime.fromMillisecondsSinceEpoch(0);
//
//       if (remoteUpdated.isAfter(localUpdated)) {
//         // Apply remote to local
//         await _writeLocal(sp, remote);
//       } else {
//         // Push local to cloud
//         await _writeRemote(docRef, local);
//       }
//     } else {
//       // No remote → upload local
//       await _writeRemote(docRef, local);
//     }
//   }
//
//   Future<void> writeThrough({
//     double? engineVolume,
//     String? builtInBank,
//     String? packId,
//     String? recordingPath,
//     bool? debugBypass,
//   }) async {
//     final sp = await SharedPreferences.getInstance();
//
//     if (engineVolume != null) sp.setDouble(_kEngineVolumeKey, engineVolume);
//     if (builtInBank != null) sp.setString(_kBuiltInBankKey, builtInBank);
//     if (packId != null) sp.setString(_kPackIdKey, packId);
//     if (recordingPath != null) sp.setString(_kRecPathKey, recordingPath);
//     if (debugBypass != null) sp.setBool(_kDebugBypassKey, debugBypass);
//
//     final nowIso = DateTime.now().toUtc().toIso8601String();
//     sp.setString(_kLocalUpdatedKey, nowIso);
//
//     final user = _auth.currentUser;
//     if (user != null) {
//       final docRef = _fire.collection("users").doc(user.uid).collection("settings").doc("preferences");
//       final local = _readLocal(sp);
//       await _writeRemote(docRef, local);
//     }
//   }
//
//   _LocalSettings _readLocal(SharedPreferences sp) {
//     return _LocalSettings(
//       engineVolume: sp.getDouble(_kEngineVolumeKey) ?? 0.7,
//       builtInBank: sp.getString(_kBuiltInBankKey),
//       packId: sp.getString(_kPackIdKey),
//       recordingPath: sp.getString(_kRecPathKey),
//       debugBypass: sp.getBool(_kDebugBypassKey) ?? false,
//       updatedAt: sp.getString(_kLocalUpdatedKey),
//     );
//   }
//
//   Future<void> _writeLocal(SharedPreferences sp, Map<String, dynamic> r) async {
//     await sp.setDouble(_kEngineVolumeKey, (r["engineVolume"] as num?)?.toDouble() ?? 0.7);
//     if (r["selectedBuiltInBank"] != null) await sp.setString(_kBuiltInBankKey, r["selectedBuiltInBank"]);
//     if (r["selectedPackId"] != null) await sp.setString(_kPackIdKey, r["selectedPackId"]);
//     if (r["selectedRecordingPath"] != null) await sp.setString(_kRecPathKey, r["selectedRecordingPath"]);
//     await sp.setBool(_kDebugBypassKey, r["debugBypass"] ?? false);
//     await sp.setString(_kLocalUpdatedKey, r["updatedAt"] ?? DateTime.now().toUtc().toIso8601String());
//   }
//
//   Future<void> _writeRemote(DocumentReference docRef, _LocalSettings s) async {
//     await docRef.set({
//       "engineVolume": s.engineVolume,
//       "selectedBuiltInBank": s.builtInBank,
//       "selectedPackId": s.packId,
//       "selectedRecordingPath": s.recordingPath,
//       "debugBypass": s.debugBypass,
//       "updatedAt": DateTime.now().toUtc().toIso8601String(),
//     });
//   }
// }
//
// class _LocalSettings {
//   final double engineVolume;
//   final String? builtInBank;
//   final String? packId;
//   final String? recordingPath;
//   final bool debugBypass;
//   final String? updatedAt;
//   _LocalSettings({
//     required this.engineVolume,
//     required this.builtInBank,
//     required this.packId,
//     required this.recordingPath,
//     required this.debugBypass,
//     required this.updatedAt,
//   });
// }
