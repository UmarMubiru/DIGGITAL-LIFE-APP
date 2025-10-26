import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool(_keyIsAuthenticated) ?? false;
    _email = prefs.getString(_keyEmail) ?? '';
    _role = prefs.getString(_keyRole) ?? 'student';
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

  /// --- Firebase Register ---
  Future<String?> register({
    required String email,
    required String password,
    required String role,
  }) async {
    if (!_isValidEmail(email)) return 'Invalid email format';
    if (password.length < 6) return 'Password must be at least 6 characters';

    try {
      // Create Firebase Auth user
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store extra info in Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update local state + SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _isAuthenticated = true;
      _email = email;
      _role = role;
      await prefs.setBool(_keyIsAuthenticated, true);
      await prefs.setString(_keyEmail, email);
      await prefs.setString(_keyRole, role);
      notifyListeners();

      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Registration failed: $e';
    }
  }

  /// --- Firebase Login ---
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    if (!_isValidEmail(email)) return 'Invalid email format';
    if (password.isEmpty) return 'Password required';

    try {
      UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Fetch role from Firestore
      final doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      final fetchedRole = doc['role'] ?? 'student';

      // Update local state + SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _isAuthenticated = true;
      _email = email;
      _role = fetchedRole;
      await prefs.setBool(_keyIsAuthenticated, true);
      await prefs.setString(_keyEmail, email);
      await prefs.setString(_keyRole, fetchedRole);
      notifyListeners();

      return fetchedRole; // return role for routing
    } on FirebaseAuthException catch (e) {
      return 'error:${e.message}';
    } catch (e) {
      return 'error:Login failed: $e';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
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
