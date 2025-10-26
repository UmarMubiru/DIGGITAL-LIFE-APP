import 'package:digital_life_care_app/providers/auth_provider.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _role = 'student';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 8),
              const Center(child: AppBrand.centered(logoSize: 72)),
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
                (v == null || v.length < 6) ? 'Min 6 characters' : null,
              ),
              TextFormField(
                controller: _confirmCtrl,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                ),
                obscureText: true,
                validator: (v) =>
                v != _passwordCtrl.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                onChanged: (v) => setState(() => _role = v ?? 'student'),
                items: const [
                  DropdownMenuItem(value: 'student', child: Text('Student')),
                  DropdownMenuItem(
                    value: 'worker',
                    child: Text('Health Worker'),
                  ),
                ],
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    // --- Firebase backend logic ---
                    final err = await context.read<AuthProvider>().register(
                      email: _emailCtrl.text.trim(),
                      password: _passwordCtrl.text,
                      role: _role,
                    );

                    if (err != null) {
                      if (!mounted) return;
                      messenger.showSnackBar(SnackBar(content: Text(err)));
                      return;
                    }

                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Registration successful')),
                    );
                    navigator.pushReplacementNamed('/dashboard');
                  },
                  child: const Text('Create Account'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text('Have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
