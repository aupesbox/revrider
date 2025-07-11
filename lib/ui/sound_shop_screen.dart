// lib/ui/sound_shop_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';

import '../providers/purchase_provider.dart';

class SoundShopScreen extends StatefulWidget {
  const SoundShopScreen({Key? key}) : super(key: key);

  @override
  State<SoundShopScreen> createState() => _SoundShopScreenState();
}

class _SoundShopScreenState extends State<SoundShopScreen> {
  bool _downloading = false;
  double _progress = 0.0;

  Future<void> _buyAndDownloadPack({
    required String packId,
    required String packName,
    required String url,
  }) async {
    final purchaseProvider = context.read<PurchaseProvider>();

    // 1️⃣ Launch purchase flow
    final success = await purchaseProvider.purchaseItem(packId);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase failed')),
      );
      return;
    }

    // 2️⃣ Download zip
    setState(() {
      _downloading = true;
      _progress = 0;
    });
    final dio = Dio();
    final dir = await getApplicationDocumentsDirectory();
    final zipPath = '${dir.path}/$packId.zip';

    try {
      await dio.download(
        url,
        zipPath,
        onReceiveProgress: (received, total) {
          setState(() => _progress = received / total);
        },
      );

      // 3️⃣ Unzip into sounds/$packId/
      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        final outPath = '${dir.path}/sounds/$packId/${file.name}';
        if (file.isFile) {
          final outFile = File(outPath);
          outFile.createSync(recursive: true);
          outFile.writeAsBytesSync(file.content as List<int>);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('“$packName” downloaded!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download error: $e')),
      );
    } finally {
      setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchaseProvider = context.watch<PurchaseProvider>();

    // Example packs; replace URLs with your server’s.
    final packs = [
      {
        'id': 'cruiser_pack',
        'name': 'Cruiser Sound Pack',
        'url': 'https://example.com/cruiser.zip',
      },
      {
        'id': 'sport_pack',
        'name': 'Sport Sound Pack',
        'url': 'https://example.com/sport.zip',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Sound Shop')),
      body: _downloading
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(value: _progress),
            const SizedBox(height: 16),
            Text('${(_progress * 100).toStringAsFixed(0)}%'),
          ],
        ),
      )
          : ListView.separated(
        itemCount: packs.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          final pack = packs[i];
          final owned = purchaseProvider.isItemPurchased(pack['id']!);
          return ListTile(
            title: Text(pack['name']!),
            trailing: ElevatedButton(
              onPressed: owned
                  ? null
                  : () => _buyAndDownloadPack(
                packId: pack['id']!,
                packName: pack['name']!,
                url: pack['url']!,
              ),
              child: Text(owned ? 'Owned' : 'Buy & Download'),
            ),
          );
        },
      ),
    );
  }
}
