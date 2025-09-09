// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_session/audio_session.dart';

import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/app_state.dart';

import 'services/ble_manager.dart';
import 'services/sound_bank_service.dart';

//import 'ui/splash_screen.dart';
import 'ui/home_screen.dart';
import 'ui/exhaust_studio.dart';
import 'ui/shop_screen.dart';
import 'ui/profile_screen.dart';
import 'ui/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // await FirebaseFirestore.instance
  //     .collection('debug')
  //     .doc('hello')
  //     .set({'ok': true, 'ts': DateTime.now().toIso8601String()});
  // Theme
  final themeProvider = ThemeProvider();
  await themeProvider.load();

  // Configure audio focus/session (media)
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  runApp(
    MultiProvider(
      providers: [
        // Theme
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),

        // Purchases (keep if you use RevenueCat/etc.)
        ChangeNotifierProvider<PurchaseProvider>(create: (_) => PurchaseProvider()),

        // Sound bank service as a singleton (so context.read<SoundBankService>() still works)
        Provider<SoundBankService>.value(value: SoundBankService.instance),

        // BLE & App State
        Provider<BleManager>(create: (_) => BleManager()),
        ChangeNotifierProvider<AppState>(create: (ctx) => AppState(ctx.read<BleManager>())),
      ],
      child: const RydemApp(),
    ),
  );
}

class RydemApp extends StatelessWidget {
  const RydemApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().mode;

    return MaterialApp(
      title: 'Rydem',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // swap to your AppThemes if you have them wired
      // darkTheme: AppThemes.darkTheme,
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        //'/splash': (_)   => const SplashScreen(),
        '/':       (_)   => const HomeScreen(),
        '/studio': (_)   => const ExhaustStudio(),
        '/shop':   (_)   => const ShopScreen(),
        '/profile':(_)   => const ProfileScreen(),
        '/settings':(_)  => const SettingsScreen(),
      },
    );
  }
}


