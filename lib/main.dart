// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:revrider/utils/themes.dart';

import 'providers/theme_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/app_state.dart';
import 'services/ble_manager.dart';
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
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
        ),

        Provider(create: (_) => BleManager()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(
          create: (ctx) => AppState(ctx.read<BleManager>()),
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
      home: const HomeScreen(),
    );
  }
}
