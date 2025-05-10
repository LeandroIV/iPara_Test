import 'package:cloud_firestore/cloud_firestore.dart';
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
  });

  /// Create a DriverLocation from a Firestore document
  factory DriverLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Extract the GeoPoint and convert to LatLng
    final GeoPoint? geoPoint = data['location'] as GeoPoint?;
    final LatLng location = geoPoint != null 
        ? LatLng(geoPoint.latitude, geoPoint.longitude)
        : const LatLng(0, 0);
    
    // Extract the timestamp and convert to DateTime
    final Timestamp? timestamp = data['lastUpdated'] as Timestamp?;
    final DateTime lastUpdated = timestamp != null 
        ? timestamp.toDate() 
        : DateTime.now();
    
    return DriverLocation(
      userId: data['userId'] ?? '',
      location: location,
      heading: (data['heading'] ?? 0).toDouble(),
      speed: (data['speed'] ?? 0).toDouble(),
      isLocationVisible: data['isLocationVisible'] ?? false,
      isOnline: data['isOnline'] ?? false,
      lastUpdated: lastUpdated,
      puvType: data['puvType'] ?? 'Unknown',
      routeId: data['routeId'],
      vehicleId: data['vehicleId'],
      plateNumber: data['plateNumber'],
      capacity: data['capacity'],
      driverName: data['driverName'],
      rating: data['rating']?.toDouble(),
      status: data['status'],
      etaMinutes: data['etaMinutes'],
    );
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
    };
  }
}
