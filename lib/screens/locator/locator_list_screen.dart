import 'package:digital_life_care_app/providers/locator_provider.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LocatorListScreen extends StatefulWidget {
  const LocatorListScreen({super.key});

  @override
  State<LocatorListScreen> createState() => _LocatorListScreenState();
}

class _LocatorListScreenState extends State<LocatorListScreen> {
  String _searchQuery = '';
  String _sortBy = 'distance'; // distance, rating, name

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
        title: const Text('Nearby Clinics'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: AppBrand.compact(logoSize: 28),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'distance',
                child: Row(
                  children: [
                    Icon(Icons.near_me, size: 18),
                    SizedBox(width: 8),
                    Text('Sort by Distance'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'rating',
                child: Row(
                  children: [
                    Icon(Icons.star, size: 18),
                    SizedBox(width: 8),
                    Text('Sort by Rating'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 18),
                    SizedBox(width: 8),
                    Text('Sort by Name'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search clinics...',
                prefixIcon: const Icon(Icons.search),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${clinics.length} ${clinics.length == 1 ? 'clinic' : 'clinics'} found',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                Text(
                  'Sorted by: ${_sortBy == 'distance' ? 'Distance' : _sortBy == 'rating' ? 'Rating' : 'Name'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Clinics list
          Expanded(
            child: clinics.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
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
              padding: const EdgeInsets.all(16),
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
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Icon(Icons.map),
        tooltip: 'View Map',
      ),
    );
  }
}

class _ClinicListCard extends StatelessWidget {
  final Clinic clinic;
  final double distance;

  const _ClinicListCard({
    required this.clinic,
    required this.distance,
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
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => _ClinicDetailsSheet(clinic: clinic),
          );
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/booking');
            },
            icon: const Icon(Icons.calendar_month),
            label: const Text('Book Appointment'),
          ),
        ],
      ),
    );
  }
}