import 'package:digital_life_care_app/providers/locator_provider.dart';
import 'package:digital_life_care_app/widgets/hw_top_actions.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HWLocatorScreen extends StatefulWidget {
  const HWLocatorScreen({super.key});

  @override
  State<HWLocatorScreen> createState() => _HWLocatorScreenState();
}

class _HWLocatorScreenState extends State<HWLocatorScreen> {
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
          if (provider.clinics.isEmpty && !provider.isLoading) {
            provider.initialize();
          }
        }
      });
      _initialized = true;
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

  void _showClinicDetails(BuildContext context, Clinic clinic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ClinicDetailsSheet(clinic: clinic),
    );
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
        title: const Text('Locator'),
        actions: const [HWTopActions()],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search clinics...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          onChanged: (value) {
                            if (mounted) {
                              setState(() => _searchQuery = value);
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
                                  'No clinics found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
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
                              // Calculate distance if user location is available
                              final distance = provider.userLocation != null
                                  ? provider.calculateDistance(
                                      provider.userLocation!,
                                      clinic.position,
                                    )
                                  : null;
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    // Directly open navigation when clicking on clinic card
                                    _openNavigationToClinic(clinic);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          child: Icon(
                                            Icons.local_hospital,
                                            color: Theme.of(context).colorScheme.primary,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                clinic.name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                clinic.address,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  if (distance != null) ...[
                                                    Icon(
                                                      Icons.near_me,
                                                      size: 14,
                                                      color: Colors.blue.shade600,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${distance.toStringAsFixed(1)} km',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.blue.shade600,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                  ],
                                                  Icon(
                                                    Icons.star,
                                                    size: 14,
                                                    color: Colors.amber,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${clinic.rating}/5',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade700,
                                                    ),
                                                  ),
                                                  if (clinic.isYouthFriendly) ...[
                                                    const SizedBox(width: 12),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green.shade100,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        'Youth-Friendly',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.green.shade700,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.grey.shade400,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

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
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
        );
      }).toList(),
    );
  }
}

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
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  clinic.address,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.phone, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                clinic.phone,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                clinic.openingHours,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.star, size: 18, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                '${clinic.rating}/5.0',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Services:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: clinic.services.map((service) {
              return Chip(
                label: Text(
                  service,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.blue.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              );
            }).toList(),
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
        ],
      ),
    );
  }
}

