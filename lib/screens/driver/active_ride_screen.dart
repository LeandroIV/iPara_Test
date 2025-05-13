import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../models/ride_request_model.dart';
import '../../services/proximity_service.dart';

// Google Maps API key
const String _googleApiKey = "AIzaSyDtm_kDatDOlKtvEMCA5lcVRFyTM6f6NNk";

class DriverActiveRideScreen extends StatefulWidget {
  final RideRequest rideRequest;

  const DriverActiveRideScreen({super.key, required this.rideRequest});

  @override
  State<DriverActiveRideScreen> createState() => _DriverActiveRideScreenState();
}

class _DriverActiveRideScreenState extends State<DriverActiveRideScreen> {
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
  bool _isNearCommuter = false;
  bool _isNearDestination = false;

  // UI state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _rideRequest = widget.rideRequest;
    _destinationLocation = _rideRequest.destinationLocation;
    _commuterLocation = _rideRequest.commuterLocation;
    _driverLocation = _rideRequest.driverLocation;

    // Start tracking the ride
    _startRideTracking();

    // Start proximity monitoring
    _proximityService.startProximityMonitoring(_rideRequest.id);

    // Initial polyline update
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (mounted) {
        await _updateRoutePolyline();
      }
    });
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

    // Start tracking driver's location
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
    setState(() {
      _rideRequest = updatedRequest;

      // If the ride is completed, calculate fare
      if (_rideRequest.status == RideRequestStatus.completed) {
        _calculateFare();
      }
    });

    // Update the commuter's location on the map
    _updateCommuterMarker();

    // If the ride status changed, show a notification
    if (updatedRequest.status != widget.rideRequest.status) {
      _showStatusChangeNotification(updatedRequest.status);
    }
  }

  // Start tracking the driver's location
  void _startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_updateDriverLocation);
  }

  // Update the driver's location
  void _updateDriverLocation(Position position) {
    final newLocation = LatLng(position.latitude, position.longitude);

    // Calculate distance traveled if we have previous location
    if (_driverLocation != null &&
        _rideRequest.status == RideRequestStatus.inTransit) {
      final distanceInMeters = Geolocator.distanceBetween(
        _driverLocation!.latitude,
        _driverLocation!.longitude,
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

      // Update the ride request with the new distance
      _updateRideRequestDistance();
    }

    setState(() {
      _driverLocation = newLocation;
    });

    // Update driver marker
    _updateDriverMarker();

    // Update driver location in Firestore
    _updateDriverLocationInFirestore(newLocation);

    // Update polyline to commuter or destination
    _updateRoutePolyline().catchError((error) {
      debugPrint('Error updating route polyline: $error');
    });

    // Check proximity to commuter
    _checkProximityToCommuter(newLocation);

    // Check proximity to destination if in transit
    if (_rideRequest.status == RideRequestStatus.inTransit &&
        _destinationLocation != null) {
      _checkProximityToDestination(newLocation);
    }

    // Center map on driver and commuter
    _centerMapOnRide();
  }

  // Check if driver is near commuter
  void _checkProximityToCommuter(LatLng driverLocation) {
    if (_commuterLocation == null) return;

    // Only check if ride is in accepted state
    if (_rideRequest.status != RideRequestStatus.accepted) return;

    final distanceInMeters = Geolocator.distanceBetween(
      driverLocation.latitude,
      driverLocation.longitude,
      _commuterLocation!.latitude,
      _commuterLocation!.longitude,
    );

    // If within 50 meters and not already marked as near
    if (distanceInMeters <= 50 && !_isNearCommuter) {
      setState(() {
        _isNearCommuter = true;
      });

      // Update ride status to boarding
      _updateRideStatus(RideRequestStatus.boarding);

      // Show notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have arrived at the pickup location'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Check if driver is near destination
  void _checkProximityToDestination(LatLng driverLocation) {
    if (_destinationLocation == null) return;

    // Only check if ride is in transit
    if (_rideRequest.status != RideRequestStatus.inTransit) return;

    final distanceInMeters = Geolocator.distanceBetween(
      driverLocation.latitude,
      driverLocation.longitude,
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
            content: Text('You are approaching the destination'),
            backgroundColor: Colors.purple,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }

    // If within 20 meters, automatically update to arrived status
    if (distanceInMeters <= 20) {
      _updateRideStatus(RideRequestStatus.arrived);
    }
  }

  // Update the driver's location in Firestore
  Future<void> _updateDriverLocationInFirestore(LatLng location) async {
    try {
      await _firestore.collection('ride_requests').doc(_rideRequest.id).update({
        'driverLocation': GeoPoint(location.latitude, location.longitude),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating driver location: $e');
    }
  }

  // Update the ride request with the new distance traveled
  Future<void> _updateRideRequestDistance() async {
    try {
      await _firestore.collection('ride_requests').doc(_rideRequest.id).update({
        'totalDistanceTraveled': _distanceTraveled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating ride distance: $e');
    }
  }

  // Update the driver marker on the map
  void _updateDriverMarker() {
    if (_driverLocation != null) {
      setState(() {
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
              title: 'Your Location (${_rideRequest.puvType})',
            ),
          ),
        );
      });
    }
  }

  // Update the commuter marker on the map
  void _updateCommuterMarker() {
    if (_rideRequest.commuterLocation != _commuterLocation) {
      setState(() {
        _commuterLocation = _rideRequest.commuterLocation;

        // Update the commuter marker
        _markers.removeWhere((marker) => marker.markerId.value == 'commuter');
        _markers.add(
          Marker(
            markerId: const MarkerId('commuter'),
            position: _commuterLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: _rideRequest.commuterName ?? 'Commuter',
            ),
          ),
        );
      });

      // Update polyline to commuter
      if (_rideRequest.status == RideRequestStatus.accepted ||
          _rideRequest.status == RideRequestStatus.boarding) {
        _updateRoutePolyline().catchError((error) {
          debugPrint('Error updating route polyline: $error');
        });
      }
    }
  }

  // Update the route polyline on the map
  Future<void> _updateRoutePolyline() async {
    // Clear existing polylines
    setState(() {
      _polylines.clear();
    });

    // If in transit, show the actual route traveled
    if (_routePoints.isNotEmpty &&
        _rideRequest.status == RideRequestStatus.inTransit) {
      setState(() {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: _routePoints,
            color: Colors.blue,
            width: 5,
          ),
        );
      });
    }
    // If accepted or boarding, show route to commuter
    else if ((_rideRequest.status == RideRequestStatus.accepted ||
            _rideRequest.status == RideRequestStatus.boarding) &&
        _driverLocation != null &&
        _commuterLocation != null) {
      try {
        // Get directions from Google API
        final List<LatLng> routePoints = await _getDirections(
          _driverLocation!,
          _commuterLocation!,
        );

        if (mounted) {
          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('to_commuter'),
                points: routePoints,
                color: Colors.orange,
                width: 5,
              ),
            );
          });
        }
      } catch (e) {
        debugPrint('Error getting directions to commuter: $e');
        // Fallback to direct line if directions API fails
        if (mounted) {
          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('to_commuter'),
                points: [_driverLocation!, _commuterLocation!],
                color: Colors.orange,
                width: 5,
                patterns: [PatternItem.dash(20), PatternItem.gap(10)],
              ),
            );
          });
        }
      }
    }
    // If arrived or completed, show route to destination
    else if ((_rideRequest.status == RideRequestStatus.arrived ||
            _rideRequest.status == RideRequestStatus.completed ||
            _rideRequest.status == RideRequestStatus.paid) &&
        _destinationLocation != null &&
        _driverLocation != null) {
      try {
        // Get directions from Google API
        final List<LatLng> routePoints = await _getDirections(
          _driverLocation!,
          _destinationLocation!,
        );

        if (mounted) {
          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('to_destination'),
                points: routePoints,
                color: Colors.green,
                width: 5,
              ),
            );
          });
        }
      } catch (e) {
        debugPrint('Error getting directions to destination: $e');
        // Fallback to direct line if directions API fails
        if (mounted) {
          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('to_destination'),
                points:
                    _routePoints.isNotEmpty
                        ? _routePoints
                        : [_driverLocation!, _destinationLocation!],
                color: Colors.green,
                width: 5,
              ),
            );
          });
        }
      }
    }
  }

  // Method to get directions from the Google Directions API
  Future<List<LatLng>> _getDirections(LatLng origin, LatLng destination) async {
    // For mobile, use the HTTP API
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=$_googleApiKey';

    try {
      debugPrint('Fetching directions from Google API');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          // Decode polyline points
          final points = data['routes'][0]['overview_polyline']['points'];
          final polylinePoints = PolylinePoints().decodePolyline(points);

          // Convert to LatLng coordinates
          return polylinePoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        } else {
          debugPrint('Directions API error: ${data['status']}');
          // If error, return direct line between points as fallback
          return [origin, destination];
        }
      } else {
        debugPrint('Failed to fetch directions: ${response.statusCode}');
        // Return direct line as fallback
        return [origin, destination];
      }
    } catch (e) {
      debugPrint('Error fetching directions: $e');
      // Return direct line as fallback
      return [origin, destination];
    }
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
        message = 'You have accepted this ride request';
        color = Colors.blue;
        break;
      case RideRequestStatus.boarding:
        message = 'Waiting for commuter to board';
        color = Colors.orange;
        break;
      case RideRequestStatus.inTransit:
        message = 'Commuter has boarded, ride in progress';
        color = Colors.green;
        break;
      case RideRequestStatus.arrived:
        message = 'You have arrived at the destination';
        color = Colors.purple;
        break;
      case RideRequestStatus.completed:
        message = 'Ride completed, waiting for payment';
        color = Colors.amber;
        break;
      case RideRequestStatus.paid:
        message = 'Payment completed. Thank you!';
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

  // Calculate the fare based on distance traveled
  void _calculateFare() {
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

    // Calculate fare
    double calculatedFare = baseFare;

    // Add per km charge for distance beyond the base distance
    double baseDistance =
        _rideRequest.puvType.toLowerCase() == 'bus'
            ? 5.0
            : _rideRequest.puvType.toLowerCase() == 'motorela'
            ? 2.0
            : 4.0;

    if (_distanceTraveled > baseDistance) {
      calculatedFare += (_distanceTraveled - baseDistance) * ratePerKm;
    }

    // Round to nearest peso
    calculatedFare = (calculatedFare * 10).round() / 10;

    setState(() {
      _estimatedFare = calculatedFare;
    });
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
        updateData['totalDistanceTraveled'] = _distanceTraveled;
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

  // Build the ride status panel based on the current ride status
  Widget _buildRideStatusPanel() {
    // Get status description
    final statusDescription = _rideRequest.status.description;

    // Build different UI based on ride status
    switch (_rideRequest.status) {
      case RideRequestStatus.accepted:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Commuter: ${_rideRequest.commuterName ?? 'Unknown'}',
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed:
                      () => _updateRideStatus(RideRequestStatus.boarding),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    elevation: 3,
                  ),
                  child: const Text('Arrived at Pickup'),
                ),
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
                                  await _updateRideStatus(
                                    RideRequestStatus.cancelled,
                                  );
                                  if (mounted) {
                                    final context = this.context;
                                    if (context.mounted) {
                                      Navigator.pop(
                                        context,
                                      ); // Return to previous screen
                                    }
                                  }
                                },
                                child: const Text('Yes'),
                              ),
                            ],
                          ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    elevation: 3,
                  ),
                  child: const Text('Cancel Ride'),
                ),
              ],
            ),
          ],
        );

      case RideRequestStatus.boarding:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Commuter: ${_rideRequest.commuterName ?? 'Unknown'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Waiting for commuter to board',
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
              onPressed: () => _updateRideStatus(RideRequestStatus.inTransit),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 3,
              ),
              child: const Text('Start Ride'),
            ),
          ],
        );

      case RideRequestStatus.inTransit:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Commuter: ${_rideRequest.commuterName ?? 'Unknown'}',
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _updateRideStatus(RideRequestStatus.arrived),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 3,
              ),
              child: const Text('Arrived at Destination'),
            ),
          ],
        );

      case RideRequestStatus.arrived:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Arrived at Destination',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total distance: ${_distanceTraveled.toStringAsFixed(2)} km',
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
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _updateRideStatus(RideRequestStatus.completed),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 3,
              ),
              child: const Text('Complete Ride'),
            ),
          ],
        );

      case RideRequestStatus.completed:
      case RideRequestStatus.paid:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ride Completed',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total distance: ${_distanceTraveled.toStringAsFixed(2)} km',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total fare: ₱${(_rideRequest.fareAmount ?? _estimatedFare).toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            if (_rideRequest.status == RideRequestStatus.completed)
              const Text(
                'Waiting for payment...',
                style: TextStyle(
                  color: Colors.amber,
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (_rideRequest.status == RideRequestStatus.paid)
              Text(
                'Payment received via ${_rideRequest.paymentMethodId ?? 'cash'}',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Return to previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 3,
              ),
              child: const Text('Return to Home'),
            ),
          ],
        );

      case RideRequestStatus.cancelled:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ride Cancelled',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Return to previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 3,
              ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 3,
              ),
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
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _rideRequest.driverLocation,
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
              _updateCommuterMarker();

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

              // Force update polylines
              Future.delayed(const Duration(milliseconds: 300), () async {
                if (mounted) {
                  await _updateRoutePolyline();
                  _centerMapOnRide();
                }
              });
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
