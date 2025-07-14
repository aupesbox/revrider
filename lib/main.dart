// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'utils/themes.dart';
import 'providers/theme_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/sound_bank_provider.dart';
import 'services/sound_bank_service.dart';
import 'services/ble_manager.dart';
import 'providers/app_state.dart';
import 'ui/splash_screen.dart';
import 'ui/home_screen.dart';
import 'ui/prelaunch_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ Initialize RevenueCat
  await Purchases.setDebugLogsEnabled(true);
  await Purchases.configure(
    PurchasesConfiguration('public_sdk_key_here'),
  );

  // 2️⃣ Load saved theme preference
  final themeProvider = ThemeProvider();
  await themeProvider.load();

  // 3️⃣ Run app with providers
  runApp(
    MultiProvider(
      providers: [
        // Theme provider first
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
        ),

        // In-app purchases
        ChangeNotifierProvider<PurchaseProvider>(
          create: (_) => PurchaseProvider(),
        ),

        // Sound bank service
        Provider<SoundBankService>(
          create: (_) => SoundBankService(),
        ),

        // Sound bank provider (depends on SoundBankService & PurchaseProvider)
        ChangeNotifierProvider<SoundBankProvider>(
          create: (context) => SoundBankProvider(
            context.read<SoundBankService>(),
            context.read<PurchaseProvider>(),
          ),
        ),

        // BLE manager
        Provider<BleManager>(
          create: (_) => BleManager(),
          dispose: (_, manager) => manager.dispose(),
        ),

        // App state (depends on BleManager)
        ChangeNotifierProvider<AppState>(
          create: (context) => AppState(
            context.read<BleManager>(),
          ),
        ),
      ],
      child: const RevRiderApp(),
    ),
  );
}

class RevRiderApp extends StatelessWidget {
  const RevRiderApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().mode;

    return MaterialApp(
      title: 'RevRider',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeMode,
      //home: const SplashScreen(),
      home: const PreLaunchScreen(),
      routes: {
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}

// // lib/main.dart
//
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:purchases_flutter/purchases_flutter.dart';
//
// import 'utils/themes.dart';
// import 'providers/theme_provider.dart';
// import 'providers/purchase_provider.dart';
// import 'providers/sound_bank_provider.dart';
// import 'services/sound_bank_service.dart';
// import 'services/ble_manager.dart';
// import 'providers/app_state.dart';
// import 'ui/splash_screen.dart';
// import 'ui/home_screen.dart';
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // 1️⃣ Initialize RevenueCat
//   await Purchases.setDebugLogsEnabled(true);
//   await Purchases.configure(
//     PurchasesConfiguration('public_sdk_key_here'),
//   );
//
//   // 2️⃣ Load saved theme preference
//   final themeProvider = ThemeProvider();
//   await themeProvider.load();
//
//   // 3️⃣ Run app with providers
//   runApp(
//     MultiProvider(
//       providers: [
//         // Theme provider first
//         ChangeNotifierProvider<ThemeProvider>.value(
//           value: themeProvider,
//         ),
//
//         // In-app purchases
//         ChangeNotifierProvider<PurchaseProvider>(
//           create: (_) => PurchaseProvider(),
//         ),
//
//         // Sound bank service
//         Provider<SoundBankService>(
//           create: (_) => SoundBankService(),
//         ),
//
//         // Sound bank provider (depends on SoundBankService & PurchaseProvider)
//         ChangeNotifierProvider<SoundBankProvider>(
//           create: (context) => SoundBankProvider(
//             context.read<SoundBankService>(),
//             context.read<PurchaseProvider>(),
//           ),
//         ),
//
//         // BLE manager
//         Provider<BleManager>(
//           create: (_) => BleManager(),
//           dispose: (_, manager) => manager.dispose(),
//         ),
//
//         // App state (depends on BleManager)
//         ChangeNotifierProvider<AppState>(
//           create: (context) => AppState(
//             context.read<BleManager>(),
//           ),
//         ),
//       ],
//       child: const RevRiderApp(),
//     ),
//   );
// }
//
// class RevRiderApp extends StatelessWidget {
//   const RevRiderApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final themeMode = context.watch<ThemeProvider>().mode;
//
//     return MaterialApp(
//       title: 'RevRider',
//       debugShowCheckedModeBanner: false,
//       theme: AppThemes.lightTheme,
//       darkTheme: AppThemes.darkTheme,
//       themeMode: themeMode,
//       home: const SplashScreen(),
//       routes: {
//         '/home': (_) => const HomeScreen(),
//       },
//     );
//   }
// }
//
// // // lib/main.dart
// //
// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import 'package:purchases_flutter/purchases_flutter.dart';
// //
// // import 'utils/themes.dart';
// // import 'providers/theme_provider.dart';
// // import 'providers/purchase_provider.dart';
// // import 'providers/sound_bank_provider.dart';
// // import 'services/sound_bank_service.dart';
// // import 'services/ble_manager.dart';
// // import 'providers/app_state.dart';
// // import 'ui/splash_screen.dart';
// // import 'ui/home_screen.dart';
// //
// // void main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //
// //   // 1️⃣ Init RevenueCat
// //   await Purchases.setDebugLogsEnabled(true);
// //   await Purchases.configure(
// //     PurchasesConfiguration("public_sdk_key_here"),
// //   );
// //
// //   // 2️⃣ Init ThemeProvider
// //   final themeProvider = ThemeProvider();
// //   await themeProvider.load();
// //
// //   runApp(
// //     MultiProvider(
// //       providers: [
// //         // Theme
// //         ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
// //
// //         // Purchases
// //         ChangeNotifierProvider(create: (_) => PurchaseProvider()),
// //
// //         // Sound‐bank service → needed by SoundBankProvider
// //         Provider<SoundBankService>(create: (_) => SoundBankService()),
// //
// //         // SoundBankProvider (reads SoundBankService + PurchaseProvider)
// //         ChangeNotifierProvider<SoundBankProvider>(
// //           create: (ctx) => SoundBankProvider(
// //             ctx.read<SoundBankService>(),
// //             ctx.read<PurchaseProvider>(),
// //           ),
// //         ),
// //
// //         // BLE manager
// //         Provider(create: (_) => BleManager()),
// //
// //         // App state (needs BLE & can read PurchaseProvider if you like)
// //         ChangeNotifierProvider(
// //           create: (ctx) => AppState(ctx.read<BleManager>()),
// //         ),
// //       ],
// //       child: const RevRiderApp(),
// //     ),
// //   );
// // }
// //
// // class RevRiderApp extends StatelessWidget {
// //   const RevRiderApp({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final themeMode = context.watch<ThemeProvider>().mode;
// //
// //     return MaterialApp(
// //       title: 'RevRider',
// //       debugShowCheckedModeBanner: false,
// //       theme: AppThemes.lightTheme,
// //       darkTheme: AppThemes.darkTheme,
// //       themeMode: themeMode,
// //       home: const SplashScreen(),
// //       routes: {
// //         '/home': (_) => const HomeScreen(),
// //       },
// //     );
// //   }
// // }
