// lib/services/sound_bank_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';

import '../models/sound_bank.dart';

class SoundBankService {
  /// Downloads a ZIP for [bankId] and unpacks it into a local directory.
  /// Returns the path to the directory, or null on failure.
  /// Fetches the JSON catalog of categories → brands → models
  Future<List<SoundBankCategory>> fetchCatalog() async {
    final jsonStr = await rootBundle.loadString('assets/catalog.json');
    final data = jsonDecode(jsonStr) as List<dynamic>;
    return data
        .map((j) => SoundBankCategory.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // Future<List<SoundBankCategory>> fetchCatalog() async {
  //   const url = 'asset://assets/catalog.json';
  //   final response = await http.get(Uri.parse(url));
  //
  //   if (response.statusCode != 200) {
  //     throw Exception('Failed to load sound bank catalog');
  //   }
  //
  //   final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
  //   return data
  //       .map((json) => SoundBankCategory.fromJson(json as Map<String, dynamic>))
  //       .toList();
  // }
  Future<String?> downloadAndUnzip(String bankId, String zipUrl) async {
    try {
      List<int> bytes;
      if (zipUrl.startsWith('asset://')) {
        final assetPath = zipUrl.replaceFirst('asset://', '');
        bytes = (await rootBundle.load(assetPath)).buffer.asUint8List();
      } else {
        final res = await http.get(Uri.parse(zipUrl));
        if (res.statusCode != 200) return null;
        bytes = res.bodyBytes;
      }
      final archive = ZipDecoder().decodeBytes(bytes);
      // 2) Get app documents dir and create a folder
      final baseDir = await getApplicationDocumentsDirectory();
      final outDir = Directory('${baseDir.path}/banks/$bankId');
      if (!outDir.existsSync()) outDir.createSync(recursive: true);

      // 3) Decode & extract
      //final bytes = res.bodyBytes;
      //final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        final filePath = '${outDir.path}/${file.name}';
        if (file.isFile) {
          File(filePath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(file.content as List<int>);
        }
      }

      return outDir.path;
    } catch (e) {
      print('Download/unzip failed for $bankId: $e');
      return null;
    }
  }
}
