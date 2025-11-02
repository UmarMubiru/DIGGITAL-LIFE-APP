import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserProvider extends ChangeNotifier {
  static const _keyUsername = 'user_username';
  static const _keyRole = 'auth_role';
  static const _keyPhotoPath = 'user_photo_path';
  static const _keyPhotoUrl = 'user_photo_url';
  static const _keyThemeSeed = 'user_theme_seed';
  static const _keyIsDark = 'user_is_dark_mode';
  static const _defaultUsername = 'Test User';

  String _username = _defaultUsername;
  String _role = 'student';
  String _photoPath = '';
  String _photoUrl = '';
  Color _themeSeed = Colors.blue;
  bool _isDark = false;
  bool _initialized = false;

  String get username => _username;
  String get role => _role;
  String get photoPath => _photoPath;
  Color get themeSeed => _themeSeed;
  bool get isDark => _isDark;
  bool get hasPhoto => _photoPath.isNotEmpty;
  bool get hasPhotoUrl => _photoUrl.isNotEmpty;
  String get photoUrl => _photoUrl;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString(_keyUsername) ?? _defaultUsername;
    _role = prefs.getString(_keyRole) ?? 'student';
    _photoPath = prefs.getString(_keyPhotoPath) ?? '';
    _photoUrl = prefs.getString(_keyPhotoUrl) ?? '';
    final storedSeed = prefs.getInt(_keyThemeSeed);
    if (storedSeed != null) {
      _themeSeed = Color(storedSeed);
    }
    _isDark = prefs.getBool(_keyIsDark) ?? false;
    _initialized = true;
    notifyListeners();

    // Try to hydrate from Firestore if logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final data = doc.data();
        if (data != null) {
          // Check for username in multiple possible locations
          String? cloudName;
          if (data.containsKey('username')) {
            cloudName = data['username'] as String?;
          } else if (data.containsKey('profile') && data['profile'] is Map) {
            final profile = data['profile'] as Map<String, dynamic>;
            cloudName = profile['username'] as String?;
            // Also try 'name' field if username not found
            if ((cloudName == null || cloudName.isEmpty) && profile.containsKey('name')) {
              cloudName = profile['name'] as String?;
            }
          }
          
          final cloudPhoto = data['photoUrl'] as String?;
          
          if (cloudName != null && cloudName.isNotEmpty && cloudName != _defaultUsername) {
            _username = cloudName;
            await prefs.setString(_keyUsername, _username);
          }
          if (cloudPhoto != null && cloudPhoto.isNotEmpty) {
            _photoUrl = cloudPhoto;
            await prefs.setString(_keyPhotoUrl, _photoUrl);
          }
          notifyListeners();
        }
      } catch (_) {}
    }
  }

  Future<String?> updateUsername(String name) async {
    final nameRegex = RegExp(r"^[A-Za-z][A-Za-z' -]{1,30}$");
    if (!nameRegex.hasMatch(name.trim())) {
      return 'Enter a valid name (2-31 letters)';
    }
    _username = name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, _username);
    notifyListeners();
    return null;
  }

  Future<void> updateRole(String role) async {
    _role = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, _role);
    notifyListeners();
  }

  Future<void> updateTheme(Color color) async {
    _themeSeed = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeSeed, color.toARGB32());
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    _isDark = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsDark, _isDark);
    notifyListeners();
  }

  Future<void> updatePhoto(File imageFile) async {
    // Compress
    final targetPath = imageFile.path.replaceAll('.jpg', '_compressed.jpg');
    try {
      await FlutterImageCompress.compressAndGetFile(imageFile.path, targetPath, quality: 60);
      _photoPath = targetPath;
    } catch (_) {
      _photoPath = imageFile.path; // fallback
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhotoPath, _photoPath);
    notifyListeners();

    // Upload to Firebase Storage and update Firestore
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null) {
      try {
        final storageRef = FirebaseStorage.instance.ref('users/${authUser.uid}/profile.jpg');
        await storageRef.putFile(File(_photoPath));
        final url = await storageRef.getDownloadURL();
        _photoUrl = url;
        await prefs.setString(_keyPhotoUrl, _photoUrl);
        await FirebaseFirestore.instance.collection('users').doc(authUser.uid).set(
          {
            'photoUrl': _photoUrl,
          },
          SetOptions(merge: true),
        );
        notifyListeners();
      } catch (_) {
        // ignore upload errors for now
      }
    }
  }

  String initials() {
    final trimmedName = _username.trim();
    // If username is empty or default, return placeholder
    if (trimmedName.isEmpty || trimmedName == _defaultUsername) {
      return '??';
    }
    
    // Split by whitespace to get name parts
    final parts = trimmedName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    
    if (parts.isEmpty) return '??';
    
    // Get first letter of first name
    final first = parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'U';
    
    // Get first letter of last name if available, otherwise second letter of first name
    String last;
    if (parts.length > 1 && parts[parts.length - 1].isNotEmpty) {
      last = parts[parts.length - 1][0].toUpperCase();
    } else if (parts[0].length > 1) {
      last = parts[0][1].toUpperCase();
    } else {
      last = first; // Single character name
    }
    
    return '$first$last';
  }
  
  /// Refresh user data from Firestore
  Future<void> refreshFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        // Check for username in multiple possible locations
        String? cloudName;
        if (data.containsKey('username')) {
          cloudName = data['username'] as String?;
        } else if (data.containsKey('profile') && data['profile'] is Map) {
          final profile = data['profile'] as Map<String, dynamic>;
          cloudName = profile['username'] as String?;
          // Also try 'name' field if username not found
          if ((cloudName == null || cloudName.isEmpty) && profile.containsKey('name')) {
            cloudName = profile['name'] as String?;
          }
        }
        
        // Get role from Firestore (check both top-level and profile)
        String? cloudRole;
        if (data.containsKey('role')) {
          cloudRole = data['role'] as String?;
        } else if (data.containsKey('profile') && data['profile'] is Map) {
          final profile = data['profile'] as Map<String, dynamic>;
          cloudRole = profile['role'] as String?;
        }
        
        final cloudPhoto = data['photoUrl'] as String?;
        
        final prefs = await SharedPreferences.getInstance();
        bool shouldNotify = false;
        
        if (cloudName != null && cloudName.isNotEmpty && cloudName != _defaultUsername) {
          _username = cloudName;
          await prefs.setString(_keyUsername, _username);
          shouldNotify = true;
        }
        
        // Update role from Firestore if available - normalize to lowercase
        if (cloudRole != null && cloudRole.isNotEmpty) {
          final normalizedRole = cloudRole.trim().toLowerCase();
          if (normalizedRole != _role) {
            _role = normalizedRole;
            await prefs.setString(_keyRole, _role);
            shouldNotify = true;
          }
        }
        
        if (cloudPhoto != null && cloudPhoto.isNotEmpty) {
          _photoUrl = cloudPhoto;
          await prefs.setString(_keyPhotoUrl, _photoUrl);
          shouldNotify = true;
        }
        
        if (shouldNotify) {
        notifyListeners();
        }
      }
    } catch (_) {}
  }

  Color hashColor() {
    final code = _username.hashCode;
    final r = (code & 0xFF0000) >> 16;
    final g = (code & 0x00FF00) >> 8;
    final b = (code & 0x0000FF);
    return Color.fromARGB(255, r, g, b);
  }
}


