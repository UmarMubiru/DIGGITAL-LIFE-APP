import 'package:digital_life_care_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_Slide> slides = [
    _Slide(title: 'Welcome', text: 'Privacy-first health companion'),
    _Slide(title: 'Features', text: 'Awareness, Booking, Reminders, Chat'),
    _Slide(title: 'Your Data', text: 'Mock-only now; real backend later'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: slides.length,
              itemBuilder: (context, index) {
                final slide = slides[index];
                return Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(slide.title, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 12),
                        Text(slide.text, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              slides.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await context.read<AuthProvider>().setNotFirstLaunch();
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Get Started'),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _Slide {
  final String title;
  final String text;
  _Slide({required this.title, required this.text});
}


