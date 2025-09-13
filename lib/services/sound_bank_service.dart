// lib/services/sound_bank_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/exhaust_pack.dart';

class SoundBankService {
  SoundBankService._();
  static final instance = SoundBankService._();

  Future<String> _root() async {
    final dir = await getApplicationSupportDirectory();
    final root = '${dir.path}/exhausts';
    await Directory(root).create(recursive: true);
    return root;
  }

  Future<List<ExhaustPack>> listInstalled() async {
    final root = await _root();
    final rootDir = Directory(root);
    if (!await rootDir.exists()) return [];

    final packs = <ExhaustPack>[];
    await for (final ent in rootDir.list()) {
      if (ent is Directory) {
        final metaFile = File('${ent.path}/meta.json');
        if (await metaFile.exists()) {
          try {
            final meta = jsonDecode(await metaFile.readAsString()) as Map;
            packs.add(
              ExhaustPack(
                id: meta['id'] as String,
                name: meta['name'] as String,
                dirPath: ent.path,
                source: (meta['source'] as String?) ?? 'store',
                version: (meta['version'] as int?) ?? 1,
              ),
            );
          } catch (_) {}
        }
      }
    }
    packs.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return packs;
  }

  /// Download pack ZIP or individual files. Here: individual file URLs.
  /// If you deliver a ZIP, unzip with an archive lib (e.g., archive_io).
  Future<ExhaustPack> installFromUrls({
    required String id,
    required String name,
    required Uri idleUrl,
    required Uri midUrl,
    required Uri highUrl,
    String source = 'store',
    int version = 1,
  }) async {
    final root = await _root();
    final packDir = Directory('$root/$id');
    if (await packDir.exists()) {
      await packDir.delete(recursive: true);
    }
    await packDir.create(recursive: true);

    final dio = Dio();
    final idlePath = '${packDir.path}/idle1.wav';
    final midPath  = '${packDir.path}/mid.mp3';
    final highPath = '${packDir.path}/high.mp3';

    await dio.download(idleUrl.toString(), idlePath);
    await dio.download(midUrl.toString(),  midPath);
    await dio.download(highUrl.toString(), highPath);

    final meta = {
      'id': id,
      'name': name,
      'version': version,
      'source': source,
    };
    await File('${packDir.path}/meta.json').writeAsString(jsonEncode(meta));

    return ExhaustPack(
      id: id, name: name, dirPath: packDir.path, source: source, version: version,
    );
  }

  Future<void> deletePack(String id) async {
    final root = await _root();
    final d = Directory('$root/$id');
    if (await d.exists()) await d.delete(recursive: true);
  }
}
