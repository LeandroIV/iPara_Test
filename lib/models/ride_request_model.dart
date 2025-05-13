import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Status of a ride request
enum RideRequestStatus {
  pending,
  accepted,
  rejected,
  cancelled,
  completed
}

/// Extension to provide display names for ride request statuses
extension RideRequestStatusExtension on RideRequestStatus {
  String get displayName {
    switch (this) {
      case RideRequestStatus.pending:
        return 'Pending';
      case RideRequestStatus.accepted:
        return 'Accepted';
      case RideRequestStatus.rejected:
        return 'Rejected';
      case RideRequestStatus.cancelled:
        return 'Cancelled';
      case RideRequestStatus.completed:
        return 'Completed';
    }
  }

  String get description {
    switch (this) {
      case RideRequestStatus.pending:
        return 'Waiting for driver response';
      case RideRequestStatus.accepted:
        return 'Driver is on the way';
      case RideRequestStatus.rejected:
        return 'Driver rejected the request';
      case RideRequestStatus.cancelled:
        return 'Request was cancelled';
      case RideRequestStatus.completed:
        return 'Ride completed';
    }
  }
}

/// Model class representing a ride request from a commuter to a driver
class RideRequest {
  /// Unique identifier for the ride request
  final String id;

  /// ID of the commuter who made the request
  final String commuterId;

  /// Name of the commuter
  final String? commuterName;

  /// Location of the commuter
  final LatLng commuterLocation;

  /// ID of the driver who received the request
  final String driverId;

  /// Name of the driver
  final String? driverName;

  /// Location of the driver
  final LatLng driverLocation;

  /// Type of PUV requested
  final String puvType;

  /// Distance between commuter and driver in kilometers
  final double distanceKm;

  /// Estimated time of arrival in minutes
  final int etaMinutes;

  /// Status of the request
  final RideRequestStatus status;

  /// Timestamp when the request was created
  final DateTime createdAt;

  /// Timestamp when the request was last updated
  final DateTime updatedAt;

  /// Constructor
  RideRequest({
    required this.id,
    required this.commuterId,
    this.commuterName,
    required this.commuterLocation,
    required this.driverId,
    this.driverName,
    required this.driverLocation,
    required this.puvType,
    required this.distanceKm,
    required this.etaMinutes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a RideRequest from a Firestore document
  factory RideRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Extract commuter location
    final GeoPoint? commuterGeoPoint = data['commuterLocation'] as GeoPoint?;
    final LatLng commuterLocation = commuterGeoPoint != null
        ? LatLng(commuterGeoPoint.latitude, commuterGeoPoint.longitude)
        : const LatLng(0, 0);

    // Extract driver location
    final GeoPoint? driverGeoPoint = data['driverLocation'] as GeoPoint?;
    final LatLng driverLocation = driverGeoPoint != null
        ? LatLng(driverGeoPoint.latitude, driverGeoPoint.longitude)
        : const LatLng(0, 0);

    // Extract timestamps
    final Timestamp? createdTimestamp = data['createdAt'] as Timestamp?;
    final DateTime createdAt = createdTimestamp != null
        ? createdTimestamp.toDate()
        : DateTime.now();

    final Timestamp? updatedTimestamp = data['updatedAt'] as Timestamp?;
    final DateTime updatedAt = updatedTimestamp != null
        ? updatedTimestamp.toDate()
        : DateTime.now();

    // Parse status
    final int statusIndex = data['status'] as int? ?? 0;
    final RideRequestStatus status = RideRequestStatus.values[statusIndex];

    return RideRequest(
      id: doc.id,
      commuterId: data['commuterId'] ?? '',
      commuterName: data['commuterName'],
      commuterLocation: commuterLocation,
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'],
      driverLocation: driverLocation,
      puvType: data['puvType'] ?? '',
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0.0,
      etaMinutes: data['etaMinutes'] as int? ?? 0,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convert to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'commuterId': commuterId,
      'commuterName': commuterName,
      'commuterLocation': GeoPoint(
        commuterLocation.latitude,
        commuterLocation.longitude,
      ),
      'driverId': driverId,
      'driverName': driverName,
      'driverLocation': GeoPoint(
        driverLocation.latitude,
        driverLocation.longitude,
      ),
      'puvType': puvType,
      'distanceKm': distanceKm,
      'etaMinutes': etaMinutes,
      'status': status.index,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create a copy of this RideRequest with updated fields
  RideRequest copyWith({
    String? id,
    String? commuterId,
    String? commuterName,
    LatLng? commuterLocation,
    String? driverId,
    String? driverName,
    LatLng? driverLocation,
    String? puvType,
    double? distanceKm,
    int? etaMinutes,
    RideRequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RideRequest(
      id: id ?? this.id,
      commuterId: commuterId ?? this.commuterId,
      commuterName: commuterName ?? this.commuterName,
      commuterLocation: commuterLocation ?? this.commuterLocation,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverLocation: driverLocation ?? this.driverLocation,
      puvType: puvType ?? this.puvType,
      distanceKm: distanceKm ?? this.distanceKm,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
