// lib/ui/exhaust_studio.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../providers/app_state.dart';
import 'app_scaffold.dart';
import '../providers/purchase_provider.dart';

class ExhaustStudio extends StatefulWidget {
  const ExhaustStudio({super.key});
  @override
  State<ExhaustStudio> createState() => _ExhaustStudioState();
}

class _ExhaustStudioState extends State<ExhaustStudio> {
  // record v5+
  final AudioRecorder _rec = AudioRecorder();
  bool _isRecording = false;
  String? _lastSavedPath;

  // 45s limit + counter
  static const int _maxSecs = 45;
  int _elapsed = 0;
  Timer? _recTimer;

  // selectors (unchanged)
  String? _pendingBuiltIn;
  String? _pendingPackId;

  // recordings list
  List<FileSystemEntity> _recordings = [];
  String? _pendingRecordingPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AppState>().refreshInstalledPacks();
      await _refreshRecordings();
    });
  }

  @override
  void dispose() {
    _recTimer?.cancel();
    _rec.dispose();
    super.dispose();
  }

  // ─────────────────── Recording helpers ───────────────────

  Future<void> _startRecording() async {
    try {
      // 1) Ask for a filename
      final proposed = await _askFilename(context);
      if (proposed == null) return; // user cancelled

      final hasPerm = await _rec.hasPermission();
      if (!hasPerm) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mic permission denied')),
        );
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final safe = _sanitizeFilename(proposed);
      final filePath = _uniquePathIn(dir, '$safe.m4a');

      // 2) Start recording
      await _rec.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      // 3) Start 45s timer
      _elapsed = 0;
      _recTimer?.cancel();
      _recTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
        if (!mounted) return;
        setState(() => _elapsed++);
        if (_elapsed >= _maxSecs) {
          // auto-stop at 45s
          await _stopRecording(auto: true);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Max 45s reached — recording saved')),
          );
        }
      });

      setState(() {
        _isRecording = true;
        _lastSavedPath = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording started')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording failed to start: $e')),
      );
    }
  }

  Future<void> _stopRecording({bool auto = false}) async {
    try {
      _recTimer?.cancel();
      final path = await _rec.stop();
      setState(() {
        _isRecording = false;
        _lastSavedPath = path;
      });
      await _refreshRecordings(); // list immediately
      if (!mounted || auto) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(path != null ? 'Saved: $path' : 'Recording stopped')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stop failed: $e')),
      );
    }
  }

  Future<void> _refreshRecordings() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = Directory(dir.path)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.m4a'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    setState(() {
      _recordings = files;
      _pendingRecordingPath ??= files.isNotEmpty ? files.first.path : null;
    });
  }

  // ─────────────────── UI helpers ───────────────────

  InputDecoration _roundedInput(String hint) => InputDecoration(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    isDense: true,
    hintText: hint,
  );

  String _formatMMSS(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _sanitizeFilename(String input) {
    // allow letters, numbers, space, dash, underscore
    final trimmed = input.trim();
    final clean = trimmed.replaceAll(RegExp(r'[^A-Za-z0-9 _-]+'), '');
    return clean.isEmpty ? 'exhaust_${DateTime.now().millisecondsSinceEpoch}' : clean;
  }

  String _uniquePathIn(Directory dir, String baseName) {
    var name = baseName;
    var attempt = 1;
    while (File('${dir.path}${Platform.pathSeparator}$name').existsSync()) {
      final dot = baseName.lastIndexOf('.');
      final stem = dot > 0 ? baseName.substring(0, dot) : baseName;
      final ext = dot > 0 ? baseName.substring(dot) : '';
      name = '$stem ($attempt)$ext';
      attempt++;
    }
    return '${dir.path}${Platform.pathSeparator}$name';
  }

  Future<String?> _askFilename(BuildContext context) async {
    final ctrl = TextEditingController();
    String? errorText;

    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            // Declare BEFORE use
            void validateAndPop() {
              final raw = ctrl.text.trim();
              if (raw.isEmpty) {
                setState(() => errorText = 'Please enter a name');
                return;
              }
              if (raw.length > 50) {
                setState(() => errorText = 'Keep it under 50 characters');
                return;
              }
              if (!RegExp(r'^[A-Za-z0-9 _-]+$').hasMatch(raw)) {
                setState(() => errorText = 'Only letters, numbers, spaces, - and _');
                return;
              }
              Navigator.of(ctx).pop(raw);
            }

            return AlertDialog(
              title: const Text('Name your recording'),
              content: TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Ninja650 idle',
                  errorText: errorText,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => validateAndPop(), // use it here
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: validateAndPop, // and here
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    _pendingBuiltIn ??= app.selectedBuiltInBank;
    _pendingPackId ??= app.selectedPackId;
    final purchaseProv = context.watch<PurchaseProvider>();
    const aiProductId = 'ai_sound_update';
    final aiOwned = purchaseProv.isPurchased(aiProductId);

// Only allow processing if user has a recording selected
    final hasRecording = app.selectedRecordingPath != null && app.selectedRecordingPath!.isNotEmpty;

    return AppScaffold(
      title: 'Exhaust Studio',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Calibrate
            ElevatedButton.icon(
              icon: const Icon(Icons.tune),
              label: const Text('Re-Calibrate Throttle'),
              onPressed: app.isConnected ? () => app.calibrateThrottle() : null,
            ),
            const SizedBox(height: 16),

            // Preview
            ElevatedButton(
              onPressed: () => app.audio.updateThrottle(50),
              child: const Text('Preview Throttle (50%)'),
            ),
            const SizedBox(height: 24),

            // Built-in
            Text('Built-in Exhaust', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _pendingBuiltIn,
                    items: app.builtInBanks
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) => setState(() => _pendingBuiltIn = v),
                    decoration: _roundedInput('Select built-in bank'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: (_pendingBuiltIn != null)
                      ? () async {
                    await context.read<AppState>().selectBuiltInBank(_pendingBuiltIn!);
                    setState(() {
                      _pendingPackId = null;
                      _pendingRecordingPath = null;
                    });
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Using built-in: $_pendingBuiltIn')),
                    );
                  }
                      : null,
                  child: const Text('Use'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Packs
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _pendingPackId,
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('None')),
                      ...app.installedPacks.map(
                            (p) => DropdownMenuItem<String?>(value: p.id, child: Text(p.name)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _pendingPackId = v),
                    decoration: _roundedInput('Installed packs'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    await context.read<AppState>().selectExhaustPack(_pendingPackId);
                    setState(() => _pendingRecordingPath = null);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _pendingPackId == null
                              ? 'Using built-in: ${app.selectedBuiltInBank}'
                              : 'Using pack: ${app.installedPacks.firstWhere((p) => p.id == _pendingPackId).name}',
                        ),
                      ),
                    );
                  },
                  child: const Text('Use'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Recordings
            Text('Your Recordings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _pendingRecordingPath,
                    items: _recordings.isEmpty
                        ? const [
                      DropdownMenuItem<String?>(value: null, child: Text('No recordings yet')),
                    ]
                        : _recordings
                        .map((f) => DropdownMenuItem<String?>(
                      value: f.path,
                      child: Text(
                        f.uri.pathSegments.isNotEmpty
                            ? f.uri.pathSegments.last
                            : f.path.split(Platform.pathSeparator).last,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                        .toList(),
                    onChanged: (v) => setState(() => _pendingRecordingPath = v),
                    decoration: _roundedInput('Select a recording'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: (_pendingRecordingPath != null)
                      ? () async {
                    await context.read<AppState>().selectRecordingFile(_pendingRecordingPath!);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Using your recording')),
                    );
                  }
                      : null,
                  child: const Text('Use'),
                ),
              ],
            ),

            const Divider(height: 32),

            // Engine volume
            Text('Engine Volume: ${(app.engineVolume * 100).round()}%'),
            Slider(
              value: app.engineVolume,
              min: 0,
              max: 1,
              divisions: 20,
              label: '${(app.engineVolume * 100).round()}%',
              onChanged: (v) => context.read<AppState>().setEngineVolume(v),
            ),

            const Divider(height: 32),

            // Recording controls + counter
            Text('Recording', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                    label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.red : null,
                    ),
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_fix_high),
              label: Text(
                aiOwned
                    ? (hasRecording ? 'AI Process Recording' : 'Select a recording to process')
                    : 'Unlock AI to Process',
              ),
              onPressed: aiOwned
                  ? (hasRecording ? () => _runAiProcess(context) : null)
                  : () {
                // Nudge to Shop
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchase AI Sound Update to enable processing')),
                );
                Navigator.pushNamed(context, '/shop');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: aiOwned
                    ? (hasRecording ? const Color(0xFFCC5500) : Colors.grey)
                    : Colors.grey,
                foregroundColor: Colors.white,
              ),
            ),


            const SizedBox(height: 8),
            if (_isRecording) ...[
              LinearProgressIndicator(value: _elapsed / _maxSecs),
              const SizedBox(height: 6),
              Text(
                '${_formatMMSS(_elapsed)} / ${_formatMMSS(_maxSecs)}',
                textAlign: TextAlign.center,
              ),
            ] else if (_lastSavedPath != null) ...[
              const SizedBox(height: 4),
              Text(
                'Saved: $_lastSavedPath',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 24),
            Text('Live Throttle: ${app.latestAngle}%', textAlign: TextAlign.center),
          ],
        ),
      ),
    );

  }
  void _runAiProcess(BuildContext context) async {
    final app = context.read<AppState>();
    final path = app.selectedRecordingPath;
    if (path == null || path.isEmpty) return;

    // TODO: plug in AI pipeline here.
    // After AI finishes, call app.installAiProcessedPack(...)
    // with generated idle/mid/high file paths.

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('AI processing started for "${path.split('/').last}" (stub)')),
    );
  }

}

