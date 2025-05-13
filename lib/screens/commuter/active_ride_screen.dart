import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ride_request_model.dart';
import '../../services/proximity_service.dart';
import 'ride_payment_screen.dart';

class ActiveRideScreen extends StatefulWidget {
  final RideRequest rideRequest;

  const ActiveRideScreen({super.key, required this.rideRequest});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProximityService _proximityService = ProximityService();

  late RideRequest _rideRequest;
  GoogleMapController? _mapController;
  StreamSubscription<DocumentSnapshot>? _rideRequestSubscription;
  StreamSubscription<Position>? _positionSubscription;

  // Map markers and polylines
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Ride tracking
  LatLng? _driverLocation;
  LatLng? _commuterLocation;
  LatLng? _destinationLocation;
  double _distanceTraveled = 0.0;
  double _estimatedFare = 0.0;
  final List<LatLng> _routePoints = [];

  // Proximity detection
  bool _isNearDriver = false;
  bool _isNearDestination = false;

  // UI state
  bool _isLoading = true;
  final String _selectedPassengerType = 'regular';

  @override
  void initState() {
    super.initState();
    _rideRequest = widget.rideRequest;
    _destinationLocation = _rideRequest.destinationLocation;
    _driverLocation = _rideRequest.driverLocation;

    // Start tracking the ride
    _startRideTracking();

    // Start proximity monitoring
    _proximityService.startProximityMonitoring(_rideRequest.id);
  }

  @override
  void dispose() {
    _rideRequestSubscription?.cancel();
    _positionSubscription?.cancel();
    _mapController?.dispose();
    _proximityService.stopProximityMonitoring();
    super.dispose();
  }

  // Start tracking the ride
  void _startRideTracking() {
    // Listen for updates to the ride request
    _rideRequestSubscription = FirebaseFirestore.instance
        .collection('ride_requests')
        .doc(_rideRequest.id)
        .snapshots()
        .listen(_handleRideRequestUpdate);

    // Start tracking commuter's location
    _startLocationTracking();
  }

