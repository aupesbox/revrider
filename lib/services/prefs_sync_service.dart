// lib/services/prefs_sync_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrefsSyncService {
  static const _keys = [
    'engineVolume',
    'selectedBuiltInBank',
    'selectedPackId',
    'selectedRecordingPath',
    'debugBypass',
  ];

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = auth.currentUser?.uid;
    Map<String, dynamic> result = {};

    if (uid != null) {
      try {
        final doc =
        await firestore.collection('users').doc(uid).collection('prefs').doc('main').get();
        if (doc.exists) {
          result = doc.data()!;
          for (final key in _keys) {
            if (result.containsKey(key)) {
              await prefs.setString(key, result[key].toString());
            }
          }
          return result;
        }
      } catch (e) {
        print('⚠️ Error loading cloud prefs: $e');
      }
    }

    // fallback: local
    for (final key in _keys) {
      final val = prefs.get(key);
      if (val != null) result[key] = val;
    }
    return result;
  }

  Future<void> savePrefs(Map<String, dynamic> prefsToSave) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = auth.currentUser?.uid;

    // Save locally
    for (final entry in prefsToSave.entries) {
      final key = entry.key;
      final val = entry.value;
      if (val is String) {
        await prefs.setString(key, val);
      } else if (val is int) await prefs.setInt(key, val);
      else if (val is double) await prefs.setDouble(key, val);
      else if (val is bool) await prefs.setBool(key, val);
    }

    // Save to Firestore
    if (uid != null) {
      try {
        await firestore
            .collection('users')
            .doc(uid)
            .collection('prefs')
            .doc('main')
            .set(prefsToSave, SetOptions(merge: true));
      } catch (e) {
        print('⚠️ Error saving cloud prefs: $e');
      }
    }
  }
}
