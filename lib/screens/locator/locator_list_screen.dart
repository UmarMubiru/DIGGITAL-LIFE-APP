import 'package:digital_life_care_app/providers/locator_provider.dart';
import 'package:digital_life_care_app/widgets/top_actions.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LocatorListScreen extends StatefulWidget {
  const LocatorListScreen({super.key});

  @override
  State<LocatorListScreen> createState() => _LocatorListScreenState();
}

class _LocatorListScreenState extends State<LocatorListScreen> {
  String _searchQuery = '';
  String _sortBy = 'distance'; // distance, rating, name
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize LocatorProvider if not already initialized (only once)
    if (!_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final provider = context.read<LocatorProvider>();
          // Always initialize if clinics list is empty
          if (provider.clinics.isEmpty) {
            provider.initialize();
          }
        }
      });
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocatorProvider>();
    List<Clinic> clinics = _searchQuery.isEmpty
        ? provider.clinics
        : provider.searchClinics(_searchQuery);

    // Sort clinics
    if (_sortBy == 'rating') {
      clinics.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortBy == 'name') {
      clinics.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'distance' && provider.userLocation != null) {
      clinics.sort((a, b) {
        final distA = provider.calculateDistance(
          provider.userLocation!,
          a.position,
        );
        final distB = provider.calculateDistance(
          provider.userLocation!,
          b.position,
        );
        return distA.compareTo(distB);
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: AppBrand.compact(logoSize: 28),
        ),
        title: const Text('Nearby Clinics'),
        actions: const [
          TopActions(),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Search bar and sort
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search clinics...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      if (mounted) {
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      }
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          onChanged: (value) {
                            if (mounted) {
                              setState(() {
                                _searchQuery = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Sort by: '),
                            ChoiceChips(
                              options: const ['distance', 'rating', 'name'],
                              selected: _sortBy,
                              onSelected: (value) {
                                if (mounted) {
                                  setState(() => _sortBy = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Clinics list
                  Expanded(
                    child: clinics.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              provider.userLocation == null
                                  ? 'Loading clinics...'
                                  : 'No clinics found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (provider.userLocation == null)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Please wait while we fetch nearby clinics',
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: clinics.length,
                            itemBuilder: (context, index) {
                              final clinic = clinics[index];
                              final distance = provider.userLocation != null
                                  ? provider.calculateDistance(
                                      provider.userLocation!,
                                      clinic.position,
                                    )
                                  : 0.0;
                              return _ClinicListCard(
                                clinic: clinic,
                                distance: distance,
                                onNavigate: () => _openNavigationToClinic(clinic),
                              );
                            },
                          ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        tooltip: 'View Map',
        child: const Icon(Icons.map),
      ),
    );
  }
}

// ChoiceChips widget for sort options (matching health worker side)
class ChoiceChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final Function(String) onSelected;

  const ChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: options.map((option) {
        final isSelected = option == selected;
        return ChoiceChip(
          label: Text(
            option == 'distance'
                ? 'Distance'
                : option == 'rating'
                    ? 'Rating'
                    : 'Name',
          ),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          selectedColor: Theme.of(context).colorScheme.primary,
          backgroundColor: Colors.grey.shade200,
        );
      }).toList(),
    );
  }
}

// Helper function to open navigation to clinic
Future<void> _openNavigationToClinic(Clinic clinic) async {
  // Use Google Maps navigation URL - works on mobile and web
  final url = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=${clinic.position.latitude},${clinic.position.longitude}&travelmode=driving',
  );
  try {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Fallback for mobile devices - try maps:// scheme
      final mapsUrl = Uri.parse(
        'maps://maps.google.com/?daddr=${clinic.position.latitude},${clinic.position.longitude}',
      );
      try {
        if (await canLaunchUrl(mapsUrl)) {
          await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        // If maps:// fails, try comgooglemaps:// for iOS
        final iosMapsUrl = Uri.parse(
          'comgooglemaps://?daddr=${clinic.position.latitude},${clinic.position.longitude}&directionsmode=driving',
        );
        try {
          if (await canLaunchUrl(iosMapsUrl)) {
            await launchUrl(iosMapsUrl, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          debugPrint('Error launching navigation: $e');
        }
      }
    }
  } catch (e) {
    debugPrint('Error launching navigation: $e');
  }
}

class _ClinicListCard extends StatelessWidget {
  final Clinic clinic;
  final double distance;
  final VoidCallback onNavigate;

  const _ClinicListCard({
    required this.clinic,
    required this.distance,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Directly open navigation when clicking on clinic card
          onNavigate();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      clinic.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (clinic.isYouthFriendly)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Youth-Friendly',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      clinic.address,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    clinic.openingHours,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        clinic.rating.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Icon(Icons.near_me, size: 16, color: Colors.blue.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${distance.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Navigation button - primary action
                  ElevatedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.directions, size: 16),
                    label: Text('${distance.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/booking');
                    },
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: const Text('Book', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reuse the same _ClinicDetailsSheet from locator_map_screen.dart
class _ClinicDetailsSheet extends StatelessWidget {
  final Clinic clinic;

  const _ClinicDetailsSheet({required this.clinic});

  Future<void> _launchDirections() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${clinic.position.latitude},${clinic.position.longitude}&travelmode=driving',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: Try maps:// scheme for native apps
        final mapsUrl = Uri.parse(
          'maps://maps.google.com/?daddr=${clinic.position.latitude},${clinic.position.longitude}',
        );
        if (await canLaunchUrl(mapsUrl)) {
          await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('Error launching directions: $e');
    }
  }

  Future<void> _launchPhone() async {
    final url = Uri.parse('tel:${clinic.phone}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Same implementation as in locator_map_screen.dart
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  clinic.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (clinic.isYouthFriendly)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Youth-Friendly',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _launchDirections,
                  icon: const Icon(Icons.directions),
                  label: const Text('Get Directions'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _launchPhone,
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/booking');
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text('Book Appointment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}