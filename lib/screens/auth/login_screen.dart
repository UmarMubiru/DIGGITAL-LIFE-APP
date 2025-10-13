import 'package:digital_life_care_app/providers/auth_provider.dart';
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
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
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
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Enter a valid email'
                    : null,
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
                    // Use local ctx for dialog interactions and avoid using outer context
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
                                // Defer using outer context until after the dialog completes
                              },
                              child: const Text('Send'),
                            ),
                          ],
                        );
                      },
                    );
                    // Dialog closed; ensure widget still mounted before using context
                    if (!mounted) return;
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
                    // Capture objects that depend on BuildContext before awaiting
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    final err = await context.read<AuthProvider>().login(
                      email: _emailCtrl.text.trim(),
                      password: _passwordCtrl.text,
                    );
                    if (err != null) {
                      if (!mounted) return;
                      messenger.showSnackBar(SnackBar(content: Text(err)));
                      return;
                    }
                    if (!mounted) return;
                    navigator.pushReplacementNamed('/dashboard');
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
