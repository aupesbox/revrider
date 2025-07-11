// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:revrider/providers/sound_bank_provider.dart';

import 'utils/themes.dart';
import 'providers/theme_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/app_state.dart';
import 'services/ble_manager.dart';
import 'ui/splash_screen.dart';
import 'ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ Init RevenueCat
  await Purchases.setDebugLogsEnabled(true);
  await Purchases.configure(
    PurchasesConfiguration("public_sdk_key_here"),
  );

  // 2️⃣ Init ThemeProvider
  final themeProvider = ThemeProvider();
  await themeProvider.load(); // load saved preference

  runApp(
    MultiProvider(
      providers: [
        // Theme must come first so every screen can read it
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProxyProvider<PurchaseProvider, SoundBankProvider>(
          // create only runs once, so we grab the PurchaseProvider right away
          create: (context) => SoundBankProvider(context.read<PurchaseProvider>()),
          // update will be called whenever PurchaseProvider changes
          update: (context, purchaseProv, bankProv) =>
          bankProv!..updatePurchaseProvider(purchaseProv),
        ),
        // BLE manager
        Provider(create: (_) => BleManager()),


        // AppState (needs BleManager & PurchaseProvider)
        ChangeNotifierProvider(
          create: (ctx) => AppState(ctx.read<BleManager>()),
        ),
      ],
      child: const RevRiderApp(),
    ),
  );
}

class RevRiderApp extends StatelessWidget {
  const RevRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().mode;

    return MaterialApp(
      title: 'RevRider',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeMode,
      // Start at the splash screen, which will auto-navigate to HomeScreen
      home: const SplashScreen(),
      routes: {
        // Named route in case you need to push directly:
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}
