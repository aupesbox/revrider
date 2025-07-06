import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'providers/theme_provider.dart';
import 'providers/activation_provider.dart';
import 'services/ble_manager.dart';
import 'providers/app_state.dart';
import 'ui/home_screen.dart';
import 'utils/themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Purchases.configure(
    PurchasesConfiguration("public_sdk_key_here"),
  );
  // Load theme choice
  final themeProvider = ThemeProvider();
  await themeProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider<ActivationProvider>(create: (_) {
          final ap = ActivationProvider();
          ap.load();
          return ap;
        }),
        Provider(create: (_) => BleManager()),
        ChangeNotifierProvider<AppState>(
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
      home: const HomeScreen(),
    );
  }
}
