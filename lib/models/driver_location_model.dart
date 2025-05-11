import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Model class representing a driver's location data
class DriverLocation {
  /// The driver's user ID
  final String userId;

  /// The driver's current location
  final LatLng location;

  /// The driver's current heading (direction) in degrees
  final double heading;

  /// The driver's current speed in meters per second
  final double speed;

  /// Whether the driver's location is visible to commuters
  final bool isLocationVisible;

  /// Whether the driver is currently online
  final bool isOnline;

  /// The timestamp of the last location update
  final DateTime lastUpdated;

  /// The type of PUV the driver is operating
  final String puvType;

  /// The route ID the driver is currently on
  final String? routeId;

  /// The vehicle ID the driver is currently operating
  final String? vehicleId;

  /// The vehicle's plate number
  final String? plateNumber;

  /// The vehicle's current capacity (number of passengers / total capacity)
  final String? capacity;

  /// The driver's name
  final String? driverName;

  /// The driver's rating (0-5)
  final double? rating;

  /// The driver's status (e.g., "Available", "Full", "On Break")
  final String? status;

  /// Estimated time of arrival in minutes (if applicable)
  final int? etaMinutes;

  /// Whether this is mock data
  final bool isMockData;

  /// The icon type to use for this driver
  final String? iconType;

  /// Constructor
  DriverLocation({
    required this.userId,
    required this.location,
    required this.heading,
    required this.speed,
    required this.isLocationVisible,
    required this.isOnline,
    required this.lastUpdated,
    required this.puvType,
    this.routeId,
    this.vehicleId,
    this.plateNumber,
    this.capacity,
    this.driverName,
    this.rating,
    this.status,
    this.etaMinutes,
    this.isMockData = false,
    this.iconType,
  });

  /// Create a DriverLocation from a Firestore document
  factory DriverLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Extract the GeoPoint and convert to LatLng
    final GeoPoint? geoPoint = data['location'] as GeoPoint?;
    final LatLng location =
        geoPoint != null
            ? LatLng(geoPoint.latitude, geoPoint.longitude)
            : const LatLng(0, 0);

    // Extract the timestamp and convert to DateTime
    final Timestamp? timestamp = data['lastUpdated'] as Timestamp?;
    final DateTime lastUpdated =
        timestamp != null ? timestamp.toDate() : DateTime.now();

    return DriverLocation(
      userId: data['userId'] ?? '',
      location: location,
      heading: _parseDouble(data['heading'], 0),
      speed: _parseDouble(data['speed'], 0),
      isLocationVisible: data['isLocationVisible'] ?? false,
      isOnline: data['isOnline'] ?? false,
      lastUpdated: lastUpdated,
      puvType: data['puvType'] ?? 'Unknown',
      routeId: data['routeId'],
      vehicleId: data['vehicleId'],
      plateNumber: data['plateNumber'],
      capacity: data['capacity'],
      driverName: data['driverName'],
      rating: _parseRating(data['rating']),
      status: data['status'],
      etaMinutes: data['etaMinutes'] is int ? data['etaMinutes'] : null,
      isMockData: data['isMockData'] ?? false,
      iconType: data['iconType'],
    );
  }

  /// Helper method to parse a double value from different types with a default value
  static double _parseDouble(dynamic value, double defaultValue) {
    if (value == null) {
      return defaultValue;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        debugPrint('Error parsing double value: $e');
        return defaultValue;
      }
    }

    // For any other type, return the default value
    return defaultValue;
  }

  /// Helper method to parse rating value from different types
  static double? _parseRating(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        debugPrint('Error parsing rating value: $e');
        return null;
      }
    }

    // For any other type, return null
    return null;
  }

  /// Convert to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'location': GeoPoint(location.latitude, location.longitude),
      'heading': heading,
      'speed': speed,
      'isLocationVisible': isLocationVisible,
      'isOnline': isOnline,
      'lastUpdated': FieldValue.serverTimestamp(),
      'puvType': puvType,
      'routeId': routeId,
      'vehicleId': vehicleId,
      'plateNumber': plateNumber,
      'capacity': capacity,
      'driverName': driverName,
      'rating': rating,
      'status': status,
      'etaMinutes': etaMinutes,
      'isMockData': isMockData,
      'iconType':
          iconType ??
          puvType.toLowerCase(), // Default to puvType if iconType is null
    };
  }
}
