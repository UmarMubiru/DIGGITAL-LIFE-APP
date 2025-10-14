import 'package:digital_life_care_app/providers/auth_provider.dart';
import 'package:digital_life_care_app/providers/awareness_provider.dart';
import 'package:digital_life_care_app/providers/user_provider.dart';
import 'package:digital_life_care_app/providers/reminder_provider.dart';
import 'package:digital_life_care_app/screens/awareness/awareness_detail_screen.dart';
import 'package:digital_life_care_app/screens/awareness/awareness_home_screen.dart';
import 'package:digital_life_care_app/screens/auth/login_screen.dart';
import 'package:digital_life_care_app/screens/auth/register_screen.dart';
import 'package:digital_life_care_app/screens/onboarding_screen.dart';
import 'package:digital_life_care_app/screens/home_shell.dart';
import 'package:digital_life_care_app/screens/profile_screen.dart';
import 'package:digital_life_care_app/screens/splash_screen.dart';
import 'package:digital_life_care_app/screens/booking.dart';
import 'package:digital_life_care_app/screens/reminder.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const RootApp());
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => UserProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => AwarenessProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()..initialize()),
      ],
      child: Consumer<UserProvider>(
        builder: (context, user, _) => MaterialApp(
          title: 'Digital Life Care',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            // Base color scheme with explicit overrides for surfaces/buttons
            colorScheme:
                ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: user.isDark ? Brightness.dark : Brightness.light,
                ).copyWith(
                  surface: user.isDark
                      ? const Color(0xFF263238)
                      : const Color(0xFFF2F2F2),
                  primary: const Color(0xFF1976D2), // normal blue for buttons
                  onPrimary: Colors.white,
                ),
            scaffoldBackgroundColor: user.isDark
                ? const Color(0xFF0D47A1)
                : const Color(0xFFB3E5FC),
            cardTheme: const CardThemeData(
              color: Color(0xFFF2F2F2), // greyish cards
              margin: EdgeInsets.all(12),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2), // blue buttons
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(
                  0xFF1976D2,
                ), // links like Forgot Password
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: const Color(0xFF388E3C), // grass green
              indicatorColor: const Color(0xFF2E7D32),
              surfaceTintColor: Colors.transparent,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              labelTextStyle: WidgetStateProperty.all(
                const TextStyle(color: Colors.white),
              ),
              iconTheme: WidgetStateProperty.all(
                const IconThemeData(color: Colors.white),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
          ),
          initialRoute: '/splash',
          routes: {
            '/splash': (_) => const SplashScreen(),
            '/onboarding': (_) => const OnboardingScreen(),
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const RegisterScreen(),
            '/profile': (_) => const ProfileScreen(),
            '/dashboard': (_) => const HomeShell(),
            '/awareness': (_) => const AwarenessHomeScreen(),
            '/booking': (_) => const BookingScreen(),
            '/reminder': (_) => const ReminderScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/awareness/detail') {
              return MaterialPageRoute(
                builder: (_) => const AwarenessDetailScreen(),
                settings: settings,
              );
            }
            return null;
          },
        ),
      ),
    );
  }
}
