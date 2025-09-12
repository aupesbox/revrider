// lib/ui/app_scaffold.dart

import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? bottomBar;
  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.bottomBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const Text(
                'rydem',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);               // close drawer
                Navigator.pushNamedAndRemoveUntil(
                  context, '/', (route) => false,     // go back to home
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Exhaust Studio'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/studio');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Shop Sounds'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/shop');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/test'),
              child: const Text('Test Harness'),
            )

          ],
        ),
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: bottomBar,
    );
  }
}
