import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/purchase_provider.dart';
import '../services/activation_service.dart';
import 'app_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ActivationService _actService = ActivationService();
  Map<String, dynamic>? _activation;

  @override
  void initState() {
    super.initState();
    _loadActivation();
  }

  Future<void> _loadActivation() async {
    final act = await _actService.getActivation();
    setState(() => _activation = act);
  }

  Future<void> _enterCodeManually() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter Activation JSON'),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: '{"deviceId":"...", "tier":"basic", "activatedDate":"..."}',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;

    try {
      final data = jsonDecode(result);
      if (data is! Map<String, dynamic>) throw const FormatException();
      await _actService.saveActivation(data);
      await _loadActivation();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activation saved!')));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid JSON')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActivated = _activation != null;
    final isPremium   = context.watch<PurchaseProvider>().isPremium;

    return AppScaffold(
      title: 'Profile',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isActivated) ...[
            ListTile(
              leading: const Icon(Icons.device_hub),
              title: const Text('Device ID'),
              subtitle: Text('${_activation!['deviceId']}'),
            ),
            ListTile(
              leading: const Icon(Icons.verified_user),
              title: const Text('Tier'),
              subtitle: Text('${_activation!['tier']}'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Activated On'),
              subtitle: Text('${_activation!['activatedDate']}'),
            ),
          ] else ...[
            const ListTile(
              leading: Icon(Icons.warning_amber_rounded),
              title: Text('Not activated'),
              subtitle: Text('Please enter the activation code manually.'),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(isActivated ? Icons.edit : Icons.code),
            label: Text(isActivated ? 'Edit Activation' : 'Enter Activation Code'),
            onPressed: _enterCodeManually,
          ),

          // Show upgrade option if basic user
          if (!isPremium) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.upgrade),
              label: const Text('Upgrade to Premium'),
              onPressed: () {
                // TODO: Launch IAP flow
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Premium upgrade coming soon!')),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