// // lib/ui/exhaust_studio.dart
// // ...imports unchanged...
// // lib/ui/exhaust_studio.dart
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:record/record.dart';
//
// import '../providers/app_state.dart';
// import 'app_scaffold.dart';
//
// class ExhaustStudio extends StatefulWidget {
//   const ExhaustStudio({super.key});
//   @override
//   State<ExhaustStudio> createState() => _ExhaustStudioState();
// }
//
// class _ExhaustStudioState extends State<ExhaustStudio> {
//   final AudioRecorder _rec = AudioRecorder();
//   bool _isRecording = false;
//   String? _lastSavedPath;
//
//   String? _pendingBuiltIn; // bank name
//   String? _pendingPackId;  // pack id
//
//   // NEW: recordings list & selection
//   List<FileSystemEntity> _recordings = [];
//   String? _pendingRecordingPath; // file path
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await context.read<AppState>().refreshInstalledPacks();
//       await _refreshRecordings();
//     });
//   }
//
//   @override
//   void dispose() {
//     _rec.dispose();
//     super.dispose();
//   }
//
//   Future<void> _refreshRecordings() async {
//     final dir = await getApplicationDocumentsDirectory();
//     final files = Directory(dir.path)
//         .listSync()
//         .whereType<File>()
//         .where((f) =>
//     f.path.toLowerCase().endsWith('.m4a') &&
//         f.path.toLowerCase().contains('exhaust_'))
//         .toList()
//       ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
//     setState(() {
//       _recordings = files;
//       // keep current selection if present; else pick latest
//       if (_pendingRecordingPath == null && files.isNotEmpty) {
//         _pendingRecordingPath = files.first.path;
//       }
//     });
//   }
//
//   // Recording helpers (unchanged except call _refreshRecordings on stop)
//   Future<void> _startRecording() async {
//     try {
//       final hasPerm = await _rec.hasPermission();
//       if (!hasPerm) {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mic permission denied')));
//         return;
//       }
//       final dir = await getApplicationDocumentsDirectory();
//       final ts = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
//       final filePath = '${dir.path}${Platform.pathSeparator}exhaust_$ts.m4a';
//
//       await _rec.start(
//         const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
//         path: filePath,
//       );
//
//       setState(() {
//         _isRecording = true;
//         _lastSavedPath = null;
//       });
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recording started')));
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recording failed: $e')));
//     }
//   }
//
//   Future<void> _stopRecording() async {
//     try {
//       final path = await _rec.stop();
//       setState(() {
//         _isRecording = false;
//         _lastSavedPath = path;
//       });
//       await _refreshRecordings(); // <— NEW: immediately list it
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(path != null ? 'Saved: $path' : 'Recording stopped')),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stop failed: $e')));
//     }
//   }
//
//   InputDecoration _roundedInput(String hint) => InputDecoration(
//     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//     enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//     focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//     isDense: true,
//     hintText: hint,
//   );
//
//   @override
//   Widget build(BuildContext context) {
//     final app = context.watch<AppState>();
//     _pendingBuiltIn ??= app.selectedBuiltInBank;
//     _pendingPackId ??= app.selectedPackId;
//
//     return AppScaffold(
//       title: 'Exhaust Studio',
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Calibration
//             ElevatedButton.icon(
//               icon: const Icon(Icons.tune),
//               label: const Text('Re-Calibrate Throttle'),
//               onPressed: app.isConnected ? () => app.calibrateThrottle() : null,
//             ),
//             const SizedBox(height: 16),
//
//             // Preview
//             ElevatedButton(
//               onPressed: () => app.audio.updateThrottle(50),
//               child: const Text('Preview Throttle (50%)'),
//             ),
//             const SizedBox(height: 24),
//
//             // ===== Built-in Selector =====
//             Text('Select Exhaust', style: Theme.of(context).textTheme.titleMedium),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Expanded(
//                   child: DropdownButtonFormField<String>(
//                     value: _pendingBuiltIn,
//                     items: app.builtInBanks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
//                     onChanged: (v) => setState(() => _pendingBuiltIn = v),
//                     decoration: _roundedInput('Select built-in bank'),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 ElevatedButton(
//                   onPressed: (_pendingBuiltIn != null)
//                       ? () async {
//                     await context.read<AppState>().selectBuiltInBank(_pendingBuiltIn!);
//                     setState(() {
//                       _pendingPackId = null;
//                       _pendingRecordingPath = null;
//                     });
//                     if (!mounted) return;
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Using built-in: $_pendingBuiltIn')),
//                     );
//                   }
//                       : null,
//                   child: const Text('Use'),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//
//             // ===== Installed Pack Selector =====
//             Row(
//               children: [
//                 Expanded(
//                   child: DropdownButtonFormField<String?>(
//                     value: _pendingPackId,
//                     items: [
//                       const DropdownMenuItem<String?>(value: null, child: Text('None')),
//                       ...app.installedPacks.map(
//                             (p) => DropdownMenuItem<String?>(value: p.id, child: Text(p.name)),
//                       ),
//                     ],
//                     onChanged: (v) => setState(() => _pendingPackId = v),
//                     decoration: _roundedInput('Installed packs'),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 ElevatedButton(
//                   onPressed: () async {
//                     await context.read<AppState>().selectExhaustPack(_pendingPackId);
//                     setState(() => _pendingRecordingPath = null);
//                     if (!mounted) return;
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text(
//                           _pendingPackId == null
//                               ? 'Using built-in: ${app.selectedBuiltInBank}'
//                               : 'Using pack: ${app.installedPacks.firstWhere((p) => p.id == _pendingPackId).name}',
//                         ),
//                       ),
//                     );
//                   },
//                   child: const Text('Use'),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 12),
//
//             // ===== Recordings Selector (NEW) =====
//             Text('Your Recordings', style: Theme.of(context).textTheme.titleMedium),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Expanded(
//                   child: DropdownButtonFormField<String?>(
//                     value: _pendingRecordingPath,
//                     items: _recordings.isEmpty
//                         ? const [DropdownMenuItem<String?>(value: null, child: Text('No recordings yet'))]
//                         : _recordings
//                         .map((f) => DropdownMenuItem<String?>(
//                       value: f.path,
//                       child: Text(
//                         f.uri.pathSegments.isNotEmpty
//                             ? f.uri.pathSegments.last
//                             : f.path.split(Platform.pathSeparator).last,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ))
//                         .toList(),
//                     onChanged: (v) => setState(() => _pendingRecordingPath = v),
//                     decoration: _roundedInput('Select a recording'),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 ElevatedButton(
//                   onPressed: (_pendingRecordingPath != null)
//                       ? () async {
//                     await context.read<AppState>().selectRecordingFile(_pendingRecordingPath!);
//                     setState(() {
//                       _pendingPackId = null;
//                       _pendingBuiltIn = app.selectedBuiltInBank; // display only
//                     });
//                     if (!mounted) return;
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Using your recording')),
//                     );
//                   }
//                       : null,
//                   child: const Text('Use'),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Align(
//               alignment: Alignment.centerRight,
//               child: Wrap(
//                 spacing: 8,
//                 children: [
//                   TextButton.icon(
//                     onPressed: _refreshRecordings,
//                     icon: const Icon(Icons.refresh),
//                     label: const Text('Refresh'),
//                   ),
//                   // AI Process placeholder
//                   ElevatedButton.icon(
//                     onPressed: (_pendingRecordingPath != null)
//                         ? () {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('AI processing coming soon…')),
//                       );
//                     }
//                         : null,
//                     icon: const Icon(Icons.auto_awesome),
//                     label: const Text('AI Process'),
//                   ),
//                 ],
//               ),
//             ),
//
//             const Divider(height: 32),
//
//             // ===== Engine Volume only =====
//             Text('Engine Volume: ${(app.engineVolume * 100).round()}%'),
//             Slider(
//               value: app.engineVolume,
//               min: 0,
//               max: 1,
//               divisions: 20,
//               label: '${(app.engineVolume * 100).round()}%',
//               onChanged: (v) => context.read<AppState>().setEngineVolume(v),
//             ),
//
//             const Divider(height: 32),
//
//             // ===== Recording controls =====
//             Text('Recording', style: Theme.of(context).textTheme.titleMedium),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     icon: Icon(_isRecording ? Icons.stop : Icons.mic),
//                     label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
//                     onPressed: _isRecording ? _stopRecording : _startRecording,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: _isRecording ? Colors.red : null,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             if (_isRecording)
//               const Row(
//                 children: [
//                   SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
//                   SizedBox(width: 8),
//                   Text('Recording...'),
//                 ],
//               ),
//             if (!_isRecording && _lastSavedPath != null) ...[
//               const SizedBox(height: 4),
//               Text(
//                 'Saved: $_lastSavedPath',
//                 style: Theme.of(context).textTheme.bodySmall,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//
//             const SizedBox(height: 24),
//             Text('Live Throttle: ${app.latestAngle}%', textAlign: TextAlign.center),
//           ],
//         ),
//       ),
//     );
//   }
// }
