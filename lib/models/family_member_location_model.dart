import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Model class representing a family member's location data
class FamilyMemberLocation {
  /// The family member's user ID
  final String userId;

  /// The family member's current location
  final LatLng location;

  /// The family group ID this member belongs to
  final String groupId;

  /// Whether the family member's location is visible to other members
  final bool isVisible;

  /// The timestamp of the last location update
  final DateTime lastUpdated;

  /// The family member's name or username
  final String? displayName;

  /// The family member's photo URL
  final String? photoUrl;

  /// The family member's role (commuter, driver, operator)
  final String? userRole;

  /// Constructor
  FamilyMemberLocation({
    required this.userId,
    required this.location,
    required this.groupId,
    required this.isVisible,
    required this.lastUpdated,
    this.displayName,
    this.photoUrl,
    this.userRole,
  });

  /// Create a FamilyMemberLocation from a Firestore document
  factory FamilyMemberLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Extract the GeoPoint and convert to LatLng
    final GeoPoint? geoPoint = data['location'] as GeoPoint?;
    final LatLng location = geoPoint != null
        ? LatLng(geoPoint.latitude, geoPoint.longitude)
        : const LatLng(0, 0);

    // Extract the timestamp and convert to DateTime
    final Timestamp? timestamp = data['lastUpdated'] as Timestamp?;
    final DateTime lastUpdated =
        timestamp != null ? timestamp.toDate() : DateTime.now();

    return FamilyMemberLocation(
      userId: data['userId'] ?? '',
      location: location,
      groupId: data['groupId'] ?? '',
      isVisible: data['isVisible'] ?? false,
      lastUpdated: lastUpdated,
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      userRole: data['userRole'],
    );
  }

  /// Convert to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'location': GeoPoint(location.latitude, location.longitude),
      'groupId': groupId,
      'isVisible': isVisible,
      'lastUpdated': FieldValue.serverTimestamp(),
      'displayName': displayName,
      'photoUrl': photoUrl,
      'userRole': userRole,
    };
  }
}
