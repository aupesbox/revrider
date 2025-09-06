// lib/ui/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/user_profile.dart';
import 'app_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _aliasCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _marketingOptIn = true;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile;
    _applyProfile(p);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = context.watch<AppState>().profile;
    _applyProfile(p, soft: true);
  }

  void _applyProfile(UserProfile p, {bool soft = false}) {
    if (!soft || _nameCtrl.text.isEmpty)  _nameCtrl.text = p.name;
    if (!soft || _aliasCtrl.text.isEmpty) _aliasCtrl.text = p.alias;
    if (!soft || _emailCtrl.text.isEmpty) _emailCtrl.text = p.email;
    if (!soft || _phoneCtrl.text.isEmpty) _phoneCtrl.text = p.phone;
    _marketingOptIn = p.marketingOptIn;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _aliasCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint, Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AppState>().updateProfile(
      name: _nameCtrl.text.trim(),
      alias: _aliasCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      marketingOptIn: _marketingOptIn,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved')),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final confirmCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Delete account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This is a permanent action. Type DELETE to confirm. (UI only)'),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Type DELETE',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, confirmCtrl.text.trim().toUpperCase() == 'DELETE'),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deletion requested (UI only)')),
      );
    }
  }

  void _logout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out (UI only)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final p = app.profile;

    return AppScaffold(
      title: 'Profile',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Read-only Google status (sign-in enforced at splash)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white10,
                        backgroundImage: (p.googlePhotoUrl != null)
                            ? NetworkImage(p.googlePhotoUrl!)
                            : null,
                        child: (p.googlePhotoUrl == null)
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.googleSignedIn ? (p.name.isEmpty ? 'Google user' : p.name)
                                  : 'Not connected',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              p.email.isEmpty ? '—' : p.email,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      // No connect/disconnect button here (read-only)
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Avatar + change (UI-only)
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.person, size: 42),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Change photo (UI only)')),
                        );
                      },
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Change photo'),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: _dec('Full name', hint: 'e.g. Aman Verma', prefix: const Icon(Icons.badge)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 12),

              // Alias
              TextFormField(
                controller: _aliasCtrl,
                textInputAction: TextInputAction.next,
                decoration: _dec('Alias', hint: 'e.g. rev_king', prefix: const Icon(Icons.tag)),
              ),
              const SizedBox(height: 12),

              // Email
              TextFormField(
                controller: _emailCtrl,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                decoration: _dec('Email', hint: 'you@example.com', prefix: const Icon(Icons.email)),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (t.isEmpty) return 'Please enter your email';
                  if (!re.hasMatch(t)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Phone
              TextFormField(
                controller: _phoneCtrl,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.phone,
                decoration: _dec('Phone', hint: '+91 98765 43210', prefix: const Icon(Icons.phone)),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Please enter your phone';
                  if (t.replaceAll(RegExp(r'\D'), '').length < 7) return 'Enter a valid phone';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Marketing opt-in
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('I agree to receive updates & offers'),
                value: _marketingOptIn,
                onChanged: (v) => setState(() => _marketingOptIn = v),
              ),

              const SizedBox(height: 16),

              // Save
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),

              // Danger zone (UI-only)
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Danger zone', style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Log out'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete account'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        foregroundColor: Colors.redAccent,
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// // lib/ui/profile_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/app_state.dart';
// import '../models/user_profile.dart';
// import 'app_scaffold.dart';
//
// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});
//
//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends State<ProfileScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameCtrl = TextEditingController();
//   final _aliasCtrl = TextEditingController();
//   final _emailCtrl = TextEditingController();
//   final _phoneCtrl = TextEditingController();
//   bool _marketingOptIn = true;
//
//   @override
//   void initState() {
//     super.initState();
//     // Prefill from stored profile
//     final p = context.read<AppState>().profile;
//     _applyProfile(p);
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     // If profile changes while screen is open, keep in sync
//     final p = context.watch<AppState>().profile;
//     _applyProfile(p, soft: true);
//   }
//
//   void _applyProfile(UserProfile p, {bool soft = false}) {
//     // soft=true will not overwrite user typing
//     if (!soft || _nameCtrl.text.isEmpty)  _nameCtrl.text = p.name;
//     if (!soft || _aliasCtrl.text.isEmpty) _aliasCtrl.text = p.alias;
//     if (!soft || _emailCtrl.text.isEmpty) _emailCtrl.text = p.email;
//     if (!soft || _phoneCtrl.text.isEmpty) _phoneCtrl.text = p.phone;
//     _marketingOptIn = p.marketingOptIn;
//   }
//
//   @override
//   void dispose() {
//     _nameCtrl.dispose();
//     _aliasCtrl.dispose();
//     _emailCtrl.dispose();
//     _phoneCtrl.dispose();
//     super.dispose();
//   }
//
//   InputDecoration _dec(String label, {String? hint, Widget? prefix}) {
//     return InputDecoration(
//       labelText: label,
//       hintText: hint,
//       prefixIcon: prefix,
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//       enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//       focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//       isDense: true,
//     );
//   }
//
//   void _save() {
//     if (!_formKey.currentState!.validate()) return;
//     context.read<AppState>().updateProfile(
//       name: _nameCtrl.text.trim(),
//       alias: _aliasCtrl.text.trim(),
//       email: _emailCtrl.text.trim(),
//       phone: _phoneCtrl.text.trim(),
//       marketingOptIn: _marketingOptIn,
//     );
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Profile saved')),
//     );
//   }
//
//   Future<void> _confirmDelete() async {
//     final ok = await showDialog<bool>(
//       context: context,
//       builder: (ctx) {
//         final confirmCtrl = TextEditingController();
//         return AlertDialog(
//           title: const Text('Delete account?'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text('This is a permanent action. Type DELETE to confirm. (UI only)'),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: confirmCtrl,
//                 decoration: const InputDecoration(
//                   border: OutlineInputBorder(),
//                   labelText: 'Type DELETE',
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//               onPressed: () => Navigator.pop(ctx, confirmCtrl.text.trim().toUpperCase() == 'DELETE'),
//               child: const Text('Delete'),
//             ),
//           ],
//         );
//       },
//     );
//     if (ok == true && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Account deletion requested (UI only)')),
//       );
//     }
//   }
//
//   void _logout() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Logged out (UI only)')),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final app = context.watch<AppState>();
//     final p = app.profile;
//
//     return AppScaffold(
//       title: 'Profile',
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               // Google account row
//               Card(
//                 elevation: 2,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 child: Padding(
//                   padding: const EdgeInsets.all(12),
//                   child: Row(
//                     children: [
//                       CircleAvatar(
//                         radius: 22,
//                         backgroundColor: Colors.white10,
//                         backgroundImage: (p.googlePhotoUrl != null) ? NetworkImage(p.googlePhotoUrl!) : null,
//                         child: (p.googlePhotoUrl == null) ? const Icon(Icons.person) : null,
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(p.googleSignedIn ? (p.name.isEmpty ? 'Google user' : p.name) : 'Not connected'),
//                             Text(
//                               p.email.isEmpty ? '—' : p.email,
//                               style: Theme.of(context).textTheme.bodySmall,
//                             ),
//                           ],
//                         ),
//                       ),
//                       ElevatedButton.icon(
//                         onPressed: () async {
//                           if (!p.googleSignedIn) {
//                             final ok = await context.read<AppState>().signInWithGoogle();
//                             if (mounted) {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(content: Text(ok ? 'Google connected' : 'Google sign-in failed')),
//                               );
//                             }
//                           } else {
//                             await context.read<AppState>().signOutGoogle();
//                             if (mounted) {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(content: Text('Disconnected Google')),
//                               );
//                             }
//                           }
//                         },
//                         icon: Icon(p.googleSignedIn ? Icons.logout : Icons.login),
//                         label: Text(p.googleSignedIn ? 'Disconnect' : 'Connect Google'),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 16),
//
//               // Avatar + change (UI-only)
//               Center(
//                 child: Column(
//                   children: [
//                     CircleAvatar(
//                       radius: 38,
//                       backgroundColor: Colors.white10,
//                       child: const Icon(Icons.person, size: 42),
//                     ),
//                     const SizedBox(height: 8),
//                     TextButton.icon(
//                       onPressed: () {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(content: Text('Change photo (UI only)')),
//                         );
//                       },
//                       icon: const Icon(Icons.camera_alt, size: 18),
//                       label: const Text('Change photo'),
//                     )
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),
//
//               // Name
//               TextFormField(
//                 controller: _nameCtrl,
//                 textInputAction: TextInputAction.next,
//                 decoration: _dec('Full name', hint: 'e.g. Aman Verma', prefix: const Icon(Icons.badge)),
//                 validator: (v) =>
//                 (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
//               ),
//               const SizedBox(height: 12),
//
//               // Alias
//               TextFormField(
//                 controller: _aliasCtrl,
//                 textInputAction: TextInputAction.next,
//                 decoration: _dec('Alias', hint: 'e.g. rev_king', prefix: const Icon(Icons.tag)),
//               ),
//               const SizedBox(height: 12),
//
//               // Email
//               TextFormField(
//                 controller: _emailCtrl,
//                 textInputAction: TextInputAction.next,
//                 keyboardType: TextInputType.emailAddress,
//                 decoration: _dec('Email', hint: 'you@example.com', prefix: const Icon(Icons.email)),
//                 validator: (v) {
//                   final t = v?.trim() ?? '';
//                   final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
//                   if (t.isEmpty) return 'Please enter your email';
//                   if (!re.hasMatch(t)) return 'Enter a valid email';
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 12),
//
//               // Phone
//               TextFormField(
//                 controller: _phoneCtrl,
//                 textInputAction: TextInputAction.done,
//                 keyboardType: TextInputType.phone,
//                 decoration: _dec('Phone', hint: '+91 98765 43210', prefix: const Icon(Icons.phone)),
//                 validator: (v) {
//                   final t = v?.trim() ?? '';
//                   if (t.isEmpty) return 'Please enter your phone';
//                   if (t.replaceAll(RegExp(r'\D'), '').length < 7) return 'Enter a valid phone';
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 12),
//
//               // Marketing opt-in
//               SwitchListTile(
//                 contentPadding: EdgeInsets.zero,
//                 title: const Text('I agree to receive updates & offers'),
//                 value: _marketingOptIn,
//                 onChanged: (v) => setState(() => _marketingOptIn = v),
//               ),
//
//               const SizedBox(height: 16),
//
//               // Save
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   icon: const Icon(Icons.save),
//                   label: const Text('Save'),
//                   onPressed: _save,
//                   style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
//                 ),
//               ),
//
//               const SizedBox(height: 24),
//               const Divider(),
//               const SizedBox(height: 8),
//
//               // Danger zone
//               Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text('Danger zone', style: Theme.of(context).textTheme.titleMedium),
//               ),
//               const SizedBox(height: 8),
//
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: _logout,
//                       icon: const Icon(Icons.logout),
//                       label: const Text('Log out'),
//                       style: OutlinedButton.styleFrom(
//                         minimumSize: const Size.fromHeight(44),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: _confirmDelete,
//                       icon: const Icon(Icons.delete_forever),
//                       label: const Text('Delete account'),
//                       style: OutlinedButton.styleFrom(
//                         side: const BorderSide(color: Colors.redAccent),
//                         foregroundColor: Colors.redAccent,
//                         minimumSize: const Size.fromHeight(44),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
