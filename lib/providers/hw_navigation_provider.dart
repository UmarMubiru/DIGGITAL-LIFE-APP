import 'dart:async';
import 'package:flutter/foundation.dart';

/// Provider for health worker shell navigation - allows communication between TopActions and Shell
class HWNavigationProvider extends ChangeNotifier {
  static HWNavigationProvider? _instance;
  
  static HWNavigationProvider get instance {
    _instance ??= HWNavigationProvider._();
    return _instance!;
  }
  
  HWNavigationProvider._();
  
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
      // Ignore duplicate rapid calls - increased to 500ms for better UX
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

