import 'dart:async';
import 'package:digital_life_care_app/providers/locator_provider.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LocatorMapScreen extends StatefulWidget {
  const LocatorMapScreen({super.key});

  @override
  State<LocatorMapScreen> createState() => _LocatorMapScreenState();
}

class _LocatorMapScreenState extends State<LocatorMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  bool _showYouthFriendlyOnly = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocatorProvider>().initialize();
    });
  }

  Set<Marker> _buildMarkers(LocatorProvider provider) {
    final clinics = _showYouthFriendlyOnly
        ? provider.getYouthFriendlyClinics()
        : provider.clinics;

    final filtered = _searchQuery.isEmpty
        ? clinics
        : provider.searchClinics(_searchQuery);

    return filtered.map((clinic) {
      return Marker(
        markerId: MarkerId(clinic.id),
        position: clinic.position,
        infoWindow: InfoWindow(
          title: clinic.name,
          snippet: clinic.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          clinic.isYouthFriendly
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueRed,
        ),
        onTap: () {
          provider.selectClinic(clinic);
          _showClinicDetails(clinic);
        },
      );
    }).toSet();
  }

  void _showClinicDetails(Clinic clinic) {
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

    if (provider.isLoading || provider.userLocation == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Clinic Locator'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading nearby clinics...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
        appBar: AppBar(
            title: const Text('Clinic Locator'),
            actions: [
        Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: AppBrand.compact(logoSize:28),
        ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.person)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.add_shopping_cart)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.location_on)),
            ],
        ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: provider.userLocation!,
              zoom: 13,
            ),
            markers: _buildMarkers(provider),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),

          // Search bar at top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search clinics...',
                    border: InputBorder.none,
                    icon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
          ),

          // Filter toggle
          Positioned(
            top: 80,
            left: 16,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Youth-Friendly Only',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _showYouthFriendlyOnly,
                      onChanged: (value) {
                        setState(() {
                          _showYouthFriendlyOnly = value;
                        });
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Clinic list button
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'list_btn',
              onPressed: () {
                Navigator.pushNamed(context, '/locator/list');
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.list, color: Colors.white),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final controller = await _controller.future;
          if (provider.userLocation != null) {
            controller.animateCamera(
              CameraUpdate.newLatLngZoom(provider.userLocation!, 13),
            );
          }
        },
        icon: const Icon(Icons.my_location),
        label: const Text('My Location'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _ClinicDetailsSheet extends StatelessWidget {
  final Clinic clinic;

  const _ClinicDetailsSheet({required this.clinic});

  Future<void> _launchDirections() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${clinic.position.latitude},${clinic.position.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
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
          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: Colors.grey),
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
              const Icon(Icons.phone, size: 18, color: Colors.grey),
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
              const Icon(Icons.access_time, size: 18, color: Colors.grey),
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
              const Icon(Icons.star, size: 18, color: Colors.amber),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}