//
// // lib/main.dart
//
// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:audio_session/audio_session.dart';
// import 'package:sleek_circular_slider/sleek_circular_slider.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   final session = await AudioSession.instance;
//   await session.configure(const AudioSessionConfiguration.music());
//   runApp(const rydemMVP());
// }
//
// class rydemMVP extends StatelessWidget {
//   const rydemMVP({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'rydem MVP',
//       theme: ThemeData.dark(),
//       home: const HomePage(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
//
// class HomePage extends StatefulWidget {
//   const HomePage({Key? key}) : super(key: key);
//   @override
//   _HomePageState createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   // BLE
//   final _ble = FlutterReactiveBle();
//   late StreamSubscription<DiscoveredDevice> _scanSub;
//   StreamSubscription<ConnectionStateUpdate>? _connSub;
//   StreamSubscription<List<int>>? _notifySub;
//   DiscoveredDevice? _device;
//   bool _connected = false;
//   bool _isStarting = false; // gate for start-segment
//
//   // Throttle & audio
//   int _throttle = 0;
//   late final AudioManager _audio;
//
//   // UUIDs must match your TTGO firmware
//   static const _SERVICE_UUID = "12345678-1234-5678-1234-56789abcdef0";
//   static const _CHAR_UUID    = "12345678-1234-5678-1234-56789abcdef1";
//   static const _CALIB_UUID   = "12345678-1234-5678-1234-56789abcdef2";
//
//   @override
//   void initState() {
//     super.initState();
//     _audio = AudioManager();
//     _audio.loadBank('default', masterFileName: 'exhaust.mp3');
//   }
//
//   Future<void> _connect() async {
//     setState(() => _connected = false);
//
//     _scanSub = _ble.scanForDevices(
//       withServices: [Uuid.parse(_SERVICE_UUID)],
//       scanMode: ScanMode.lowLatency,
//     ).listen((device) {
//       // stop at first match
//       _scanSub.cancel();
//       _device = device;
//
//       _connSub = _ble
//           .connectToDevice(
//         id: device.id,
//         connectionTimeout: const Duration(seconds: 5),
//       )
//           .listen((event) async {
//         if (event.connectionState == DeviceConnectionState.connected) {
//           setState(() => _connected = true);
//           setState(() => _isStarting = true);
//           await _audio.playStart();      // play start once
//           setState(() => _isStarting = false);
//           _audio.updateThrottle(_throttle); // begin idle loop
//           _subscribeToThrottle(device.id);
//         } else if (event.connectionState == DeviceConnectionState.disconnected) {
//           setState(() => _connected = false);
//           await _notifySub?.cancel();
//           await _audio.playCutoff();
//         }
//       }, onError: (e) {
//         print("Connection error: $e");
//         setState(() => _connected = false);
//       });
//     }, onError: (e) {
//       print("Scan error: $e");
//       setState(() => _connected = false);
//     });
//   }
//
//   void _subscribeToThrottle(String deviceId) {
//     final char = QualifiedCharacteristic(
//       serviceId:        Uuid.parse(_SERVICE_UUID),
//       characteristicId: Uuid.parse(_CHAR_UUID),
//       deviceId:         deviceId,
//     );
//     _notifySub = _ble.subscribeToCharacteristic(char).listen((data) {
//       if (data.isNotEmpty && !_isStarting) {
//         final raw = data[0]; // 0–255
//         final pct = (raw.clamp(0, 255) * 100 / 255).round();
//         setState(() => _throttle = pct);
//         _audio.updateThrottle(pct);
//       }
//     }, onError: (e) {
//       print("Notify error: $e");
//     });
//   }
//
//   Future<void> _disconnect() async {
//     await _connSub?.cancel();
//     await _notifySub?.cancel();
//     setState(() => _connected = false);
//     await _audio.playCutoff();
//   }
//
//   Future<void> _calibrate() async {
//     if (_device == null) return;
//     final calibChar = QualifiedCharacteristic(
//       serviceId:        Uuid.parse(_SERVICE_UUID),
//       characteristicId: Uuid.parse(_CALIB_UUID),
//       deviceId:         _device!.id,
//     );
//     await _ble.writeCharacteristicWithoutResponse(
//       calibChar,
//       value: [1],
//     );
//   }
//
//   @override
//   void dispose() {
//     _scanSub.cancel();
//     _connSub?.cancel();
//     _notifySub?.cancel();
//     _audio.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // gauge size = 90% of shorter screen dimension
//     final size = MediaQuery.of(context).size;
//     final gaugeSize = min(size.width, size.height) * 0.9;
//
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: const Text('rydem MVP'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.tune),
//             tooltip: 'Calibrate Zero',
//             onPressed: _connected ? _calibrate : null,
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _connected ? _disconnect : _connect,
//         child: Icon(_connected ? Icons.bluetooth_disabled : Icons.bluetooth),
//       ),
//       body: Center(
//         child: SizedBox(
//           width: gaugeSize,
//           height: gaugeSize,
//           child: SleekCircularSlider(
//             min: 0,
//             max: 100,
//             initialValue: _throttle.toDouble(),
//             appearance: CircularSliderAppearance(
//               startAngle: 150,
//               angleRange: 240,
//               size: gaugeSize,
//               customWidths: CustomSliderWidths(
//                 trackWidth: 12,
//                 progressBarWidth: 16,
//                 handlerSize: 0,
//               ),
//               customColors: CustomSliderColors(
//                 trackColor: Colors.grey.shade900,
//                 progressBarColor: Colors.redAccent,
//                 dotColor: Colors.redAccent,
//               ),
//               infoProperties: InfoProperties(
//                 modifier: (double value) => '${value.round()}%',
//                 mainLabelStyle: TextStyle(
//                   fontSize: gaugeSize * 0.16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.redAccent,
//                 ),
//                 bottomLabelText: _connected ? 'Throttle' : 'Disconnected',
//                 bottomLabelStyle: TextStyle(
//                   fontSize: gaugeSize * 0.06,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               animationEnabled: true,
//               animDurationMultiplier: 0.3,
//             ),
//             onChange: null,
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// /// AudioManager
//
// enum ThrottleSegment { start, idle, gear1, gear2, gear3, cruise, cutoff }
//
// class AudioManager {
//   final AudioPlayer _player = AudioPlayer();
//   String _bank = 'default';
//   String _file = 'exhaust.mp3';
//   static const _bounds = {
//     ThrottleSegment.start:  [0,    2500],
//     ThrottleSegment.idle:   [2500, 4500],
//     ThrottleSegment.gear1:  [4500, 6500],
//     ThrottleSegment.gear2:  [6500, 8500],
//     ThrottleSegment.gear3:  [8500,10500],
//     ThrottleSegment.cruise: [10500,12500],
//     ThrottleSegment.cutoff:[12500,14500],
//   };
//
//   ThrottleSegment? _currentSeg;
//
//   Future<void> loadBank(String bankId,
//       {String masterFileName = 'exhaust.mp3'}) async {
//     _bank = bankId;
//     _file = masterFileName;
//   }
//
//   Future<void> playStart() async {
//     _currentSeg = ThrottleSegment.start;
//     await _playSegment(ThrottleSegment.start, loop: false);
//   }
//
//   Future<void> playCutoff() async {
//     _currentSeg = ThrottleSegment.cutoff;
//     await _playSegment(ThrottleSegment.cutoff, loop: false);
//   }
//
//   Future<void> updateThrottle(int pct) async {
//     final t = pct / 100.0;
//     final seg = t == 0.0
//         ? ThrottleSegment.idle
//         : t < 0.1
//         ? ThrottleSegment.idle
//         : t < 0.3
//         ? ThrottleSegment.gear1
//         : t < 0.5
//         ? ThrottleSegment.gear2
//         : t < 0.7
//         ? ThrottleSegment.gear3
//         : t < 0.9
//         ? ThrottleSegment.cruise
//         : ThrottleSegment.cutoff;
//
//     // only change if segment differs
//     if (seg == _currentSeg) return;
//     _currentSeg = seg;
//
//     final loop = seg != ThrottleSegment.start && seg != ThrottleSegment.cutoff;
//     await _playSegment(seg, loop: loop);
//   }
//
//   Future<void> _playSegment(ThrottleSegment seg,
//       {required bool loop}) async {
//     final bounds = _bounds[seg]!;
//     final clip = ClippingAudioSource(
//       start: Duration(milliseconds: bounds[0]),
//       end:   Duration(milliseconds: bounds[1]),
//       child: AudioSource.asset('assets/sounds/$_bank/$_file'),
//     );
//     await _player.setAudioSource(clip);
//     await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
//     await _player.play();
//   }
//
//   Future<void> dispose() => _player.dispose();
// }
//
//
