import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  static const _keyUsername = 'user_username';
  static const _keyRole = 'auth_role';
  static const _keyPhotoPath = 'user_photo_path';
  static const _keyThemeSeed = 'user_theme_seed';
  static const _keyIsDark = 'user_is_dark_mode';
  static const _defaultUsername = 'Test User';

  String _username = _defaultUsername;
  String _role = 'student';
  String _photoPath = '';
  Color _themeSeed = Colors.blue;
  bool _isDark = false;
  bool _initialized = false;

  String get username => _username;
  String get role => _role;
  String get photoPath => _photoPath;
  Color get themeSeed => _themeSeed;
  bool get isDark => _isDark;
  bool get hasPhoto => _photoPath.isNotEmpty;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString(_keyUsername) ?? _defaultUsername;
    _role = prefs.getString(_keyRole) ?? 'student';
    _photoPath = prefs.getString(_keyPhotoPath) ?? '';
    final storedSeed = prefs.getInt(_keyThemeSeed);
    if (storedSeed != null) {
      _themeSeed = Color(storedSeed);
    }
    _isDark = prefs.getBool(_keyIsDark) ?? false;
    _initialized = true;
    notifyListeners();
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
    // Mock: compress and "save" to temp, store path only
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
  }

  String initials() {
    if (_username.trim().isEmpty) return 'TU';
    final parts = _username.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first.characters.first.toUpperCase() : 'T';
    final last = parts.length > 1 ? parts.last.characters.first.toUpperCase() : 'U';
    return '$first$last';
  }

  Color hashColor() {
    final code = _username.hashCode;
    final r = (code & 0xFF0000) >> 16;
    final g = (code & 0x00FF00) >> 8;
    final b = (code & 0x0000FF);
    return Color.fromARGB(255, r, g, b);
  }
}


