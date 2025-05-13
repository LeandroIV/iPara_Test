import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_request_model.dart';

/// Service for detecting proximity between users and handling automatic ride state transitions
class ProximityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Proximity thresholds in meters
  static const double _boardingProximityThreshold =
      50.0; // 50 meters for boarding notification
  static const double _destinationProximityThreshold =
      100.0; // 100 meters for destination approach

  // Timers for periodic checks
  Timer? _proximityCheckTimer;

  /// Start monitoring proximity for a specific ride request
  void startProximityMonitoring(String rideRequestId) {
    // Cancel any existing timer
    _proximityCheckTimer?.cancel();

    // Start periodic proximity checks (every 10 seconds)
    _proximityCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkProximity(rideRequestId),
    );

    debugPrint('Started proximity monitoring for ride request: $rideRequestId');
  }

  /// Stop monitoring proximity
  void stopProximityMonitoring() {
    _proximityCheckTimer?.cancel();
    _proximityCheckTimer = null;
    debugPrint('Stopped proximity monitoring');
  }

  /// Check proximity between driver and commuter for a ride request
  Future<void> _checkProximity(String rideRequestId) async {
    try {
      // Get the ride request
      final rideRequestDoc =
          await _firestore.collection('ride_requests').doc(rideRequestId).get();

      if (!rideRequestDoc.exists) {
        debugPrint(
          'Ride request no longer exists, stopping proximity monitoring',
        );
        stopProximityMonitoring();
        return;
      }

      final rideRequest = RideRequest.fromFirestore(rideRequestDoc);

      // Only check proximity for accepted rides that haven't started yet
      if (rideRequest.status != RideRequestStatus.accepted) {
        return;
      }

      // Get current locations
      final driverLocation = rideRequest.driverLocation;
      final commuterLocation = rideRequest.commuterLocation;

      // Calculate distance between driver and commuter
      final distanceInMeters = Geolocator.distanceBetween(
        driverLocation.latitude,
        driverLocation.longitude,
        commuterLocation.latitude,
        commuterLocation.longitude,
      );

      debugPrint(
        'Distance between driver and commuter: ${distanceInMeters.toStringAsFixed(2)} meters',
      );

      // Check if driver is within boarding proximity threshold
      if (distanceInMeters <= _boardingProximityThreshold) {
        // Update ride status to boarding
        await _updateRideStatus(rideRequestId, RideRequestStatus.boarding);
        debugPrint(
          'Driver is within boarding proximity, updating status to boarding',
        );
      }
    } catch (e) {
      debugPrint('Error checking proximity: $e');
    }
  }

  /// Check if a driver is near a destination
  Future<bool> isNearDestination({
    required LatLng currentLocation,
    required LatLng destinationLocation,
  }) async {
    final distanceInMeters = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      destinationLocation.latitude,
      destinationLocation.longitude,
    );

    return distanceInMeters <= _destinationProximityThreshold;
  }

  /// Update the status of a ride request
  Future<void> _updateRideStatus(
    String rideRequestId,
    RideRequestStatus status,
  ) async {
    try {
      await _firestore.collection('ride_requests').doc(rideRequestId).update({
        'status': status.index,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating ride status: $e');
    }
  }

  /// Calculate distance between two points
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Dispose resources
  void dispose() {
    stopProximityMonitoring();
  }
}
