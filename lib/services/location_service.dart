import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<Position>? _positionStream;
  String? _userId;
  String? _userRole;
  bool _isLocationVisible = true;

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

      await _firestore.collection(collection).doc(_userId).set({
        'userId': _userId,
        'location': location,
        'heading': position.heading,
        'speed': position.speed,
        'isLocationVisible': _isLocationVisible,
        'lastUpdated': timestamp,
        'deviceInfo': {'platform': 'mobile', 'accuracy': position.accuracy},
      }, SetOptions(merge: true));
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

  Stream<QuerySnapshot> getNearbyDrivers({
    required GeoPoint center,
    double radiusKm = 5.0,
    String? puvType,
  }) {
    // This is a simplified version that will work for demo purposes

    // Get all online drivers
    Query query = _firestore
        .collection('driver_locations')
        .where('isOnline', isEqualTo: true)
        .where('isLocationVisible', isEqualTo: true);

    // Filter by PUV type if specified
    if (puvType != null) {
      query = query.where('vehicleType', isEqualTo: puvType);
    }

    // We'll filter by distance client-side since Firestore doesn't support geoqueries directly
    return query.snapshots();
  }

  Future<List<DocumentSnapshot>> getNearbyDriversOnce({
    required GeoPoint center,
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
      query = query.where('vehicleType', isEqualTo: puvType);
    }

    final snapshot = await query.get();
    return snapshot.docs;
  }

  // Clean up resources
  void dispose() {
    _positionStream?.cancel();
  }
}
