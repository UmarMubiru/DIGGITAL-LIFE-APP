import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
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
    required String username,
  }) async {
    if (!_isValidEmail(email)) return 'Invalid email format';
    if (password.length < 6) return 'Password must be at least 6 characters';
    final trimmedUsername = username.trim();
    if (!_isValidUsername(trimmedUsername)) {
      return 'Enter a valid username (letters, numbers, _ or . , 3-20 chars)';
    }

    try {
      // Ensure username is unique
      final usernameDoc = await _firestore
          .collection('usernames')
          .doc(trimmedUsername.toLowerCase())
          .get();
      if (usernameDoc.exists) {
        return 'Username already taken';
      }

      // Create Firebase Auth user
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Store extra info in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'username': trimmedUsername,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create username -> uid mapping (for username login)
      await _firestore
          .collection('usernames')
          .doc(trimmedUsername.toLowerCase())
          .set({'uid': userCredential.user!.uid, 'email': email});

      // Sign out after registration so user stays on register and uses Login
      await _auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      _isAuthenticated = false;
      await prefs.setBool(_keyIsAuthenticated, false);
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
    required String identifier, // email or username
    required String password,
  }) async {
    try {
      String email = identifier.trim();

      // if identifier is not an email, first try the usernames mapping
      if (!email.contains('@')) {
        final key = identifier.trim().toLowerCase();
        final mapping = await _firestore.collection('usernames').doc(key).get();
        if (mapping.exists) {
          final mappedEmail = (mapping.data() ?? {})['email'] as String?;
          if (mappedEmail != null && mappedEmail.isNotEmpty) {
            email = mappedEmail;
          }
        } else {
          // fallback: try users collection query on profile.usernameLower (case-insensitive)
          final q = await _firestore
              .collection('users')
              .where('profile.usernameLower', isEqualTo: key)
              .limit(1)
              .get();
          if (q.docs.isNotEmpty) {
            final udata = q.docs.first.data();
            email = (udata['email'] ?? email) as String;
          } else {
            return 'User not found';
          }
        }
      }

      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCred.user!.uid;

      final doc = await _firestore.collection('users').doc(uid).get();
      final map = doc.data() ?? {};
      
      // Retrieve role from Firestore - check both top-level and profile
      String? firestoreRole;
      if (map.containsKey('role')) {
        firestoreRole = map['role'] as String?;
      } else if (map.containsKey('profile') && map['profile'] is Map) {
        final profile = map['profile'] as Map<String, dynamic>;
        firestoreRole = profile['role'] as String?;
      }
      
      // Ensure role is valid - default to 'student' if not found or invalid
      _role = (firestoreRole != null && firestoreRole.isNotEmpty) 
          ? firestoreRole.trim().toLowerCase() 
          : 'student';
      
      _email = (map['email'] ?? email) as String;
      _isAuthenticated = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsAuthenticated, true);
      await prefs.setString(_keyEmail, _email);
      await prefs.setString(_keyRole, _role);

      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    }
  }

  /// Login with username by resolving to email
  Future<String?> loginWithUsername({
    required String username,
    required String password,
  }) async {
    final trimmed = username.trim();
    if (!_isValidUsername(trimmed)) return 'Invalid username format';
    if (password.isEmpty) return 'Password required';

    try {
      final mapping = await _firestore
          .collection('usernames')
          .doc(trimmed.toLowerCase())
          .get();
      if (!mapping.exists) {
        return 'Username not found';
      }
      final mappedEmail = (mapping.data() ?? const {})['email'] as String?;
      if (mappedEmail == null || !_isValidEmail(mappedEmail)) {
        return 'Account mapping invalid';
      }

      // Reuse the unified login flow
      return await login(identifier: mappedEmail, password: password);
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

  bool _isValidUsername(String username) {
    final re = RegExp(r'^[A-Za-z0-9_.]{3,20}$');
    return re.hasMatch(username);
  }

  /// Register a user, attach role/profile and create username mapping.
  Future<void> registerWithRole({
    required String role, // 'student' or 'health_worker'
    required String email,
    required String password,
    Map<String, dynamic>? profile,
  }) async {
    try {
      // create auth user
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCred.user!.uid;

      // prepare profile and username mapping
      final prof = Map<String, dynamic>.from(profile ?? {});
      final username = (prof['username'] ?? '').toString().trim();
      if (username.isNotEmpty) {
        prof['username'] = username;
        prof['usernameLower'] = username.toLowerCase();
      }

      // write user doc and username mapping in a batch (atomic)
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(uid);
      final userData = {
        'email': email,
        'role': role,
        'profile': prof,
        'createdAt': FieldValue.serverTimestamp(),
      };
      batch.set(userRef, userData);

      if (username.isNotEmpty) {
        final unameRef = _firestore
            .collection('usernames')
            .doc(username.toLowerCase());
        // ensure mapping doesn't already exist
        final unameSnap = await unameRef.get();
        if (unameSnap.exists) {
          // rollback auth user to avoid orphaned auth accounts
          await userCred.user?.delete();
          throw FirebaseException(
            plugin: 'auth',
            message: 'Username already in use. Choose another.',
          );
        }
        batch.set(unameRef, {
          'email': email,
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // persist local auth info
      final prefs = await SharedPreferences.getInstance();
      _isAuthenticated = true;
      _email = email;
      _role = role;
      await prefs.setBool(_keyIsAuthenticated, true);
      await prefs.setString(_keyEmail, _email);
      await prefs.setString(_keyRole, _role);

      notifyListeners();
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }
}
