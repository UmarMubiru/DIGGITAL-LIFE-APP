import 'dart:async';

import 'package:digital_life_care_app/providers/auth_provider.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    if (!auth.initialized) {
      await auth.initialize();
    }
    Timer(const Duration(seconds: 1), () async {
      final isFirst = await auth.getIsFirstLaunch();
      if (isFirst) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/onboarding');
        return;
      }
      if (auth.isAuthenticated) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppBrand.centered(logoSize: 96),
            const SizedBox(height: 24),
            CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }
}


