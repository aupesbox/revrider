import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:revrider/ui/shop_screen.dart';
import 'package:revrider/ui/upgrade_screen.dart';
import '../providers/purchase_provider.dart';
import 'home_screen.dart';
import 'exhaust_studio.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  final String title;

  const AppScaffold({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PurchaseProvider>().isPremium;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text('RevRider', style: TextStyle(fontSize: 24, color: Colors.white)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Home'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Exhaust Studio'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ExhaustStudio()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Shop Sounds'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShopScreen()),
                );
              },
            ),
            if (isPremium) ...[
              ListTile(
                leading: const Icon(Icons.upgrade),
                title: const Text('Upgrade'),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                  );
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:revrider/ui/home_screen.dart';
// import 'package:revrider/ui/exhaust_studio.dart';
// import 'package:revrider/ui/shop_screen.dart';
// import 'package:revrider/ui/settings_screen.dart';
// import 'package:revrider/ui/profile_screen.dart';
// import 'package:revrider/ui/upgrade_screen.dart';
//
// class AppScaffold extends StatelessWidget {
//   final Widget child;
//   final String title;
//
//   const AppScaffold({Key? key, required this.child, required this.title})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(title),
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             DrawerHeader(
//               decoration: BoxDecoration(
//                 color: Theme.of(context).primaryColor,
//               ),
//               child: Text(
//                 'RevRider',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 24,
//                 ),
//               ),
//             ),
//             ListTile(
//               leading: Icon(Icons.home),
//               title: const Text('Home'),
//               onTap: () => Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (_) => const HomeScreen()),
//               ),
//             ),
//             ListTile(
//               leading: Icon(Icons.tune),
//               title: const Text('Exhaust Studio'),
//               onTap: () => Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (_) => const ExhaustStudio()),
//               ),
//             ),
//             ListTile(
//               leading: Icon(Icons.store),
//               title: const Text('Shop Sounds'),
//               onTap: () => Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (_) => const ShopScreen()),
//               ),
//             ),
//             ListTile(
//               leading: Icon(Icons.settings),
//               title: const Text('Settings'),
//               onTap: () => Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (_) => const SettingsScreen()),
//               ),
//             ),
//             ListTile(
//               leading: Icon(Icons.person),
//               title: const Text('Profile'),
//               onTap: () => Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (_) => const ProfileScreen()),
//               ),
//             ),
//             ListTile(
//               leading: Icon(Icons.upgrade),
//               title: const Text('Upgrade'),
//               onTap: () => Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (_) => const UpgradeScreen()),
//               ),
//             ),
//           ],
//         ),
//       ),
//       body: child,
//     );
//   }
// }
// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import 'package:revrider/ui/shop_screen.dart';
// // import 'package:revrider/ui/upgrade_screen.dart';
// // import '../providers/purchase_provider.dart';
// // import 'home_screen.dart';
// // import 'exhaust_studio.dart';
// // import 'music_screen.dart';
// // import 'settings_screen.dart';
// // import 'profile_screen.dart';
// //
// // class AppScaffold extends StatelessWidget {
// //   final Widget child;
// //   final String title;
// //
// //   const AppScaffold({
// //     super.key,
// //     required this.child,
// //     required this.title,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     // Only show premium screens when activated as premium
// //     final isPremium = context.watch<PurchaseProvider>().isPremium;
// //
// //     return Scaffold(
// //       appBar: AppBar(title: Text(title)),
// //       drawer: Drawer(
// //         child: ListView(
// //           padding: EdgeInsets.zero,
// //           children: [
// //             const DrawerHeader(
// //               decoration: BoxDecoration(color: Colors.deepPurple),
// //               child: Text('RevRider', style: TextStyle(fontSize: 24, color: Colors.white)),
// //             ),
// //             ListTile(
// //               leading: const Icon(Icons.dashboard),
// //               title: const Text('Home'),
// //               onTap: () {
// //                 Navigator.pushReplacement(
// //                   context,
// //                   MaterialPageRoute(builder: (_) => const HomeScreen()),
// //                 );
// //               },
// //             ),
// //             ListTile(
// //               leading: const Icon(Icons.tune),
// //               title: const Text('Exhaust Studio'),
// //               onTap: () {
// //                 Navigator.pushReplacement(
// //                   context,
// //                   MaterialPageRoute(builder: (_) => const ExhaustStudio()),
// //                 );
// //               },
// //             ),
// //
// //
// //             ListTile(
// //               leading: const Icon(Icons.store),
// //               title: const Text('Shop'),
// //               onTap: () {
// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(builder: (_) => const ShopScreen()),
// //                 );
// //               },
// //             ),
// //             ListTile(
// //               leading: const Icon(Icons.settings),
// //               title: const Text('Settings'),
// //               onTap: () {
// //                 Navigator.pushReplacement(
// //                   context,
// //                   MaterialPageRoute(builder: (_) => const SettingsScreen()),
// //                 );
// //               },
// //             ),
// //             ListTile(
// //               leading: const Icon(Icons.person),
// //               title: const Text('Profile'),
// //               onTap: () {
// //                 Navigator.pushReplacement(
// //                   context,
// //                   MaterialPageRoute(builder: (_) => const ProfileScreen()),
// //                 );
// //               },
// //             ),
// //           ],
// //         ),
// //       ),
// //       body: child,
// //     );
// //   }
// // }
