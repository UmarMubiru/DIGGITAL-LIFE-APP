// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digital_life_care_app/widgets/top_actions.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:digital_life_care_app/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digital_life_care_app/providers/stock_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> with SingleTickerProviderStateMixin {
  String? _selectedCategoryId;
  final Map<String, int> _cart = {}; // medicineId -> qty
  LatLng? _deliveryPoint;
  Position? _studentPosition;
  String _paymentMethod = 'cod';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Category name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (res == true && controller.text.trim().isNotEmpty) {
      if (!mounted) return;
      await context.read<StockProvider>().addCategory(controller.text.trim());
    }
  }

  Future<void> _showAddEditMedicine({Medicine? existing, required String categoryId}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final form = TextEditingController(text: existing?.form ?? 'Tablet');
    final unit = TextEditingController(text: existing?.unit ?? 'pieces');
    final quantity = TextEditingController(text: existing != null ? existing.quantity.toString() : '0');
    final price = TextEditingController(text: existing != null ? existing.pricePerUnit.toString() : '0');
    bool isFree = existing?.isFree ?? false;
    final low = TextEditingController(text: existing != null ? existing.lowStockThreshold.toString() : '5');

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setStateDialog) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Medicine' : 'Edit Medicine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: form, decoration: const InputDecoration(labelText: 'Form')),
                TextField(controller: unit, decoration: const InputDecoration(labelText: 'Unit')),
                TextField(controller: quantity, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
                TextField(controller: price, decoration: const InputDecoration(labelText: 'Price per unit (UGX)'), keyboardType: TextInputType.number),
                TextField(controller: low, decoration: const InputDecoration(labelText: 'Low stock threshold'), keyboardType: TextInputType.number),
                Row(children: [
                  Checkbox(value: isFree, onChanged: (v) => setStateDialog(() => isFree = v ?? false)),
                  const SizedBox(width: 8),
                  const Text('Free item')
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        );
      }),
    );

    if (res == true) {
      final qty = num.tryParse(quantity.text) ?? 0;
      final p = num.tryParse(price.text) ?? 0;
      final lowT = num.tryParse(low.text) ?? 0;
      final med = Medicine(
        id: existing?.id ?? '',
        categoryId: categoryId,
        name: name.text.trim(),
        form: form.text.trim(),
        unit: unit.text.trim(),
        quantity: qty,
        pricePerUnit: p,
        isFree: isFree,
        lowStockThreshold: lowT,
      );

      if (!mounted) return;
      if (existing == null) {
        await context.read<StockProvider>().addMedicine(med);
      } else {
        await context.read<StockProvider>().updateMedicine(existing.id, {
          'name': med.name,
          'form': med.form,
          'unit': med.unit,
          'quantity': med.quantity,
          'pricePerUnit': med.pricePerUnit,
          'isFree': med.isFree,
          'lowStockThreshold': med.lowStockThreshold,
        });
      }
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled. Please enable them in settings.')),
          );
        }
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission is required to set delivery location.')),
            );
          }
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is permanently denied. Please enable it in app settings.')),
          );
        }
        return null;
      }
      
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      setState(() {
        _studentPosition = pos;
      });
      return pos;
    } catch (e) {
      debugPrint('Error getting current position: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
      return null;
    }
  }

  double _distanceKm(LatLng a, LatLng b) {
    const R = 6371.0; // Earth radius km
    final lat1 = a.latitude * math.pi / 180.0;
    final lat2 = b.latitude * math.pi / 180.0;
    final dLat = lat2 - lat1;
    final dLon = (b.longitude - a.longitude) * math.pi / 180.0;
    final hav = math.pow(math.sin(dLat / 2), 2) + math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
    final c = 2 * math.asin(math.sqrt(hav));
    return R * c;
  }

  Future<LatLng?> _pickDeliveryPoint(BuildContext ctx) async {
    // Ensure we have a starting position - try to get current location first
    LatLng initial = const LatLng(0.3476, 32.5825); // Kampala fallback
    
    // Try to get current position if not already set
    if (_studentPosition == null) {
      final p = await _getCurrentPosition();
      if (p != null) {
        initial = LatLng(p.latitude, p.longitude);
      }
    } else {
      initial = LatLng(_studentPosition!.latitude, _studentPosition!.longitude);
    }

    LatLng? picked = _deliveryPoint;

    if (!mounted) return null;
    
    final result = await showDialog<LatLng?>(
      context: ctx,
      builder: (dCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.location_on),
                  SizedBox(width: 8),
                  Text('Pick Delivery Location'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: initial,
                        zoom: 14,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                      mapToolbarEnabled: false,
                      onTap: (latlng) {
                        picked = latlng;
                        setDialogState(() {});
                      },
                      markers: picked == null
                          ? {}
                          : {
                              Marker(
                                markerId: const MarkerId('delivery_point'),
                                position: picked!,
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                                infoWindow: const InfoWindow(
                                  title: 'Delivery Location',
                                  snippet: 'Tap to change location',
                                ),
                              ),
                            },
                    ),
                    if (picked != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Card(
                          color: Colors.white,
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selected Location:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lat: ${picked!.latitude.toStringAsFixed(6)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  'Lng: ${picked!.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (_studentPosition != null && picked != null) ...[
                                  const SizedBox(height: 8),
                                  Builder(
                                    builder: (context) {
                                      final studentPos = _studentPosition!;
                                      final deliveryPos = picked!;
                                      final distance = _distanceKm(
                                        LatLng(studentPos.latitude, studentPos.longitude),
                                        deliveryPos,
                                      );
                                      return Text(
                                        'Distance: ${distance.toStringAsFixed(2)} km',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dCtx, null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Ensure we have a picked location
                    if (picked == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please tap on the map to select a delivery location.')),
                        );
                      }
                      return;
                    }
                    
                    // Try to get current location if not set (needed for distance calculation)
                    if (_studentPosition == null) {
                      final pos = await _getCurrentPosition();
                      if (pos == null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not get your current location. Distance calculation may not work.')),
                          );
                        }
                      }
                    }
                    Navigator.pop(dCtx, picked);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Use Selected'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _deliveryPoint = result;
      });
      return result;
    }
    return null;
  }

  Future<Medicine?> _fetchMedicineById(String id) async {
    final doc = await FirebaseFirestore.instance.collection('medicines').doc(id).get();
    if (!doc.exists) return null;
    return Medicine.fromFirestore(doc);
  }

  Future<void> _openCartDialog(BuildContext ctx, UserProvider user) async {
    // Check if cart is empty
    if (_cart.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty. Add medicines to continue.')),
      );
      return;
    }

    // Gather medicine details
    final meds = <Medicine>[];
    final failedIds = <String>[];
    
    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (loadingCtx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      for (final id in _cart.keys) {
        final m = await _fetchMedicineById(id);
        if (m != null) {
          meds.add(m);
        } else {
          failedIds.add(id);
        }
      }
    } finally {
      if (mounted) Navigator.pop(ctx);
    }

    // Remove failed items from cart
    if (failedIds.isNotEmpty) {
      for (final id in failedIds) {
        _cart.remove(id);
      }
      setState(() {});
    }

    // Check if we have any valid medicines
    if (meds.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid medicines in cart. Please add items again.')),
      );
      return;
    }

    if (!mounted) return;
    
    // Store current values to ensure they're captured correctly
    
    await showDialog(
      context: ctx,
      builder: (dCtx) {
        double subtotal = 0;
        for (final m in meds) {
          final qty = _cart[m.id] ?? 0;
          final price = m.isFree ? 0 : m.pricePerUnit;
          subtotal += (price * qty);
        }

        // Ensure we have student position for distance calculation
        double distanceKm = 0;
        int deliveryCharge = 0;
        if (_deliveryPoint != null) {
          // Get current position if not already set
          if (_studentPosition == null) {
            _getCurrentPosition().then((pos) {
              if (pos != null && _deliveryPoint != null && mounted) {
                setState(() {
                  distanceKm = _distanceKm(LatLng(pos.latitude, pos.longitude), _deliveryPoint!);
                  deliveryCharge = (distanceKm * 1000).round();
                });
              }
            });
          } else {
            distanceKm = _distanceKm(LatLng(_studentPosition!.latitude, _studentPosition!.longitude), _deliveryPoint!);
            deliveryCharge = (distanceKm * 1000).round();
          }
        }

        // ignore: unused_local_variable
        final total = subtotal + deliveryCharge;

        return StatefulBuilder(builder: (dCtx2, setStateDialog) {
          // Recalculate when dialog state changes
          double currentSubtotal = 0;
          for (final m in meds) {
            final qty = _cart[m.id] ?? 0;
            final price = m.isFree ? 0 : m.pricePerUnit;
            currentSubtotal += (price * qty);
          }
          
          // Always recalculate distance from current state values
          // Read fresh values from parent state each time builder runs
          final deliveryPoint = _deliveryPoint;
          final studentPosition = _studentPosition;
          
          double currentDistanceKm = 0;
          int currentDeliveryCharge = 0;
          
          // Debug: Check if positions are set
          debugPrint('Cart Dialog - studentPosition: $studentPosition, deliveryPoint: $deliveryPoint');
          
          if (deliveryPoint != null && studentPosition != null) {
            try {
              currentDistanceKm = _distanceKm(
                LatLng(studentPosition.latitude, studentPosition.longitude), 
                deliveryPoint
              );
              currentDeliveryCharge = (currentDistanceKm * 1000).round(); // Transport: 1000 UGX per km
              debugPrint('Distance calculated: $currentDistanceKm km, Charge: $currentDeliveryCharge UGX');
            } catch (e) {
              debugPrint('Error calculating distance: $e');
            }
          } else {
            debugPrint('Missing positions - student: ${studentPosition != null}, delivery: ${deliveryPoint != null}');
          }
          
          final currentTotal = currentSubtotal + currentDeliveryCharge;

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.shopping_cart),
                const SizedBox(width: 8),
                const Text('Your Cart'),
                const Spacer(),
                Chip(label: Text('${_cart.values.fold<int>(0, (a, b) => a + b)} items')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (meds.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text('Cart is empty')),
                    )
                  else
                    ...meds.map((m) {
                      final qty = _cart[m.id] ?? 0;
                      if (qty <= 0) return const SizedBox.shrink();
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('${m.form} • ${m.unit}'),
                                    Text(m.isFree ? 'Free' : '${m.pricePerUnit} UGX per unit', 
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: qty <= 1
                                        ? null
                                        : () {
                                            setStateDialog(() {
                                              _cart[m.id] = qty - 1;
                                              if (_cart[m.id]! <= 0) _cart.remove(m.id);
                                            });
                                            setState(() {});
                                          },
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      setStateDialog(() {
                                        _cart[m.id] = qty + 1;
                                      });
                                      setState(() {});
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${m.isFree ? 0 : (m.pricePerUnit * qty).toStringAsFixed(0)} UGX', 
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () {
                                      setStateDialog(() {
                                        _cart.remove(m.id);
                                      });
                                      setState(() {});
                                      if (_cart.isEmpty) Navigator.pop(dCtx);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Delivery Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          // Show loading
                          showDialog(
                            context: dCtx,
                            barrierDismissible: false,
                            builder: (loadingCtx) => const Center(child: CircularProgressIndicator()),
                          );
                          
                          final pos = await _getCurrentPosition();
                          
                          if (!mounted) return;
                          Navigator.pop(dCtx); // Close loading
                          
                          if (pos == null) {
                            messenger.showSnackBar(const SnackBar(
                              content: Text('Could not get your location. Please try picking a point on the map.'),
                            ));
                            return;
                          }
                          
                          // Use current location as delivery point
                          final deliveryLatLng = LatLng(pos.latitude, pos.longitude);
                          
                          debugPrint('Setting positions - Student: ${pos.latitude}, ${pos.longitude}, Delivery: ${deliveryLatLng.latitude}, ${deliveryLatLng.longitude}');
                          
                          // Close dialog first
                          Navigator.pop(dCtx);
                          
                          // Update state
                          setState(() {
                            _studentPosition = pos; // Set student position
                            _deliveryPoint = deliveryLatLng; // Set delivery point
                          });
                          
                          // Reopen dialog with updated values
                          if (mounted) {
                            await _openCartDialog(context, user);
                            
                            messenger.showSnackBar(SnackBar(
                              content: Text('Current location set as delivery point. Distance: 0 km (same location)'),
                              duration: const Duration(seconds: 2),
                            ));
                          }
                        }, 
                        icon: const Icon(Icons.my_location), 
                        label: const Text('Use current location'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Close the cart dialog temporarily to pick location
                          Navigator.pop(dCtx);
                          
                          final picked = await _pickDeliveryPoint(context);
                          
                          if (picked != null) {
                            // Ensure we have student position for distance calculation first
                            if (_studentPosition == null) {
                              final pos = await _getCurrentPosition();
                              if (pos != null) {
                                setState(() {
                                  _studentPosition = pos;
                                  _deliveryPoint = picked;
                                });
                              } else {
                                // Still set delivery point even if we can't get current position
                                setState(() {
                                  _deliveryPoint = picked;
                                });
                              }
                            } else {
                              // Set the delivery point
                              setState(() {
                                _deliveryPoint = picked;
                              });
                            }
                            
                            // Reopen cart dialog with updated values
                            if (mounted) {
                              await _openCartDialog(context, user);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _studentPosition != null 
                                      ? 'Delivery location set. Distance: ${_distanceKm(LatLng(_studentPosition!.latitude, _studentPosition!.longitude), picked).toStringAsFixed(2)} km'
                                      : 'Delivery location set. Enable location to see distance.',
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          } else {
                            // User cancelled, reopen cart dialog
                            if (mounted) {
                              await _openCartDialog(context, user);
                            }
                          }
                        }, 
                        icon: const Icon(Icons.map), 
                        label: const Text('Pick on map'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  if (deliveryPoint != null) ...[
                    if (studentPosition != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  'Distance: ${currentDistanceKm.toStringAsFixed(2)} km',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Transport: $currentDeliveryCharge UGX (${currentDistanceKm.toStringAsFixed(2)} km × 1000 UGX/km)',
                              style: TextStyle(color: Colors.grey[700], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Delivery point set. Enable location services to calculate distance and transport cost.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(child: Text('Please set delivery location to calculate delivery charge')),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Radio<String>(value: 'mobile_money', groupValue: _paymentMethod, onChanged: (v) => setStateDialog(() => _paymentMethod = v!)),
                    const Text('Mobile Money'),
                    const SizedBox(width: 12),
                    Radio<String>(value: 'cod', groupValue: _paymentMethod, onChanged: (v) => setStateDialog(() => _paymentMethod = v!)),
                    const Text('Cash on Delivery'),
                  ]),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Subtotal:', style: TextStyle(fontSize: 14)),
                          Text('${currentSubtotal.toStringAsFixed(0)} UGX', style: const TextStyle(fontSize: 14)),
                        ]),
                        const SizedBox(height: 4),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Transport${currentDistanceKm > 0 ? ' (${currentDistanceKm.toStringAsFixed(2)} km @ 1000 UGX/km)' : ''}:', style: const TextStyle(fontSize: 14)),
                          Text('$currentDeliveryCharge UGX', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ]),
                        const Divider(),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text('${currentTotal.toStringAsFixed(0)} UGX', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Close')),
              FilledButton(
                onPressed: _cart.isEmpty ? null : () async {
                  // Validate
                  final messenger = ScaffoldMessenger.of(context);
                  final stock = context.read<StockProvider>();
                  if (_deliveryPoint == null) {
                    if (!mounted) return;
                    messenger.showSnackBar(const SnackBar(content: Text('Please set delivery point')));
                    return;
                  }
                  if (_studentPosition == null) {
                    final pos = await _getCurrentPosition();
                    if (pos == null) {
                      if (!mounted) return;
                      messenger.showSnackBar(const SnackBar(content: Text('Location permission required')));
                      return;
                    }
                  }

                  // Recompute figures
                  double recomputeSubtotal = 0;
                  final items = <Map<String, dynamic>>[];
                  for (final m in meds) {
                    final qty = _cart[m.id] ?? 0;
                    if (qty <= 0) continue;
                    final price = m.isFree ? 0 : m.pricePerUnit;
                    recomputeSubtotal += (price * qty);
                    items.add({
                      'medicineId': m.id, 
                      'name': m.name, 
                      'qty': qty, 
                      'pricePerUnit': price, 
                      'isFree': m.isFree
                    });
                  }
                  
                  if (items.isEmpty) {
                    if (!mounted) return;
                    messenger.showSnackBar(const SnackBar(content: Text('Cart is empty')));
                    return;
                  }
                  
                  // Calculate distance and delivery charge (1000 UGX per km)
                  final distKm = _distanceKm(LatLng(_studentPosition!.latitude, _studentPosition!.longitude), _deliveryPoint!);
                  final dCharge = (distKm * 1000).round(); // Transport cost: 1000 UGX per km
                  final totalAmount = recomputeSubtotal + dCharge;

                  final orderData = {
                    'studentId': FirebaseAuth.instance.currentUser?.uid ?? user.username,
                    'items': items,
                    'distanceKm': distKm,
                    'deliveryCharge': dCharge,
                    'subtotal': recomputeSubtotal,
                    'total': totalAmount,
                    'paymentMethod': _paymentMethod,
                    // store delivery point for map display
                    'deliveryPoint': GeoPoint(_deliveryPoint!.latitude, _deliveryPoint!.longitude),
                  };

                  try {
                    if (_paymentMethod == 'mobile_money') {
                      final pay = await showDialog<bool>(context: dCtx, builder: (pCtx) => AlertDialog(
                        title: const Text('Mobile Money Payment'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Payment Placeholder'),
                            const SizedBox(height: 8),
                            Text('Amount: ${totalAmount.toStringAsFixed(0)} UGX', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 8),
                            const Text('This is a payment placeholder. In production, this would integrate with a mobile money provider.'),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(pCtx, false), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.pop(pCtx, true), child: const Text('Confirm Payment')),
                        ],
                      ));
                      if (pay != true) {
                        if (!mounted) return;
                        messenger.showSnackBar(const SnackBar(content: Text('Payment cancelled')));
                        return;
                      }
                      // mark as paid
                      orderData['paymentStatus'] = 'paid';
                    } else {
                      // For cash on delivery, mark payment as pending
                      orderData['paymentStatus'] = 'pending';
                    }

                  // Show loading
                  showDialog(
                    context: dCtx,
                    barrierDismissible: false,
                    builder: (loadingCtx) => const Center(child: CircularProgressIndicator()),
                  );

                  await stock.placeOrder(orderData);
                  
                  if (!mounted) return;
                  Navigator.pop(dCtx); // Close loading
                  Navigator.pop(dCtx); // Close cart dialog
                  
                  messenger.showSnackBar(const SnackBar(
                    content: Text('Order placed successfully! Check "My Orders" tab.'),
                    duration: Duration(seconds: 3),
                  ));
                  
                  setState(() {
                    _cart.clear();
                    _deliveryPoint = null;
                  });
                  
                  // Switch to "My Orders" tab to show the new order
                  _tabController.animateTo(1);
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(content: Text('Place order failed: $e')));
                }
              }, 
              child: const Text('Confirm Order')),
            ],
          );
        });
      },
    );
  }

  Widget _buildStudentOrdersList(UserProvider user) {
    final studentId = FirebaseAuth.instance.currentUser?.uid ?? user.username;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('studentId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No orders yet. Start shopping to place your first order!'),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            final items = (data['items'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
            final subtotal = (data['subtotal'] ?? 0).toDouble();
            final deliveryCharge = (data['deliveryCharge'] ?? 0).toInt();
            final total = (data['total'] ?? 0).toDouble();
            final distanceKm = (data['distanceKm'] ?? 0).toDouble();
            final paymentMethod = data['paymentMethod'] ?? 'cod';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final dateStr = createdAt != null ? '${createdAt.day}/${createdAt.month}/${createdAt.year}' : 'N/A';

            Color statusColor;
            IconData statusIcon;
            String statusText;
            switch (status) {
              case 'pending':
                statusColor = Colors.orange;
                statusIcon = Icons.pending;
                statusText = 'Pending';
                break;
              case 'accepted':
                statusColor = Colors.blue;
                statusIcon = Icons.check_circle_outline;
                statusText = 'Accepted';
                break;
              case 'dispatched':
                statusColor = Colors.green;
                statusIcon = Icons.local_shipping;
                statusText = 'Dispatched';
                break;
              case 'declined':
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
                statusText = 'Declined';
                break;
              default:
                statusColor = Colors.grey;
                statusIcon = Icons.help_outline;
                statusText = status;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: Icon(statusIcon, color: statusColor),
                title: Text('Order #${doc.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Status: $statusText • $dateStr'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${item['name'] ?? ''} x ${item['qty'] ?? 0}'),
                                  Text(item['isFree'] == true
                                      ? 'Free'
                                      : '${(((item['pricePerUnit'] ?? 0) * (item['qty'] ?? 0))).toStringAsFixed(0)} UGX'),
                                ],
                              ),
                            )),
                        const Divider(),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Subtotal:'),
                          Text('${subtotal.toStringAsFixed(0)} UGX'),
                        ]),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Transport (${distanceKm.toStringAsFixed(2)} km @ 1000 UGX/km):'),
                          Text('$deliveryCharge UGX', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                        const Divider(),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${total.toStringAsFixed(0)} UGX', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Text('Payment: '),
                          Text(paymentMethod == 'mobile_money' ? 'Mobile Money' : 'Cash on Delivery', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                                if (data['deliveryPoint'] != null) TextButton.icon(
                              onPressed: () {
                                    final dp = data['deliveryPoint'];
                                    LatLng? point;
                                    if (dp is GeoPoint) point = LatLng(dp.latitude, dp.longitude);
                                    else if (dp is Map && dp['latitude'] != null && dp['longitude'] != null) point = LatLng(dp['latitude'], dp['longitude']);
                                    if (point == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No delivery point stored for this order')));
                                      return;
                                    }

                                    final nonNullPoint = point;
                                    showDialog(
                                      context: context,
                                      builder: (mCtx) => AlertDialog(
                                        title: const Text('Delivery Location'),
                                        content: SizedBox(
                                          width: double.maxFinite,
                                          height: 300,
                                          child: GoogleMap(
                                            initialCameraPosition: CameraPosition(target: nonNullPoint, zoom: 15),
                                            markers: {
                                              Marker(markerId: const MarkerId('order_dest'), position: nonNullPoint),
                                            },
                                          ),
                                        ),
                                        actions: [TextButton(onPressed: () => Navigator.pop(mCtx), child: const Text('Close'))],
                                      ),
                                    );
                              },
                              icon: const Icon(Icons.map),
                              label: const Text('Show on map'),
                            ),
                            const SizedBox(width: 8),
                            if (status == 'pending') TextButton.icon(
                              onPressed: () async {
                                final studentIdLocal = studentId;
                                final messenger = ScaffoldMessenger.of(context);
                                final stock = context.read<StockProvider>();
                                try {
                                  await stock.cancelOrder(doc.id, studentIdLocal);
                                  if (!mounted) return;
                                  messenger.showSnackBar(const SnackBar(content: Text('Order cancelled')));
                                } catch (e) {
                                  if (!mounted) return;
                                  messenger.showSnackBar(SnackBar(content: Text('Cancel failed: $e')));
                                }
                              },
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              label: const Text('Cancel order'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final isHW = user.role == 'health_worker' || user.role == 'worker';
    if (!isHW) {
      // Student UI: browse categories & medicines, add to cart, pick delivery point,
      // compute distance and place order.
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey.shade100,
          leadingWidth: 56,
          leading: const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: AppBrand.compact(logoSize: 28),
          ),
          title: const Text('Delivery'),
          actions: const [TopActions()],
        ),
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.shopping_bag), text: 'Shop'),
                Tab(icon: Icon(Icons.receipt_long), text: 'My Orders'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Row(
                      children: [
                        SizedBox(
                          width: 220,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: const [
                                    Expanded(child: Text('Categories', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: StreamBuilder<List<StockCategory>>(
                                  stream: context.read<StockProvider>().streamCategories(),
                                  builder: (c, snap) {
                                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                                    final cats = snap.data!;
                                    if (cats.isEmpty) return const Center(child: Text('No categories.'));
                                    return ListView.builder(
                                      itemCount: cats.length,
                                      itemBuilder: (ctx, i) {
                                        final cat = cats[i];
                                        return ListTile(
                                          title: Text(cat.name),
                                          selected: _selectedCategoryId == cat.id,
                                          onTap: () => setState(() => _selectedCategoryId = cat.id),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedCategoryId == null ? 'Select a category' : 'Medicines', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: _selectedCategoryId == null
                                      ? const Center(child: Text('Choose a category to view medicines.'))
                                      : StreamBuilder<List<Medicine>>(
                                          stream: context.read<StockProvider>().streamMedicines(_selectedCategoryId!),
                                          builder: (c, msnap) {
                                            if (!msnap.hasData) return const Center(child: CircularProgressIndicator());
                                            final meds = msnap.data!;
                                            if (meds.isEmpty) return const Center(child: Text('No medicines in this category.'));
                                            return ListView.builder(
                                              itemCount: meds.length,
                                              itemBuilder: (c2, idx) {
                                                final m = meds[idx];
                                                return Card(
                                                  child: ListTile(
                                                    title: Text(m.name),
                                                    subtitle: Text('${m.quantity} ${m.unit} • ${m.form} • ${m.isFree ? 'Free' : '${m.pricePerUnit} UGX'}'),
                                                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.add_shopping_cart),
                                                        onPressed: m.quantity <= 0 ? null : () {
                                                          setState(() {
                                                            _cart[m.id] = (_cart[m.id] ?? 0) + 1;
                                                          });
                                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                                                        },
                                                      ),
                                                    ]),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  _buildStudentOrdersList(user),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _cart.isEmpty ? null : () => _openCartDialog(context, user),
          label: Row(children: [const Icon(Icons.shopping_cart), const SizedBox(width: 8), Text('${_cart.values.fold<int>(0,(a,b)=>a+b)}')]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: AppBrand.compact(logoSize: 28),
        ),
        title: const Text('Delivery - Stock Management'),
        actions: const [TopActions()],
      ),
      body: Row(
        children: [
          // Categories
          SizedBox(
            width: 220,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Categories', style: TextStyle(fontWeight: FontWeight.bold))),
                      IconButton(onPressed: _showAddCategoryDialog, icon: const Icon(Icons.add)),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<StockCategory>>(
                    stream: context.read<StockProvider>().streamCategories(),
                    builder: (c, snap) {
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                      final cats = snap.data!;
                      if (cats.isEmpty) return const Center(child: Text('No categories. Add one.'));
                      return ListView.builder(
                        itemCount: cats.length,
                        itemBuilder: (ctx, i) {
                          final cat = cats[i];
                          return ListTile(
                            title: Text(cat.name),
                            selected: _selectedCategoryId == cat.id,
                            onTap: () => setState(() => _selectedCategoryId = cat.id),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Divider
          const VerticalDivider(width: 1),

          // Medicines + Orders
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(_selectedCategoryId == null ? 'Select a category' : 'Medicines', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      if (_selectedCategoryId != null)
                        FilledButton.icon(onPressed: () => _showAddEditMedicine(categoryId: _selectedCategoryId!), icon: const Icon(Icons.add), label: const Text('Add Medicine')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _selectedCategoryId == null
                        ? const Center(child: Text('Choose a category to view medicines and pending orders.'))
                        : Column(
                            children: [
                              Expanded(
                                child: StreamBuilder<List<Medicine>>( 
                                  stream: context.read<StockProvider>().streamMedicines(_selectedCategoryId!),
                                  builder: (c, msnap) {
                                    if (!msnap.hasData) return const Center(child: CircularProgressIndicator());
                                    final meds = msnap.data!;
                                    if (meds.isEmpty) return const Center(child: Text('No medicines in this category.'));
                                    return ListView.builder(
                                      itemCount: meds.length,
                                      itemBuilder: (c2, idx) {
                                        final m = meds[idx];
                                        final outOfStock = m.quantity <= 0;
                                        final lowStock = m.quantity <= m.lowStockThreshold;
                                        return Card(
                                          child: ListTile(
                                            title: Text(m.name),
                                            subtitle: Text('${m.quantity} ${m.unit} • ${m.form} • ${m.isFree ? 'Free' : '${m.pricePerUnit} UGX'}'),
                                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                              if (lowStock) const Padding(padding: EdgeInsets.only(right:8.0), child: Chip(label: Text('Low'))),
                                              if (outOfStock) const Padding(padding: EdgeInsets.only(right:8.0), child: Chip(label: Text('Out of stock'))),
                                              IconButton(icon: const Icon(Icons.edit), onPressed: () => _showAddEditMedicine(existing: m, categoryId: m.categoryId)),
                                              IconButton(icon: const Icon(Icons.delete), onPressed: () => context.read<StockProvider>().deleteMedicine(m.id)),
                                            ]),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('Pending Orders', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  StreamBuilder<List<StockOrder>>(
                                    stream: context.read<StockProvider>().streamOrdersByStatuses(['pending']),
                                    builder: (countCtx, countSnap) {
                                      final pendingCount = countSnap.data?.length ?? 0;
                                      if (pendingCount > 0) {
                                        return Chip(
                                          label: Text('$pendingCount pending'),
                                          backgroundColor: Colors.orange.shade100,
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: StreamBuilder<List<StockOrder>>(
                                  // Show both pending and accepted orders so HW can Accept or Dispatch
                                  stream: context.read<StockProvider>().streamOrdersByStatuses(['pending', 'accepted']),
                                  builder: (c, osnap) {
                                    if (!osnap.hasData) return const Center(child: CircularProgressIndicator());
                                    final orders = osnap.data!;
                                    if (orders.isEmpty) {
                                      return const Center(child: Text('No pending orders.'));
                                    }
                                    // Filter orders that include any medicine from this category
                                    return FutureBuilder<List<Medicine>>( 
                                      future: context.read<StockProvider>().streamMedicines(_selectedCategoryId!).first,
                                      builder: (fc, fSnap) {
                                        final meds = fSnap.data ?? [];
                                        final medIds = meds.map((e) => e.id).toSet();
                                        final filtered = orders.where((o) => o.items.any((it) => medIds.contains(it.medicineId))).toList();
                                        if (filtered.isEmpty) {
                                          return const Center(child: Text('No pending orders for this category.'));
                                        }
                                        return ListView.builder(
                                          itemCount: filtered.length,
                                          itemBuilder: (c3, i) {
                                            final ord = filtered[i];
                                            return Card(
                                              child: ListTile(
                                                title: Text('Order ${ord.id} • ${ord.studentId}'),
                                                subtitle: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: ord.items.map((it) => Text('${it.name} x ${it.qty}')).toList(),
                                                ),
                                                isThreeLine: true,
                                                trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (ord.status == 'pending') ...[
                                                      TextButton(
                                                        onPressed: () async {
                                                          final hwId = FirebaseAuth.instance.currentUser?.uid ?? user.username;
                                                          final messenger = ScaffoldMessenger.of(context);
                                                          final stock = context.read<StockProvider>();
                                                          final choice = await showDialog<String>(
                                                            context: context,
                                                            builder: (dCtx) => AlertDialog(
                                                              title: const Text('Accept Order'),
                                                              content: const Text('Choose how to accept this order:\n\nA) Accept and dispatch now (decrement stock)\nB) Accept now, decrement on dispatch'),
                                                              actions: [
                                                                TextButton(onPressed: () => Navigator.pop(dCtx, 'cancel'), child: const Text('Cancel')),
                                                                FilledButton(onPressed: () => Navigator.pop(dCtx, 'A'), child: const Text('A — Accept & Dispatch now')),
                                                                FilledButton(onPressed: () => Navigator.pop(dCtx, 'B'), child: const Text('B — Accept (decrement later)')),
                                                              ],
                                                            ),
                                                          );

                                                          if (choice == null || choice == 'cancel') return;

                                                          try {
                                                            if (choice == 'A') {
                                                              await stock.acceptOrder(ord.id, hwId, decrementNow: true);
                                                              if (!mounted) return;
                                                              messenger.showSnackBar(const SnackBar(content: Text('Order accepted and dispatched (stock decremented)')));
                                                            } else {
                                                              await stock.acceptOrder(ord.id, hwId, decrementNow: false);
                                                              if (!mounted) return;
                                                              messenger.showSnackBar(const SnackBar(content: Text('Order accepted (will decrement on dispatch)')));
                                                            }
                                                          } catch (e) {
                                                            if (!mounted) return;
                                                            messenger.showSnackBar(SnackBar(content: Text('Accept failed: $e')));
                                                          }
                                                        },
                                                        child: const Text('Accept'),
                                                      ),
                                                      TextButton(onPressed: () async { await context.read<StockProvider>().declineOrder(ord.id, user.username); }, child: const Text('Decline')),
                                                    ] else if (ord.status == 'accepted') ...[
                                                      FilledButton(
                                                        onPressed: () async {
                                                          final hwId = FirebaseAuth.instance.currentUser?.uid ?? user.username;
                                                          try {
                                                            await context.read<StockProvider>().dispatchOrder(ord.id, hwId);
                                                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order dispatched and stock decremented')));
                                                          } catch (e) {
                                                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dispatch failed: $e')));
                                                          }
                                                        },
                                                        child: const Text('Dispatch'),
                                                      ),
                                                      TextButton(onPressed: () async { await context.read<StockProvider>().declineOrder(ord.id, user.username); }, child: const Text('Decline')),
                                                    ] else ...[
                                                      const Text('—'),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


