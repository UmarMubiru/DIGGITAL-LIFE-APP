import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Clinic {
  final String id;
  final String name;
  final String address;
  final LatLng position;
  final String phone;
  final List<String> services;
  final bool isYouthFriendly;
  final double rating;
  final String openingHours;

  Clinic({
    required this.id,
    required this.name,
    required this.address,
    required this.position,
    required this.phone,
    required this.services,
    this.isYouthFriendly = false,
    this.rating = 0.0,
    required this.openingHours,
  });
}

class LocatorProvider extends ChangeNotifier {
  LatLng? _userLocation;
  List<Clinic> _clinics = [];
  Clinic? _selectedClinic;
  bool _isLoading = false;

  LatLng? get userLocation => _userLocation;
  List<Clinic> get clinics => _clinics;
  Clinic? get selectedClinic => _selectedClinic;
  bool get isLoading => _isLoading;

  // Mock clinics for Kampala area
  final List<Clinic> _mockClinics = [
    Clinic(
      id: '1',
      name: 'Makerere University Health Center',
      address: 'Makerere University Campus',
      position: const LatLng(0.3312, 32.5706),
      phone: '+256 414 542 803',
      services: ['STD Testing', 'HIV Testing', 'Counseling', 'Treatment'],
      isYouthFriendly: true,
      rating: 4.5,
      openingHours: 'Mon-Fri: 8am-5pm',
    ),
    Clinic(
      id: '2',
      name: 'Mulago Hospital Youth Clinic',
      address: 'Mulago Hill Road',
      position: const LatLng(0.3354, 32.5735),
      phone: '+256 414 554 600',
      services: ['STD Testing', 'Family Planning', 'HIV Testing'],
      isYouthFriendly: true,
      rating: 4.2,
      openingHours: 'Mon-Sat: 9am-6pm',
    ),
    Clinic(
      id: '3',
      name: 'Naguru Hospital',
      address: 'Naguru Rd',
      position: const LatLng(0.3341, 32.5985),
      phone: '+256 414 234 567',
      services: ['STD Testing', 'Treatment', 'Counseling'],
      isYouthFriendly: false,
      rating: 4.0,
      openingHours: 'Mon-Fri: 8am-4pm',
    ),
    Clinic(
      id: '4',
      name: 'Mengo Hospital Youth Services',
      address: 'Namirembe Rd',
      position: const LatLng(0.3015, 32.5580),
      phone: '+256 414 270 901',
      services: ['HIV Testing', 'STD Testing', 'Counseling', 'Treatment'],
      isYouthFriendly: true,
      rating: 4.7,
      openingHours: 'Mon-Sun: 24 hours',
    ),
    Clinic(
      id: '5',
      name: 'Kawempe Health Center',
      address: 'Kawempe Division',
      position: const LatLng(0.3723, 32.5592),
      phone: '+256 414 345 678',
      services: ['STD Testing', 'Family Planning'],
      isYouthFriendly: true,
      rating: 3.8,
      openingHours: 'Mon-Fri: 9am-5pm',
    ),
  ];

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    // Mock user location (Kampala city center)
    _userLocation = const LatLng(0.3476, 32.5825);
    _clinics = _mockClinics;

    _isLoading = false;
    notifyListeners();
  }

  void selectClinic(Clinic? clinic) {
    _selectedClinic = clinic;
    notifyListeners();
  }

  List<Clinic> getYouthFriendlyClinics() {
    return _clinics.where((c) => c.isYouthFriendly).toList();
  }

  List<Clinic> searchClinics(String query) {
    if (query.isEmpty) return _clinics;

    final lowerQuery = query.toLowerCase();
    return _clinics.where((clinic) {
      return clinic.name.toLowerCase().contains(lowerQuery) ||
          clinic.address.toLowerCase().contains(lowerQuery) ||
          clinic.services.any((s) => s.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  double calculateDistance(LatLng from, LatLng to) {
    // Simple distance calculation (not accurate for production)
    final lat = (from.latitude - to.latitude).abs();
    final lng = (from.longitude - to.longitude).abs();
    return (lat + lng) * 111; // Rough km conversion
  }

  void updateUserLocation(LatLng location) {
    _userLocation = location;
    notifyListeners();
  }
}