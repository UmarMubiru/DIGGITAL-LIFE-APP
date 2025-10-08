import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static const _keyIsAuthenticated = 'auth_is_authenticated';
  static const _keyEmail = 'auth_email';
  static const _keyRole = 'auth_role';
  static const _keyFirstLaunch = 'app_first_launch';

  bool _isAuthenticated = false;
  String _email = '';
  String _role = 'student';
  bool _initialized = false;

  bool get isAuthenticated => _isAuthenticated;
  String get email => _email;
  String get role => _role;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool(_keyIsAuthenticated) ?? false;
    _email = prefs.getString(_keyEmail) ?? '';
    _role = prefs.getString(_keyRole) ?? 'student';
    // default first launch true if not set
    if (!prefs.containsKey(_keyFirstLaunch)) {
      await prefs.setBool(_keyFirstLaunch, true);
    }
    _initialized = true;
    notifyListeners();
  }

  Future<bool> getIsFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }

  Future<void> setNotFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, false);
  }

  Future<String?> register({required String email, required String password, required String role}) async {
    if (!_isValidEmail(email)) return 'Invalid email format';
    if (password.length < 6) return 'Password must be at least 6 characters';
    // Mock: pretend success with slight delay
    await Future.delayed(const Duration(milliseconds: 400));
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = true;
    _email = email;
    _role = role;
    await prefs.setBool(_keyIsAuthenticated, true);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyRole, role);
    notifyListeners();
    return null;
  }

  Future<String?> login({required String email, required String password}) async {
    if (!_isValidEmail(email)) return 'Invalid email format';
    if (password.isEmpty) return 'Password required';
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = true;
    _email = email;
    // keep last role or default student
    _role = prefs.getString(_keyRole) ?? 'student';
    await prefs.setBool(_keyIsAuthenticated, true);
    await prefs.setString(_keyEmail, email);
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = false;
    await prefs.setBool(_keyIsAuthenticated, false);
    notifyListeners();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }
}


