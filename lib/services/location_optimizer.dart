import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationOptimizer {
  final List<Position> _locationBuffer = [];
  Timer? _batchUpdateTimer;
  final Function(Position, {double? avgSpeed}) _updateFunction;

  LocationOptimizer({
    required Function(Position, {double? avgSpeed}) updateFunction,
  }) : _updateFunction = updateFunction;

  void start() {
    _batchUpdateTimer?.cancel();
    _batchUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_locationBuffer.isNotEmpty) {
        _sendBatchUpdate();
      }
    });
  }

  void stop() {
    _batchUpdateTimer?.cancel();
    _batchUpdateTimer = null;

    // Send any remaining data
    if (_locationBuffer.isNotEmpty) {
      _sendBatchUpdate();
    }
  }

  void bufferLocationUpdate(Position position) {
    _locationBuffer.add(position);

    // If buffer gets too large, send immediately
    if (_locationBuffer.length >= 5) {
      _sendBatchUpdate();
    }
  }

  Future<void> _sendBatchUpdate() async {
    if (_locationBuffer.isEmpty) return;

    // Use the most recent position for the update
    final latestPosition = _locationBuffer.last;

    // Calculate average speed if we have more than one position
    double? avgSpeed;
    if (_locationBuffer.length > 1) {
      avgSpeed =
          _locationBuffer.map((p) => p.speed).reduce((a, b) => a + b) /
          _locationBuffer.length;
    }

    // Update Firestore with the latest position but averaged data
    _updateFunction(latestPosition, avgSpeed: avgSpeed);

    // Clear the buffer
    _locationBuffer.clear();
  }

  // Static method to get optimal location settings based on user activity
  static LocationSettings getOptimalSettings({bool highAccuracy = false}) {
    if (highAccuracy) {
      // High accuracy for active navigation or when accuracy is critical
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );
    } else {
      // Battery-saving mode for background tracking
      return const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 30, // Only update when moved 30 meters
      );
    }
  }
}
