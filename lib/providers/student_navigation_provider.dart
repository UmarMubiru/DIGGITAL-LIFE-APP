import 'dart:async';
import 'package:flutter/foundation.dart';

/// Provider for student shell navigation - allows communication between TopActions and Shell
class StudentNavigationProvider extends ChangeNotifier {
  static StudentNavigationProvider? _instance;
  
  static StudentNavigationProvider get instance {
    _instance ??= StudentNavigationProvider._();
    return _instance!;
  }
  
  StudentNavigationProvider._();
  
  ValueChanged<int>? _onNavigateToIndex;
  Timer? _debounceTimer;
  int? _lastNavigatedIndex;
  DateTime? _lastNavigationTime;
  
  void setNavigationCallback(ValueChanged<int> callback) {
    _onNavigateToIndex = callback;
  }
  
  void navigateToIndex(int index) {
    // Check if callback is registered
    if (_onNavigateToIndex == null) {
      debugPrint('Navigation callback not registered yet. Call setNavigationCallback first.');
      return;
    }
    
    // Debounce rapid navigation calls to prevent stuck buttons
    final now = DateTime.now();
    if (_lastNavigatedIndex == index && 
        _lastNavigationTime != null &&
        now.difference(_lastNavigationTime!) < const Duration(milliseconds: 500)) {
      // Ignore duplicate rapid calls
      return;
    }
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      _lastNavigatedIndex = index;
      _lastNavigationTime = DateTime.now();
      try {
        if (_onNavigateToIndex != null) {
          _onNavigateToIndex!(index);
        }
      } catch (e) {
        debugPrint('Navigation callback error: $e');
      }
    });
  }
  
  void clear() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _onNavigateToIndex = null;
    _lastNavigatedIndex = null;
    _lastNavigationTime = null;
  }
  
  @override
  void dispose() {
    clear();
    super.dispose();
  }
}

