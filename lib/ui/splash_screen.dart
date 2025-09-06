// lib/ui/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _checking = true;
  String? _error;
  bool _navigated = false; // <- guard against double-nav

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _checking = true;
      _error = null;
    });

    final ok = await context.read<AppState>().ensureGoogleSignedIn();
    if (!mounted || _navigated) return;

    if (ok) {
      _navigated = true;
      // Navigate AFTER the current frame; remove Splash from the back stack.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      });
      return;
    }

    // Stay here and show the button
    setState(() {
      _checking = false;
      _error = 'Google sign-in required';
    });
  }

  Future<void> _retry() => _start();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 96,
                  child: Image.asset(
                    'assets/branding/rydem_logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.motorcycle, size: 72),
                  ),
                ),
                const SizedBox(height: 24),
                Text('rydem', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 32),
                if (_checking) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  const Text('Signing in…'),
                ] else ...[
                  if (_error != null) ...[
                    Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.redAccent)),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in with Google'),
                      onPressed: _retry,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        backgroundColor: const Color(0xFF4285F4),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// // lib/ui/splash_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/app_state.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   bool _checking = true;
//   String? _error;
//
//   @override
//   void initState() {
//     super.initState();
//     _start();
//   }
//
//   Future<void> _start() async {
//     setState(() {
//       _checking = true;
//       _error = null;
//     });
//
//     final ok = await context.read<AppState>().ensureGoogleSignedIn();
//     if (!mounted) return;
//
//     if (ok) {
//       Navigator.pushReplacementNamed(context, '/');
//     } else {
//       // Stay on this screen; show sign-in button
//       setState(() {
//         _checking = false;
//         _error = 'Google sign-in required';
//       });
//     }
//   }
//
//   Future<void> _retry() async {
//     setState(() => _error = null);
//     await _start();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       body: SafeArea(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 28),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Your logo (safe even if asset missing)
//                 SizedBox(
//                   height: 96,
//                   child: Image.asset(
//                     'assets/branding/rydem_logo.png',
//                     fit: BoxFit.contain,
//                     errorBuilder: (_, __, ___) => const Icon(Icons.motorcycle, size: 72),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 Text('rydem', style: theme.textTheme.headlineSmall),
//
//                 const SizedBox(height: 32),
//
//                 if (_checking) ...[
//                   const CircularProgressIndicator(),
//                   const SizedBox(height: 12),
//                   const Text('Signing in…'),
//                 ] else ...[
//                   if (_error != null) ...[
//                     Text(
//                       _error!,
//                       style: theme.textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
//                     ),
//                     const SizedBox(height: 12),
//                   ],
//                   // Forced sign-in button (no skip)
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton.icon(
//                       icon: const Icon(Icons.login),
//                       label: const Text('Sign in with Google'),
//                       onPressed: _retry,
//                       style: ElevatedButton.styleFrom(
//                         minimumSize: const Size.fromHeight(46),
//                         backgroundColor: const Color(0xFF4285F4), // Google blue
//                         foregroundColor: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
