import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/driver_location_model.dart';
import '../models/commuter_location_model.dart';
import '../models/vehicle_model.dart';
import 'background_location_service.dart';

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

    debugPrint(
      'Initializing LocationService with userId: $_userId, role: $_userRole',
    );

    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    // Verify the user role in Firestore
    try {
      final userDoc = await _firestore.collection('users').doc(_userId).get();
      if (userDoc.exists && userDoc.data()?['role'] != null) {
        final roleIndex = userDoc.data()?['role'] as int;
        String roleFromFirestore = '';

        // Convert role index to string
        switch (roleIndex) {
          case 0:
            roleFromFirestore = 'commuter';
            break;
          case 1:
            roleFromFirestore = 'driver';
            break;
          case 2:
            roleFromFirestore = 'operator';
            break;
          default:
            roleFromFirestore = 'commuter';
        }

        // If the role from Firestore doesn't match the provided role, use the one from Firestore
        if (roleFromFirestore != userRole) {
          debugPrint(
            'Role mismatch: provided=$userRole, Firestore=$roleFromFirestore. Using Firestore role.',
          );
          _userRole = roleFromFirestore;
        }
      }
    } catch (e) {
      debugPrint('Error verifying user role: $e');
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
    debugPrint('Starting location tracking with visibility: $isVisible');
    _isLocationVisible = isVisible;

    // Cancel any existing streams
    await stopLocationTracking();

    // For drivers, use the background location service (Android only)
    if (_userRole == 'driver') {
      try {
        debugPrint('Starting background location service for driver');

        // Set initial status
        await _updateOnlineStatus(true);

        // Start the background service
        final success = await BackgroundLocationService.startLocationTracking(
          userId: _userId!,
          puvType: _selectedPuvType ?? 'Unknown',
          isLocationVisible: isVisible,
        );

        if (success) {
          debugPrint('Background location service started successfully');
        } else {
          debugPrint(
            'Failed to start background location service, falling back to foreground tracking',
          );
          _startForegroundTracking();
        }
      } catch (e) {
        debugPrint('Error starting background location service: $e');
        debugPrint('Falling back to foreground tracking');
        _startForegroundTracking();
      }
    } else {
      // For commuters, use the regular foreground tracking
      _startForegroundTracking();
    }

    debugPrint('Location tracking started successfully');
  }

  // Start foreground location tracking
  void _startForegroundTracking() async {
    // Set up the location stream with appropriate settings
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_updateLocation);

    // Set initial status if driver
    if (_userRole == 'driver') {
      await _updateOnlineStatus(true);
    }

    // Get current position and update location immediately
    try {
      final position = await Geolocator.getCurrentPosition();
      await _updateLocation(position);
      debugPrint(
        'Initial location updated: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      debugPrint('Error getting initial position: $e');
    }
  }

  Future<void> stopLocationTracking() async {
    // Cancel foreground tracking
    await _positionStream?.cancel();
    _positionStream = null;

    // Stop background service if user is a driver
    if (_userRole == 'driver') {
      try {
        await BackgroundLocationService.stopLocationTracking();
        debugPrint('Background location service stopped');
      } catch (e) {
        debugPrint('Error stopping background location service: $e');
      }
    }

    // Update online status to false
    await _updateOnlineStatus(false);
  }

  Future<void> updateLocationVisibility(bool isVisible) async {
    _isLocationVisible = isVisible;

    // Update background service visibility if user is a driver
    if (_userRole == 'driver') {
      try {
        await BackgroundLocationService.updateLocationVisibility(isVisible);
        debugPrint('Background service visibility updated to: $isVisible');
      } catch (e) {
        debugPrint('Error updating background service visibility: $e');
      }
    }

    // Update location in Firestore
    final position = await Geolocator.getCurrentPosition();
    await _updateLocation(position);
  }

  Future<void> _updateLocation(Position position) async {
    if (_userId == null) {
      debugPrint('Cannot update location: userId is null');
      return;
    }

    debugPrint('Updating location for user $_userId (role: $_userRole)');
    debugPrint(
      'Location: ${position.latitude}, ${position.longitude}, heading: ${position.heading}',
    );

    final location = GeoPoint(position.latitude, position.longitude);
    final timestamp = FieldValue.serverTimestamp();

    try {
      // Determine the collection based on user role
      String collection =
          _userRole == 'driver' ? 'driver_locations' : 'commuter_locations';
      debugPrint('Using collection: $collection');

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

        // Add iconType based on puvType (important for map display)
        if (_selectedPuvType != null) {
          locationData['iconType'] = _selectedPuvType!.toLowerCase();
        }

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
            debugPrint('Error fetching vehicle data: $e');
          }
        }

        // Add driver name and rating
        final userDoc = await _firestore.collection('users').doc(_userId).get();
        if (userDoc.exists) {
          locationData['driverName'] =
              userDoc.data()?['displayName'] ?? 'Driver';
          locationData['rating'] =
              userDoc.data()?['rating'] ?? 4.5; // Default rating

          // Add photo URL if available
          if (userDoc.data()?['photoURL'] != null) {
            locationData['photoUrl'] = userDoc.data()?['photoURL'];
          }
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

      // Log the data being sent to Firestore
      debugPrint('Sending location data to Firestore:');
      locationData.forEach((key, value) {
        if (key != 'location') {
          // Skip GeoPoint which doesn't print well
          debugPrint('  $key: $value');
        }
      });

      // Update the document in Firestore
      await _firestore
          .collection(collection)
          .doc(_userId)
          .set(locationData, SetOptions(merge: true));

      debugPrint('Location data successfully updated in Firestore');
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    if (_userId == null || _userRole != 'driver') {
      debugPrint(
        'Cannot update online status: userId is null or user is not a driver',
      );
      return;
    }

    debugPrint('Updating online status for driver $_userId to: $isOnline');

    try {
      Map<String, dynamic> statusData = {
        'userId': _userId,
        'isOnline': isOnline,
        'isLocationVisible': isOnline ? _isLocationVisible : false,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Add PUV type and icon type if available
      if (_selectedPuvType != null) {
        statusData['puvType'] = _selectedPuvType;
        statusData['iconType'] = _selectedPuvType!.toLowerCase();
      }

      // Add driver name from user document
      try {
        final userDoc = await _firestore.collection('users').doc(_userId).get();
        if (userDoc.exists) {
          statusData['driverName'] = userDoc.data()?['displayName'] ?? 'Driver';

          // Add photo URL if available
          if (userDoc.data()?['photoURL'] != null) {
            statusData['photoUrl'] = userDoc.data()?['photoURL'];
          }
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
      }

      // Log the data being sent to Firestore
      debugPrint('Sending online status data to Firestore:');
      statusData.forEach((key, value) {
        debugPrint('  $key: $value');
      });

      // Update the document in Firestore
      await _firestore
          .collection('driver_locations')
          .doc(_userId)
          .set(statusData, SetOptions(merge: true));

      debugPrint('Online status successfully updated in Firestore');

      // If going online, force a location update to ensure all fields are updated
      if (isOnline) {
        debugPrint('Getting current position for location update...');
        final position = await Geolocator.getCurrentPosition();
        await _updateLocation(position);
      }
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  // Set the selected PUV type for the user
  Future<void> updateSelectedPuvType(String? puvType) async {
    debugPrint('Updating selected PUV type to: $puvType');
    _selectedPuvType = puvType;

    // Update the location data with the new PUV type
    if (_userId != null) {
      try {
        String collection =
            _userRole == 'driver' ? 'driver_locations' : 'commuter_locations';
        debugPrint('Using collection: $collection for user $_userId');

        Map<String, dynamic> updateData = {
          'selectedPuvType': puvType,
          'puvType': puvType, // For backward compatibility with existing code
        };

        // Add iconType for drivers (important for map display)
        if (_userRole == 'driver' && puvType != null) {
          updateData['iconType'] = puvType.toLowerCase();
          debugPrint('Added iconType: ${puvType.toLowerCase()}');

          // Update the background service with the new PUV type
          try {
            await BackgroundLocationService.updatePuvType(puvType);
            debugPrint('Background service PUV type updated to: $puvType');
          } catch (e) {
            debugPrint('Error updating background service PUV type: $e');
          }
        }

        // Log the data being sent to Firestore
        debugPrint('Sending PUV type data to Firestore:');
        updateData.forEach((key, value) {
          debugPrint('  $key: $value');
        });

        // Use set with merge option instead of update to handle cases where the document doesn't exist yet
        await _firestore
            .collection(collection)
            .doc(_userId)
            .set(updateData, SetOptions(merge: true));

        debugPrint('PUV type successfully updated in Firestore');

        // Force a location update to ensure all fields are updated
        debugPrint('Getting current position for location update...');
        final position = await Geolocator.getCurrentPosition();
        await _updateLocation(position);
      } catch (e) {
        debugPrint('Error updating PUV type: $e');
      }
    } else {
      debugPrint('Cannot update PUV type: userId is null');
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
        // Use set with merge option instead of update to handle cases where the document doesn't exist yet
        await _firestore.collection('driver_locations').doc(_userId).set({
          'vehicleId': vehicleId,
          'routeId': routeId,
        }, SetOptions(merge: true));

        // Fetch and update vehicle details
        if (vehicleId != null) {
          final position = await Geolocator.getCurrentPosition();
          await _updateLocation(position);
        }
      } catch (e) {
        debugPrint('Error updating driver vehicle info: $e');
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
      // Debug print to check if we're querying with the correct PUV type
      debugPrint('Querying commuters with PUV type: $puvType');
      query = query.where('selectedPuvType', isEqualTo: puvType);
    } else {
      // If no PUV type specified, still show all commuters for debugging
      debugPrint('No PUV type specified, showing all commuters');
    }

    // We'll filter by distance client-side
    return query.snapshots().map((snapshot) {
      // Debug print to check if we're getting any commuters from Firestore
      debugPrint('Found ${snapshot.docs.length} commuters in Firestore');

      final commuters =
          snapshot.docs
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

      // Debug print to check how many commuters are within the radius
      debugPrint(
        'Found ${commuters.length} commuters within ${radiusKm}km radius',
      );
      return commuters;
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
