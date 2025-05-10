import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/driver_location_model.dart';
import '../models/commuter_location_model.dart';
import '../models/vehicle_model.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<Position>? _positionStream;
  String? _userId;
  String? _userRole;
  bool _isLocationVisible = true;
  String? _selectedPuvType;
  String? _vehicleId;
  String? _routeId;

  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Future<void> initialize(String userRole) async {
    _userId = _auth.currentUser?.uid;
    _userRole = userRole;

    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    // Request permissions
    await _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
  }

  Future<void> startLocationTracking({bool isVisible = true}) async {
    _isLocationVisible = isVisible;

    // Cancel any existing streams
    await stopLocationTracking();

    // Set up the location stream with appropriate settings
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_updateLocation);

    // Set initial status
    await _updateOnlineStatus(true);
  }

  Future<void> stopLocationTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    await _updateOnlineStatus(false);
  }

  Future<void> updateLocationVisibility(bool isVisible) async {
    _isLocationVisible = isVisible;
    final position = await Geolocator.getCurrentPosition();
    await _updateLocation(position);
  }

  Future<void> _updateLocation(Position position) async {
    if (_userId == null) return;

    final location = GeoPoint(position.latitude, position.longitude);
    final timestamp = FieldValue.serverTimestamp();

    try {
      // Determine the collection based on user role
      String collection =
          _userRole == 'driver' ? 'driver_locations' : 'commuter_locations';

      // Create base data
      Map<String, dynamic> locationData = {
        'userId': _userId,
        'location': location,
        'heading': position.heading,
        'speed': position.speed,
        'isLocationVisible': _isLocationVisible,
        'lastUpdated': timestamp,
        'deviceInfo': {'platform': 'mobile', 'accuracy': position.accuracy},
      };

      // Add role-specific data
      if (_userRole == 'driver') {
        // Add driver-specific data
        locationData['isOnline'] = true;
        locationData['puvType'] = _selectedPuvType;
        locationData['vehicleId'] = _vehicleId;
        locationData['routeId'] = _routeId;

        // If we have vehicle details, add them
        if (_vehicleId != null) {
          try {
            final vehicleDoc =
                await _firestore.collection('vehicles').doc(_vehicleId).get();
            if (vehicleDoc.exists) {
              final vehicleData = vehicleDoc.data();
              locationData['plateNumber'] = vehicleData?['plateNumber'];
              locationData['capacity'] =
                  '0/8'; // Default capacity, should be updated with real data
              locationData['status'] = 'Available'; // Default status
            }
          } catch (e) {
            print('Error fetching vehicle data: $e');
          }
        }

        // Add driver name and rating
        final userDoc = await _firestore.collection('users').doc(_userId).get();
        if (userDoc.exists) {
          locationData['driverName'] =
              userDoc.data()?['displayName'] ?? 'Driver';
          locationData['rating'] =
              userDoc.data()?['rating'] ?? 4.5; // Default rating
        }
      } else if (_userRole == 'commuter') {
        // Add commuter-specific data
        locationData['selectedPuvType'] = _selectedPuvType;

        // Add user name
        final userDoc = await _firestore.collection('users').doc(_userId).get();
        if (userDoc.exists) {
          locationData['userName'] =
              userDoc.data()?['displayName'] ?? 'Commuter';
        }
      }

      await _firestore
          .collection(collection)
          .doc(_userId)
          .set(locationData, SetOptions(merge: true));
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    if (_userId == null || _userRole != 'driver') return;

    try {
      await _firestore.collection('driver_locations').doc(_userId).set({
        'userId': _userId,
        'isOnline': isOnline,
        'isLocationVisible': isOnline ? _isLocationVisible : false,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  // Set the selected PUV type for the user
  Future<void> updateSelectedPuvType(String? puvType) async {
    _selectedPuvType = puvType;

    // Update the location data with the new PUV type
    if (_userId != null) {
      try {
        String collection =
            _userRole == 'driver' ? 'driver_locations' : 'commuter_locations';
        await _firestore.collection(collection).doc(_userId).update({
          'selectedPuvType': puvType,
          'puvType': puvType, // For backward compatibility with existing code
        });
      } catch (e) {
        print('Error updating PUV type: $e');
      }
    }
  }

  // Set vehicle and route information for drivers
  Future<void> updateDriverVehicleInfo(
    String? vehicleId,
    String? routeId,
  ) async {
    _vehicleId = vehicleId;
    _routeId = routeId;

    // Update the location data with the new vehicle and route info
    if (_userId != null && _userRole == 'driver') {
      try {
        await _firestore.collection('driver_locations').doc(_userId).update({
          'vehicleId': vehicleId,
          'routeId': routeId,
        });

        // Fetch and update vehicle details
        if (vehicleId != null) {
          final position = await Geolocator.getCurrentPosition();
          await _updateLocation(position);
        }
      } catch (e) {
        print('Error updating driver vehicle info: $e');
      }
    }
  }

  // Get a stream of nearby drivers based on PUV type
  Stream<List<DriverLocation>> getNearbyDrivers({
    required LatLng center,
    double radiusKm = 5.0,
    String? puvType,
  }) {
    // Get all online drivers
    Query query = _firestore
        .collection('driver_locations')
        .where('isOnline', isEqualTo: true)
        .where('isLocationVisible', isEqualTo: true);

    // Filter by PUV type if specified
    if (puvType != null) {
      query = query.where('puvType', isEqualTo: puvType);
    }

    // We'll filter by distance client-side since Firestore doesn't support geoqueries directly
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            // Convert to DriverLocation model
            return DriverLocation.fromFirestore(doc);
          })
          .where((driver) {
            // Filter by distance
            final driverLocation = driver.location;
            final distanceInMeters = Geolocator.distanceBetween(
              center.latitude,
              center.longitude,
              driverLocation.latitude,
              driverLocation.longitude,
            );
            return distanceInMeters / 1000 <= radiusKm;
          })
          .toList();
    });
  }

  // Get a stream of nearby commuters based on PUV type
  Stream<List<CommuterLocation>> getNearbyCommuters({
    required LatLng center,
    double radiusKm = 5.0,
    String? puvType,
  }) {
    // Get all visible commuters
    Query query = _firestore
        .collection('commuter_locations')
        .where('isLocationVisible', isEqualTo: true);

    // Filter by selected PUV type if specified
    if (puvType != null) {
      query = query.where('selectedPuvType', isEqualTo: puvType);
    }

    // We'll filter by distance client-side
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            // Convert to CommuterLocation model
            return CommuterLocation.fromFirestore(doc);
          })
          .where((commuter) {
            // Filter by distance
            final commuterLocation = commuter.location;
            final distanceInMeters = Geolocator.distanceBetween(
              center.latitude,
              center.longitude,
              commuterLocation.latitude,
              commuterLocation.longitude,
            );
            return distanceInMeters / 1000 <= radiusKm;
          })
          .toList();
    });
  }

  // Get nearby drivers once (not as a stream)
  Future<List<DriverLocation>> getNearbyDriversOnce({
    required LatLng center,
    double radiusKm = 5.0,
    String? puvType,
  }) async {
    // Get all online drivers
    Query query = _firestore
        .collection('driver_locations')
        .where('isOnline', isEqualTo: true)
        .where('isLocationVisible', isEqualTo: true);

    // Filter by PUV type if specified
    if (puvType != null) {
      query = query.where('puvType', isEqualTo: puvType);
    }

    final snapshot = await query.get();

    // Convert to DriverLocation models and filter by distance
    return snapshot.docs
        .map((doc) {
          return DriverLocation.fromFirestore(doc);
        })
        .where((driver) {
          // Filter by distance
          final driverLocation = driver.location;
          final distanceInMeters = Geolocator.distanceBetween(
            center.latitude,
            center.longitude,
            driverLocation.latitude,
            driverLocation.longitude,
          );
          return distanceInMeters / 1000 <= radiusKm;
        })
        .toList();
  }

  // Clean up resources
  void dispose() {
    _positionStream?.cancel();
  }
}
