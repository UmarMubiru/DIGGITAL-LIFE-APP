import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digital_life_care_app/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isHealthWorker = false;
  final _formKey = GlobalKey<FormState>();

  // Common fields
  final _usernameCtrl = TextEditingController(); // <-- added username
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Health worker extra fields
  final _licenseCtrl = TextEditingController();
  final _facilityCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _licenseCtrl.dispose();
    _facilityCtrl.dispose();
    _specializationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final role = _isHealthWorker ? 'health_worker' : 'student';
    final profile = <String, dynamic>{
      'username': _usernameCtrl.text.trim(), // <-- include username in profile
      'name': _nameCtrl.text.trim(),
    };
    if (_isHealthWorker) {
      profile.addAll({
        'licenseNumber': _licenseCtrl.text.trim(),
        'facility': _facilityCtrl.text.trim(),
        'specialization': _specializationCtrl.text.trim(),
      });
    }

    try {
      await auth.registerWithRole(
        role: role,
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        profile: profile,
      );
      // if registration succeeded, navigate to login or dashboard
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ToggleButtons(
            isSelected: [_isHealthWorker == false, _isHealthWorker == true],
            onPressed: (idx) => setState(() => _isHealthWorker = idx == 1),
            borderRadius: BorderRadius.circular(8),
            selectedColor: Colors.white,
            fillColor: primary,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text('Student'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text('Health Worker'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                // USERNAME
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) {
                      return 'Enter a username';
                    }
                    if (s.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // FULL NAME
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),

                // EMAIL
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v ?? '').contains('@') ? null : 'Enter valid email',
                ),
                const SizedBox(height: 12),

                // PASSWORD
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) =>
                      (v ?? '').length >= 6 ? null : 'Min 6 characters',
                ),

                if (_isHealthWorker) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _licenseCtrl,
                    decoration: const InputDecoration(
                      labelText: 'License / Reg. number',
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Enter license number'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _facilityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Facility / Organization',
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Enter facility' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _specializationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Specialization',
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                ],
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Register'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
