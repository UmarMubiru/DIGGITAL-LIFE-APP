import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(milliseconds: 150),
      () => setState(() => _visible = true),
    );
    Timer(const Duration(milliseconds: 2100), _navigateNext);
  }

  void _navigateNext() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Theme.of(
        context,
      ).colorScheme.onSurface, // replaced onBackground -> onSurface
    );

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedOpacity(
                opacity: _visible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                child: _buildLogo(context),
              ),
              const SizedBox(height: 18),
              AnimatedOpacity(
                opacity: _visible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                child: Text('Welcome to Digital Life Care', style: textStyle),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Image.asset(
        'assets/logo.jpg', // use project logo
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // If logo missing, show app name text instead of an icon
          return Container(
            alignment: Alignment.center,
            child: Text(
              'Digital Life Care',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}
