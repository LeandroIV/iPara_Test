import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Model class representing a commuter's location data
class CommuterLocation {
  /// The commuter's user ID
  final String userId;
  
  /// The commuter's current location
  final LatLng location;
  
  /// Whether the commuter's location is visible to drivers
  final bool isLocationVisible;
  
  /// The timestamp of the last location update
  final DateTime lastUpdated;
  
  /// The selected PUV type the commuter is looking for
  final String? selectedPuvType;
  
  /// The commuter's name or username
  final String? userName;
  
  /// The commuter's destination (if set)
  final LatLng? destination;
  
  /// The commuter's destination name (if set)
  final String? destinationName;

  /// Constructor
  CommuterLocation({
    required this.userId,
    required this.location,
    required this.isLocationVisible,
    required this.lastUpdated,
    this.selectedPuvType,
    this.userName,
    this.destination,
    this.destinationName,
  });

  /// Create a CommuterLocation from a Firestore document
  factory CommuterLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Extract the GeoPoint and convert to LatLng
    final GeoPoint? geoPoint = data['location'] as GeoPoint?;
    final LatLng location = geoPoint != null 
        ? LatLng(geoPoint.latitude, geoPoint.longitude)
        : const LatLng(0, 0);
    
    // Extract the destination GeoPoint if it exists
    LatLng? destination;
    if (data['destination'] != null) {
      final GeoPoint destPoint = data['destination'] as GeoPoint;
      destination = LatLng(destPoint.latitude, destPoint.longitude);
    }
    
    // Extract the timestamp and convert to DateTime
    final Timestamp? timestamp = data['lastUpdated'] as Timestamp?;
    final DateTime lastUpdated = timestamp != null 
        ? timestamp.toDate() 
        : DateTime.now();
    
    return CommuterLocation(
      userId: data['userId'] ?? '',
      location: location,
      isLocationVisible: data['isLocationVisible'] ?? false,
      lastUpdated: lastUpdated,
      selectedPuvType: data['selectedPuvType'],
      userName: data['userName'],
      destination: destination,
      destinationName: data['destinationName'],
    );
  }

  /// Convert to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'userId': userId,
      'location': GeoPoint(location.latitude, location.longitude),
      'isLocationVisible': isLocationVisible,
      'lastUpdated': FieldValue.serverTimestamp(),
      'selectedPuvType': selectedPuvType,
      'userName': userName,
    };
    
    // Add destination if it exists
    if (destination != null) {
      data['destination'] = GeoPoint(destination!.latitude, destination!.longitude);
      data['destinationName'] = destinationName;
    }
    
    return data;
  }
}
