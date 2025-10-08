import 'dart:io';

import 'package:digital_life_care_app/providers/user_provider.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:flutter/material.dart';
// Removed color picker in favor of dark mode toggle
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  bool _twoFA = false;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>();
    _nameCtrl.text = user.username;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings'), actions: const [Padding(padding: EdgeInsets.only(right: 12.0), child: AppBrand.compact(logoSize: 28))]),
      body: Consumer<UserProvider>(
        builder: (context, user, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final source = await showDialog<ImageSource>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Upload Photo'),
                          content: const Text('Choose source'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, ImageSource.gallery), child: const Text('Gallery')),
                            TextButton(onPressed: () => Navigator.pop(ctx, ImageSource.camera), child: const Text('Camera')),
                          ],
                        ),
                      );
                      if (source == null) return;
                      final picked = await ImagePicker().pickImage(source: source, maxWidth: 1024);
                      if (picked == null) return;
                      await context.read<UserProvider>().updatePhoto(File(picked.path));
                    },
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: user.hasPhoto ? null : user.hashColor(),
                      backgroundImage: user.hasPhoto ? FileImage(File(user.photoPath)) : null,
                      child: user.hasPhoto
                          ? null
                          : Text(
                              user.initials(),
                              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Username'),
                      onFieldSubmitted: (_) => _saveName(context),
                    ),
                  ),
                  IconButton(onPressed: () => _saveName(context), icon: const Icon(Icons.save))
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: context.watch<UserProvider>().isDark,
                onChanged: (v) => context.read<UserProvider>().setDarkMode(v),
                title: const Text('Dark Mode'),
              ),
              SwitchListTile(
                value: _twoFA,
                onChanged: (v) async {
                  setState(() => _twoFA = v);
                  if (v) {
                    await showDialog(
                      context: context,
                      builder: (ctx) {
                        final ctrl = TextEditingController();
                        return AlertDialog(
                          title: const Text('Enable 2FA'),
                          content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Enter OTP (mock 123456)')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('2FA Enabled (mock)')));
                              },
                              child: const Text('Verify'),
                            )
                          ],
                        );
                      },
                    );
                  }
                },
                title: const Text('Two-Factor Authentication'),
              ),
              SwitchListTile(
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
                title: const Text('Notifications'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text('Logout'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveName(BuildContext context) async {
    final err = await context.read<UserProvider>().updateUsername(_nameCtrl.text);
    if (err != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
  }
}


