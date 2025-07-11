// lib/services/sound_bank_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sound_bank.dart';

class SoundBankService {
  final Dio _dio = Dio();

  /// Fetch JSON manifest from your server:
  /// [
  ///   { "id":"cruiser_power", "name":"Cruiser – Power", "zipUrl":"https://..." },
  ///   ...
  /// ]
  Future<List<SoundBank>> fetchAvailableBanks() async {
    final resp = await _dio.get('https://your.cdn.com/banks/manifest.json');
    return (resp.data as List).map((m) => SoundBank(
      id:      m['id'],
      name:    m['name'],
      zipUrl:  m['zipUrl'],
    )).toList();
  }

  /// Download & unzip a bank.zip into app documents dir.
  Future<SoundBank> downloadBank(SoundBank bank) async {
    final docDir = await getApplicationDocumentsDirectory();
    final zipPath = '${docDir.path}/${bank.id}.zip';
    final outDir = '${docDir.path}/${bank.id}';

    // Download .zip
    await _dio.download(bank.zipUrl, zipPath);

    // Unpack
    final bytes = File(zipPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final outFile = File('$outDir/${file.name}');
      if (file.isFile) {
        outFile.createSync(recursive: true);
        outFile.writeAsBytesSync(file.content as List<int>);
      }
    }
    bank.downloaded = true;
    bank.localPath  = outDir;

    // Optionally delete the zip
    File(zipPath).deleteSync();
    return bank;
  }
}