  // Handle updates to the ride request
  void _handleRideRequestUpdate(DocumentSnapshot snapshot) {
    if (!snapshot.exists) {
      // Ride request was deleted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This ride request no longer exists'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    // Update the ride request
    final updatedRequest = RideRequest.fromFirestore(snapshot);
    final previousStatus = _rideRequest.status;

    setState(() {
      _rideRequest = updatedRequest;

      // If the ride is completed, calculate fare
      if (_rideRequest.status == RideRequestStatus.completed) {
        _calculateFare();
      }
    });

    // Update the driver's location on the map
    _updateDriverMarker();

    // If the ride status changed, show a notification and handle transitions
    if (updatedRequest.status != previousStatus) {
      _showStatusChangeNotification(updatedRequest.status);
      _handleStatusTransition(updatedRequest.status, previousStatus);
    }

    // Check proximity between driver and commuter
    _checkProximityToDriver();
  }

  // Handle automatic transitions based on status changes
  void _handleStatusTransition(
    RideRequestStatus newStatus,
    RideRequestStatus oldStatus,
  ) {
    switch (newStatus) {
      case RideRequestStatus.completed:
        // Automatically show payment screen when ride is completed
        _showPaymentScreen();
        break;
      default:
        break;
    }
  }

  // Show the payment screen
  void _showPaymentScreen() {
    // Short delay to allow the UI to update first
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => RidePaymentScreen(
                  rideRequest: _rideRequest,
                  fareAmount: _estimatedFare,
                  onPaymentComplete: (success) {
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Payment successful! Thank you for riding with iPara.',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Return to home screen after a short delay
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) {
                          final context = this.context;
                          if (context.mounted) {
                            Navigator.pop(context); // Return to home screen
                          }
                        }
                      });
                    }
                  },
                ),
          ),
        );
      }
    });
  }

  // Check proximity between commuter and driver
  void _checkProximityToDriver() {
    if (_commuterLocation == null || _driverLocation == null) return;

    final distanceInMeters = Geolocator.distanceBetween(
      _commuterLocation!.latitude,
      _commuterLocation!.longitude,
      _driverLocation!.latitude,
      _driverLocation!.longitude,
    );

    // If within 10 meters and not already marked as near
    if (distanceInMeters <= 10 && !_isNearDriver) {
      setState(() {
        _isNearDriver = true;
      });

      // If the ride is in boarding status, automatically update to in transit
      if (_rideRequest.status == RideRequestStatus.boarding) {
        _updateRideStatus(RideRequestStatus.inTransit);
      }

      // Show notification to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are now near the driver'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Update ride status
  Future<void> _updateRideStatus(RideRequestStatus newStatus) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Add additional fields based on status
      Map<String, dynamic> updateData = {
        'status': newStatus.index,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add specific fields based on status
      if (newStatus == RideRequestStatus.inTransit) {
        updateData['rideStartTime'] = Timestamp.now();
      } else if (newStatus == RideRequestStatus.arrived ||
          newStatus == RideRequestStatus.completed) {
        updateData['rideEndTime'] = Timestamp.now();
      }

      // Update in Firestore
      await _firestore
          .collection('ride_requests')
          .doc(_rideRequest.id)
          .update(updateData);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        final context = this.context;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update ride status: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Start tracking the commuter's location
  void _startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_updateCommuterLocation);
  }

  // Update the commuter's location
  void _updateCommuterLocation(Position position) {
    final newLocation = LatLng(position.latitude, position.longitude);

    // Calculate distance traveled if we have previous location
    if (_commuterLocation != null &&
        _rideRequest.status == RideRequestStatus.inTransit) {
      final distanceInMeters = Geolocator.distanceBetween(
        _commuterLocation!.latitude,
        _commuterLocation!.longitude,
        newLocation.latitude,
        newLocation.longitude,
      );

      // Add to total distance traveled
      setState(() {
        _distanceTraveled += distanceInMeters / 1000; // Convert to kilometers
        _calculateFare();
      });

      // Add point to route
      _routePoints.add(newLocation);
      _updateRoutePolyline();
    }

    setState(() {
      _commuterLocation = newLocation;
    });

    // Update commuter marker
    _updateCommuterMarker();

    // Check proximity to driver
    _checkProximityToDriver();

    // Check proximity to destination if in transit
    if (_rideRequest.status == RideRequestStatus.inTransit &&
        _destinationLocation != null) {
      _checkProximityToDestination(newLocation);
    }

    // Center map on commuter and driver
    _centerMapOnRide();
  }

  // Check if commuter is near destination
  void _checkProximityToDestination(LatLng commuterLocation) {
    if (_destinationLocation == null) return;

    // Only check if ride is in transit
    if (_rideRequest.status != RideRequestStatus.inTransit) return;

    final distanceInMeters = Geolocator.distanceBetween(
      commuterLocation.latitude,
      commuterLocation.longitude,
      _destinationLocation!.latitude,
      _destinationLocation!.longitude,
    );

    // If within 100 meters and not already marked as near
    if (distanceInMeters <= 100 && !_isNearDestination) {
      setState(() {
        _isNearDestination = true;
      });

      // Show notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are approaching your destination'),
            backgroundColor: Colors.purple,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Update the driver marker on the map
  void _updateDriverMarker() {
    if (_rideRequest.driverLocation != _driverLocation) {
      setState(() {
        _driverLocation = _rideRequest.driverLocation;

        // Update the driver marker
        _markers.removeWhere((marker) => marker.markerId.value == 'driver');
        _markers.add(
          Marker(
            markerId: const MarkerId('driver'),
            position: _driverLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(
              title:
                  '${_rideRequest.driverName ?? 'Driver'} (${_rideRequest.puvType})',
            ),
          ),
        );
      });

      // Update polyline to driver
      if (_rideRequest.status == RideRequestStatus.accepted ||
          _rideRequest.status == RideRequestStatus.boarding ||
          _rideRequest.status == RideRequestStatus.arrived ||
          _rideRequest.status == RideRequestStatus.completed ||
          _rideRequest.status == RideRequestStatus.paid) {
        _updateRoutePolyline();
      }
    }
  }

  // Update the commuter marker on the map
  void _updateCommuterMarker() {
    if (_commuterLocation != null) {
      setState(() {
        // Update the commuter marker
        _markers.removeWhere((marker) => marker.markerId.value == 'commuter');
        _markers.add(
          Marker(
            markerId: const MarkerId('commuter'),
            position: _commuterLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );
      });

      // Update polyline to driver if in accepted or boarding state
      if ((_rideRequest.status == RideRequestStatus.accepted ||
              _rideRequest.status == RideRequestStatus.boarding) &&
          _driverLocation != null) {
        _updateRoutePolyline();
      }
    }
  }

  // Update the route polyline on the map
  void _updateRoutePolyline() {
    setState(() {
      _polylines.clear();

      // If in transit, show the actual route traveled
      if (_routePoints.isNotEmpty &&
          _rideRequest.status == RideRequestStatus.inTransit) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: _routePoints,
            color: Colors.blue,
            width: 5,
          ),
        );
      }
      // If accepted or boarding, show direct line to driver
      else if ((_rideRequest.status == RideRequestStatus.accepted ||
              _rideRequest.status == RideRequestStatus.boarding) &&
          _driverLocation != null &&
          _commuterLocation != null) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('to_driver'),
            points: [_commuterLocation!, _driverLocation!],
            color: Colors.orange,
            width: 5,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      }
      // If arrived or completed, show line to destination
      else if ((_rideRequest.status == RideRequestStatus.arrived ||
              _rideRequest.status == RideRequestStatus.completed ||
              _rideRequest.status == RideRequestStatus.paid) &&
          _destinationLocation != null &&
          _driverLocation != null) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('to_destination'),
            points: [_driverLocation!, _destinationLocation!],
            color: Colors.green,
            width: 5,
          ),
        );
      }
    });
  }

  // Center the map on the ride (commuter and driver)
  void _centerMapOnRide() {
    if (_mapController != null &&
        _commuterLocation != null &&
        _driverLocation != null) {
      // Calculate bounds that include both commuter and driver
      final bounds = LatLngBounds(
        southwest: LatLng(
          _commuterLocation!.latitude < _driverLocation!.latitude
              ? _commuterLocation!.latitude
              : _driverLocation!.latitude,
          _commuterLocation!.longitude < _driverLocation!.longitude
              ? _commuterLocation!.longitude
              : _driverLocation!.longitude,
        ),
        northeast: LatLng(
          _commuterLocation!.latitude > _driverLocation!.latitude
              ? _commuterLocation!.latitude
              : _driverLocation!.latitude,
          _commuterLocation!.longitude > _driverLocation!.longitude
              ? _commuterLocation!.longitude
              : _driverLocation!.longitude,
        ),
      );

      // Add padding to the bounds
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  // Show a notification when the ride status changes
  void _showStatusChangeNotification(RideRequestStatus status) {
    if (!mounted) return;

    String message = '';
    Color color = Colors.blue;

    switch (status) {
      case RideRequestStatus.accepted:
        message = 'Driver has accepted your request and is on the way';
        color = Colors.blue;
        break;
      case RideRequestStatus.boarding:
        message =
            'Driver has arrived at your location. Please board the vehicle.';
        color = Colors.orange;
        break;
      case RideRequestStatus.inTransit:
        message = 'You are now in transit to your destination';
        color = Colors.green;
        break;
      case RideRequestStatus.arrived:
        message = 'You have arrived at your destination';
        color = Colors.purple;
        break;
      case RideRequestStatus.completed:
        message = 'Ride completed. Please proceed to payment.';
        color = Colors.amber;
        break;
      case RideRequestStatus.paid:
        message = 'Payment completed. Thank you for riding!';
        color = Colors.green;
        break;
      case RideRequestStatus.cancelled:
        message = 'Ride has been cancelled';
        color = Colors.red;
        break;
      default:
        return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Calculate the fare based on distance traveled and passenger type
  void _calculateFare() {
    // Get the total distance traveled (either from tracking or from the ride request)
    final distance = _rideRequest.totalDistanceTraveled ?? _distanceTraveled;

    // Calculate fare based on passenger type and PUV type
    // Basic fare calculation for Philippine context
    // Base fare + (distance in km * rate per km)
    double baseFare = 0.0;
    double ratePerKm = 0.0;

    // Set rates based on PUV type
    switch (_rideRequest.puvType.toLowerCase()) {
      case 'jeepney':
      case 'multicab':
        baseFare = 11.0; // PHP 11 for first 4 km
        ratePerKm = 1.5; // PHP 1.50 per additional km
        break;
      case 'bus':
        baseFare = 13.0; // PHP 13 for first 5 km
        ratePerKm = 2.2; // PHP 2.20 per additional km
        break;
      case 'motorela':
        baseFare = 10.0; // PHP 10 for first 2 km
        ratePerKm = 2.0; // PHP 2 per additional km
        break;
      default:
        baseFare = 11.0;
        ratePerKm = 1.5;
    }

    // Apply discount based on passenger type
    double discountFactor = 1.0;
    switch (_selectedPassengerType) {
      case 'student':
        discountFactor = 0.8; // 20% discount
        break;
      case 'senior':
        discountFactor = 0.8; // 20% discount
        break;
      case 'pwd':
        discountFactor = 0.8; // 20% discount
        break;
      default:
        discountFactor = 1.0; // No discount
    }

    // Calculate fare
    double calculatedFare = baseFare;

    // Add per km charge for distance beyond the base distance
    double baseDistance =
        _rideRequest.puvType.toLowerCase() == 'bus'
            ? 5.0
            : _rideRequest.puvType.toLowerCase() == 'motorela'
            ? 2.0
            : 4.0;

    if (distance > baseDistance) {
      calculatedFare += (distance - baseDistance) * ratePerKm;
    }

    // Apply discount
    calculatedFare *= discountFactor;

    // Round to nearest peso
    calculatedFare = (calculatedFare * 10).round() / 10;

    setState(() {
      _estimatedFare = calculatedFare;
    });
  }

  // Build the ride status panel based on the current ride status
  Widget _buildRideStatusPanel() {
    // Get status description
    final statusDescription = _rideRequest.status.description;

    // Build different UI based on ride status
    switch (_rideRequest.status) {
      case RideRequestStatus.pending:
      case RideRequestStatus.accepted:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Driver: ${_rideRequest.driverName ?? 'Unknown'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${_rideRequest.status.displayName}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusDescription,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'ETA: ${_rideRequest.etaMinutes} minutes',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Cancel Ride?'),
                        content: const Text(
                          'Are you sure you want to cancel this ride?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              // Update ride status to cancelled
                              final updatedRequest = _rideRequest.copyWith(
                                status: RideRequestStatus.cancelled,
                                updatedAt: DateTime.now(),
                              );

                              try {
                                // Update in Firestore
                                await _firestore
                                    .collection('ride_requests')
                                    .doc(_rideRequest.id)
                                    .update(updatedRequest.toFirestore());

                                if (mounted) {
                                  final context = this.context;
                                  if (context.mounted) {
                                    Navigator.pop(
                                      context,
                                    ); // Return to previous screen
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  final context = this.context;
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to cancel ride: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            child: const Text('Yes'),
                          ),
                        ],
                      ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cancel Ride'),
            ),
          ],
        );

      case RideRequestStatus.boarding:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Driver: ${_rideRequest.driverName ?? 'Unknown'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Driver has arrived!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusDescription,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Confirm boarding
                try {
                  // Update ride status to in transit
                  final updatedRequest = _rideRequest.copyWith(
                    status: RideRequestStatus.inTransit,
                    rideStartTime: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  // Update in Firestore
                  await _firestore
                      .collection('ride_requests')
                      .doc(_rideRequest.id)
                      .update(updatedRequest.toFirestore());
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to confirm boarding: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Confirm Boarding'),
            ),
          ],
        );

      case RideRequestStatus.inTransit:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Driver: ${_rideRequest.driverName ?? 'Unknown'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'In Transit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Distance traveled: ${_distanceTraveled.toStringAsFixed(2)} km',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Estimated fare: ₱${_estimatedFare.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        );

      case RideRequestStatus.arrived:
      case RideRequestStatus.completed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You have arrived!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total distance: ${(_rideRequest.totalDistanceTraveled ?? _distanceTraveled).toStringAsFixed(2)} km',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total fare: ₱${_estimatedFare.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Show digital payment dialog
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Digital Payment'),
                            content: Text(
                              'Digital payment of ₱${_estimatedFare.toStringAsFixed(2)} will be processed.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);

                                  // Update ride status to paid
                                  final updatedRequest = _rideRequest.copyWith(
                                    status: RideRequestStatus.paid,
                                    fareAmount: _estimatedFare,
                                    passengerType: _selectedPassengerType,
                                    paymentMethodId: 'digital',
                                    updatedAt: DateTime.now(),
                                  );

                                  try {
                                    // Update in Firestore
                                    await _firestore
                                        .collection('ride_requests')
                                        .doc(_rideRequest.id)
                                        .update(updatedRequest.toFirestore());

                                    if (mounted) {
                                      final context = this.context;
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Payment successful!',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      final context = this.context;
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to process payment: $e',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                child: const Text('Confirm Payment'),
                              ),
                            ],
                          ),
                    );
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('Pay Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Show cash payment dialog
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Cash Payment'),
                            content: Text(
                              'Please pay ₱${_estimatedFare.toStringAsFixed(2)} to the driver.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);

                                  // Update ride status to paid
                                  final updatedRequest = _rideRequest.copyWith(
                                    status: RideRequestStatus.paid,
                                    fareAmount: _estimatedFare,
                                    passengerType: _selectedPassengerType,
                                    paymentMethodId: 'cash',
                                    updatedAt: DateTime.now(),
                                  );

                                  try {
                                    // Update in Firestore
                                    await _firestore
                                        .collection('ride_requests')
                                        .doc(_rideRequest.id)
                                        .update(updatedRequest.toFirestore());

                                    if (mounted) {
                                      final context = this.context;
                                      if (context.mounted) {
                                        Navigator.pop(
                                          context,
                                        ); // Return to previous screen
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Payment successful!',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      final context = this.context;
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to process payment: $e',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                child: const Text('Confirm Payment'),
                              ),
                            ],
                          ),
                    );
                  },
                  icon: const Icon(Icons.money),
                  label: const Text('Pay Cash'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        );

      case RideRequestStatus.paid:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Payment Complete',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total fare: ₱${(_rideRequest.fareAmount ?? _estimatedFare).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Return to previous screen
              },
              child: const Text('Return to Home'),
            ),
          ],
        );

      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Status: ${_rideRequest.status.displayName}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusDescription,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Return to previous screen
              },
              child: const Text('Return to Home'),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Active Ride - ${_rideRequest.puvType}'),
        backgroundColor: Colors.amber,
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _rideRequest.commuterLocation,
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              setState(() {
                _isLoading = false;
              });

              // Initialize markers
              _updateDriverMarker();

              // Add destination marker if available
              if (_destinationLocation != null) {
                _markers.add(
                  Marker(
                    markerId: const MarkerId('destination'),
                    position: _destinationLocation!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed,
                    ),
                    infoWindow: const InfoWindow(title: 'Destination'),
                  ),
                );
              }
            },
          ),

          // Ride status panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade300, width: 1.0),
              ),
              child: _buildRideStatusPanel(),
            ),
          ),

          // Loading indicator
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
