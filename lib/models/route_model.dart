import 'package:flutter/material.dart' show Color;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class representing a PUV route
class PUVRoute {
  /// Unique identifier for the route
  final String id;

  /// The display name of the route (e.g., "R2 - Carmen to Divisoria")
  final String name;

  /// A brief description of the route
  final String description;

  /// The type of PUV that services this route (e.g., "Jeepney", "Bus")
  final String puvType;

  /// The route number/code (e.g., "R2", "R10")
  final String routeCode;

  /// Ordered list of waypoints that make up the route's path
  final List<LatLng> waypoints;

  /// Starting point location name
  final String startPointName;

  /// Ending point location name
  final String endPointName;

  /// Estimated travel time in minutes
  final int estimatedTravelTime;

  /// Fare price in PHP
  final double farePrice;

  /// Color for the route display (stored as integer)
  final int colorValue;

  /// Whether this route is active (available for commuters)
  final bool isActive;

  /// Constructor
  PUVRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.puvType,
    required this.routeCode,
    required this.waypoints,
    required this.startPointName,
    required this.endPointName,
    required this.estimatedTravelTime,
    required this.farePrice,
    required this.colorValue,
    this.isActive = true,
  });

  /// Get the color for display
  Color get color => Color(colorValue);

  /// Create a route from a Firebase document
  factory PUVRoute.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert the GeoPoint list to LatLng list
    final List<dynamic> waypointData = data['waypoints'] ?? [];
    final List<LatLng> routeWaypoints =
        waypointData.map((point) {
          if (point is GeoPoint) {
            return LatLng(point.latitude, point.longitude);
          } else if (point is Map<String, dynamic>) {
            return LatLng(point['latitude'], point['longitude']);
          }
          // Default fallback
          return const LatLng(0, 0);
        }).toList();

    // Normalize PUV type to ensure consistent capitalization
    String puvType = data['puvType'] ?? 'Jeepney';
    // Capitalize first letter and make rest lowercase
    if (puvType.isNotEmpty) {
      puvType = puvType[0].toUpperCase() + puvType.substring(1).toLowerCase();
    }

    return PUVRoute(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Route',
      description: data['description'] ?? '',
      puvType: puvType, // Use normalized PUV type
      routeCode: data['routeCode'] ?? '',
      waypoints: routeWaypoints,
      startPointName: data['startPointName'] ?? 'Start',
      endPointName: data['endPointName'] ?? 'End',
      estimatedTravelTime: data['estimatedTravelTime'] ?? 0,
      farePrice: (data['farePrice'] ?? 0).toDouble(),
      colorValue: data['colorValue'] ?? 0xFFFF8800, // Default amber color
      isActive: data['isActive'] ?? true,
    );
  }

  /// Convert route to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    // Convert the LatLng list to GeoPoint list for Firestore
    final List<Map<String, double>> firestoreWaypoints =
        waypoints
            .map(
              (point) => {
                'latitude': point.latitude,
                'longitude': point.longitude,
              },
            )
            .toList();

    // Normalize PUV type to ensure consistent capitalization
    String normalizedPuvType = puvType;
    if (normalizedPuvType.isNotEmpty) {
      normalizedPuvType =
          normalizedPuvType[0].toUpperCase() +
          normalizedPuvType.substring(1).toLowerCase();
    }

    return {
      'name': name,
      'description': description,
      'puvType': normalizedPuvType, // Use normalized PUV type
      'routeCode': routeCode,
      'waypoints': firestoreWaypoints,
      'startPointName': startPointName,
      'endPointName': endPointName,
      'estimatedTravelTime': estimatedTravelTime,
      'farePrice': farePrice,
      'colorValue': colorValue,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
