// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'providers/app_state.dart';
import 'providers/purchase_provider.dart';
import 'services/ble_manager.dart';
import 'ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize RevenueCat
  await Purchases.setDebugLogsEnabled(true);
  await Purchases.configure(
    PurchasesConfiguration("public_sdk_key_here"),
  );

  runApp(
    MultiProvider(
      providers: [
        // 1️⃣ Provide a single BleManager instance
        Provider(create: (_) => BleManager()),

        // 2️⃣ Provide your purchase logic
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),

        // 3️⃣ Provide AppState, injecting the BleManager
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
    return MaterialApp(
      title: 'RevRider',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}
