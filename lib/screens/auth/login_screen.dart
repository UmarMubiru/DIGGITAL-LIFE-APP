import 'package:digital_life_care_app/providers/auth_provider.dart';
import 'package:digital_life_care_app/providers/user_provider.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 8),
              const AppBrand.centered(logoSize: 72),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email or Username',
                ),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Enter email or username';
                  final isEmail = value.contains('@');
                  if (isEmail) {
                    final emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    return emailRe.hasMatch(value)
                        ? null
                        : 'Enter a valid email';
                  }
                  final userRe = RegExp(r'^[A-Za-z0-9_.]{3,20}$');
                  return userRe.hasMatch(value)
                      ? null
                      : 'Enter a valid username';
                },
              ),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter password' : null,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (ctx) {
                        final ctrl = TextEditingController();
                        return AlertDialog(
                          title: const Text('Reset Password'),
                          content: TextField(
                            controller: ctrl,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                // Add your password reset logic here if needed
                              },
                              child: const Text('Send'),
                            ),
                          ],
                        );
                      },
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reset link sent (mock)')),
                    );
                  },
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    final input = _usernameCtrl.text.trim();
                    final auth = context.read<AuthProvider>();

                    final err = await auth.login(
                      identifier: input,
                      password: _passwordCtrl.text,
                    );

                    // Guard use of BuildContext after async call
                    if (!mounted) return;

                    if (err != null) {
                      ScaffoldMessenger.of(
                        // ignore: use_build_context_synchronously
                        context,
                      ).showSnackBar(SnackBar(content: Text(err)));
                      return;
                    }

                    // Refresh UserProvider after login to get username and role from Firestore
                    // ignore: use_build_context_synchronously
                    final userProvider = context.read<UserProvider>();
                    await userProvider.refreshFromFirestore();

                    // Use the role from AuthProvider (which was just set during login)
                    // Double-check with UserProvider to ensure consistency
                    final role = auth.role.trim().toLowerCase();
                    final userRole = userProvider.role.trim().toLowerCase();
                    
                    // Use auth.role as primary source, fallback to userRole if empty
                    final finalRole = role.isNotEmpty ? role : userRole;
                    
                    // Check if user is a health worker (case-insensitive check)
                    final isHealthWorker = finalRole == 'health_worker' || finalRole == 'worker';
                    
                    if (isHealthWorker) {
                      // ignore: use_build_context_synchronously
                      Navigator.pushReplacementNamed(context, '/hw');
                    } else {
                      // ignore: use_build_context_synchronously
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    }
                  },
                  child: const Text('Login'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/register'),
                child: const Text('No account? Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
