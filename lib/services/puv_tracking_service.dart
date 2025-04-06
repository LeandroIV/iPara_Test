import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/puv_location.dart';

class PUVTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _puvLocations = StreamController<List<PUVLocation>>.broadcast();

  Stream<List<PUVLocation>> get puvLocations => _puvLocations.stream;

  // Subscribe to real-time PUV location updates
  void subscribeToPUVLocations() {
    _firestore.collection('puv_locations').snapshots().listen((snapshot) {
      final locations =
          snapshot.docs.map((doc) => PUVLocation.fromMap(doc.data())).toList();
      _puvLocations.add(locations);
    });
  }

  // Update PUV location
  Future<void> updatePUVLocation(PUVLocation location) async {
    await _firestore
        .collection('puv_locations')
        .doc(location.puvId)
        .set(location.toMap());
  }

  // Calculate ETA for a specific PUV
  Future<int> calculateETA(LatLng userLocation, String puvId) async {
    final puvDoc =
        await _firestore.collection('puv_locations').doc(puvId).get();

    if (!puvDoc.exists) return -1;

    final puvLocation = PUVLocation.fromMap(puvDoc.data()!);

    // Simple ETA calculation based on distance and average speed
    // You might want to use Google Maps Distance Matrix API for more accurate results
    final distance = _calculateDistance(
      userLocation.latitude,
      userLocation.longitude,
      puvLocation.location.latitude,
      puvLocation.location.longitude,
    );

    // Assuming average speed of 30 km/h in city traffic
    final averageSpeed = 30.0; // km/h
    final etaMinutes = (distance / averageSpeed) * 60;

    return etaMinutes.round();
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth's radius in kilometers
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * (3.141592653589793 / 180);
  }

  void dispose() {
    _puvLocations.close();
  }
}
