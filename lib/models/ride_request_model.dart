import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Status of a ride request
enum RideRequestStatus {
  pending, // Initial state when commuter requests a ride
  accepted, // Driver has accepted the request
  boarding, // Driver has arrived at pickup location, waiting for commuter to board
  inTransit, // Commuter has boarded, ride is in progress
  arrived, // Driver has arrived at destination
  completed, // Ride is completed (but may not be paid yet)
  paid, // Payment has been completed
  rejected, // Driver rejected the request
  cancelled, // Request was cancelled by either party
}

/// Extension to provide display names for ride request statuses
extension RideRequestStatusExtension on RideRequestStatus {
  String get displayName {
    switch (this) {
      case RideRequestStatus.pending:
        return 'Pending';
      case RideRequestStatus.accepted:
        return 'Accepted';
      case RideRequestStatus.boarding:
        return 'Boarding';
      case RideRequestStatus.inTransit:
        return 'In Transit';
      case RideRequestStatus.arrived:
        return 'Arrived';
      case RideRequestStatus.completed:
        return 'Completed';
      case RideRequestStatus.paid:
        return 'Paid';
      case RideRequestStatus.rejected:
        return 'Rejected';
      case RideRequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get description {
    switch (this) {
      case RideRequestStatus.pending:
        return 'Waiting for driver response';
      case RideRequestStatus.accepted:
        return 'Driver is on the way';
      case RideRequestStatus.boarding:
        return 'Driver has arrived, please board the vehicle';
      case RideRequestStatus.inTransit:
        return 'You are on your way to the destination';
      case RideRequestStatus.arrived:
        return 'You have arrived at your destination';
      case RideRequestStatus.completed:
        return 'Ride completed, please proceed to payment';
      case RideRequestStatus.paid:
        return 'Payment completed, thank you for riding';
      case RideRequestStatus.rejected:
        return 'Driver rejected the request';
      case RideRequestStatus.cancelled:
        return 'Request was cancelled';
    }
  }

  bool get isActive {
    return this == RideRequestStatus.accepted ||
        this == RideRequestStatus.boarding ||
        this == RideRequestStatus.inTransit ||
        this == RideRequestStatus.arrived;
  }

  bool get requiresPayment {
    return this == RideRequestStatus.completed;
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

  /// Location of the commuter (pickup location)
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

  /// Destination location (may be null if not specified)
  final LatLng? destinationLocation;

  /// Destination name/address (may be null if not specified)
  final String? destinationName;

  /// Route ID if following a predefined route
  final String? routeId;

  /// Timestamp when the ride started (when status changed to inTransit)
  final DateTime? rideStartTime;

  /// Timestamp when the ride ended (when status changed to arrived)
  final DateTime? rideEndTime;

  /// Total distance traveled during the ride in kilometers
  final double? totalDistanceTraveled;

  /// Calculated fare amount based on distance and passenger type
  final double? fareAmount;

  /// Tip amount added by the commuter
  final double? tipAmount;

  /// Total amount paid (fare + tip)
  final double? totalAmount;

  /// Passenger type for fare calculation (regular, student, senior)
  final String? passengerType;

  /// Payment method ID if payment has been made
  final String? paymentMethodId;

  /// Payment transaction ID if payment has been made
  final String? paymentTransactionId;

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
    this.destinationLocation,
    this.destinationName,
    this.routeId,
    this.rideStartTime,
    this.rideEndTime,
    this.totalDistanceTraveled,
    this.fareAmount,
    this.tipAmount,
    this.totalAmount,
    this.passengerType,
    this.paymentMethodId,
    this.paymentTransactionId,
  });

  /// Create a RideRequest from a Firestore document
  factory RideRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Extract commuter location
    final GeoPoint? commuterGeoPoint = data['commuterLocation'] as GeoPoint?;
    final LatLng commuterLocation =
        commuterGeoPoint != null
            ? LatLng(commuterGeoPoint.latitude, commuterGeoPoint.longitude)
            : const LatLng(0, 0);

    // Extract driver location
    final GeoPoint? driverGeoPoint = data['driverLocation'] as GeoPoint?;
    final LatLng driverLocation =
        driverGeoPoint != null
            ? LatLng(driverGeoPoint.latitude, driverGeoPoint.longitude)
            : const LatLng(0, 0);

    // Extract timestamps
    final Timestamp? createdTimestamp = data['createdAt'] as Timestamp?;
    final DateTime createdAt =
        createdTimestamp != null ? createdTimestamp.toDate() : DateTime.now();

    final Timestamp? updatedTimestamp = data['updatedAt'] as Timestamp?;
    final DateTime updatedAt =
        updatedTimestamp != null ? updatedTimestamp.toDate() : DateTime.now();

    // Parse status
    final int statusIndex = data['status'] as int? ?? 0;
    final RideRequestStatus status = RideRequestStatus.values[statusIndex];

    // Extract destination location if available
    LatLng? destinationLocation;
    if (data['destinationLocation'] != null) {
      final GeoPoint destGeoPoint = data['destinationLocation'] as GeoPoint;
      destinationLocation = LatLng(
        destGeoPoint.latitude,
        destGeoPoint.longitude,
      );
    }

    // Extract ride start/end times if available
    DateTime? rideStartTime;
    if (data['rideStartTime'] != null) {
      final Timestamp startTimestamp = data['rideStartTime'] as Timestamp;
      rideStartTime = startTimestamp.toDate();
    }

    DateTime? rideEndTime;
    if (data['rideEndTime'] != null) {
      final Timestamp endTimestamp = data['rideEndTime'] as Timestamp;
      rideEndTime = endTimestamp.toDate();
    }

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
      destinationLocation: destinationLocation,
      destinationName: data['destinationName'],
      routeId: data['routeId'],
      rideStartTime: rideStartTime,
      rideEndTime: rideEndTime,
      totalDistanceTraveled:
          (data['totalDistanceTraveled'] as num?)?.toDouble(),
      fareAmount: (data['fareAmount'] as num?)?.toDouble(),
      tipAmount: (data['tipAmount'] as num?)?.toDouble(),
      totalAmount: (data['totalAmount'] as num?)?.toDouble(),
      passengerType: data['passengerType'],
      paymentMethodId: data['paymentMethodId'],
      paymentTransactionId: data['paymentTransactionId'],
    );
  }

  /// Convert to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
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

    // Add optional fields if they are not null
    if (destinationLocation != null) {
      data['destinationLocation'] = GeoPoint(
        destinationLocation!.latitude,
        destinationLocation!.longitude,
      );
    }

    if (destinationName != null) {
      data['destinationName'] = destinationName;
    }

    if (routeId != null) {
      data['routeId'] = routeId;
    }

    if (rideStartTime != null) {
      data['rideStartTime'] = Timestamp.fromDate(rideStartTime!);
    }

    if (rideEndTime != null) {
      data['rideEndTime'] = Timestamp.fromDate(rideEndTime!);
    }

    if (totalDistanceTraveled != null) {
      data['totalDistanceTraveled'] = totalDistanceTraveled;
    }

    if (fareAmount != null) {
      data['fareAmount'] = fareAmount;
    }

    if (tipAmount != null) {
      data['tipAmount'] = tipAmount;
    }

    if (totalAmount != null) {
      data['totalAmount'] = totalAmount;
    }

    if (passengerType != null) {
      data['passengerType'] = passengerType;
    }

    if (paymentMethodId != null) {
      data['paymentMethodId'] = paymentMethodId;
    }

    if (paymentTransactionId != null) {
      data['paymentTransactionId'] = paymentTransactionId;
    }

    return data;
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
    LatLng? destinationLocation,
    String? destinationName,
    String? routeId,
    DateTime? rideStartTime,
    DateTime? rideEndTime,
    double? totalDistanceTraveled,
    double? fareAmount,
    double? tipAmount,
    double? totalAmount,
    String? passengerType,
    String? paymentMethodId,
    String? paymentTransactionId,
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
      destinationLocation: destinationLocation ?? this.destinationLocation,
      destinationName: destinationName ?? this.destinationName,
      routeId: routeId ?? this.routeId,
      rideStartTime: rideStartTime ?? this.rideStartTime,
      rideEndTime: rideEndTime ?? this.rideEndTime,
      totalDistanceTraveled:
          totalDistanceTraveled ?? this.totalDistanceTraveled,
      fareAmount: fareAmount ?? this.fareAmount,
      tipAmount: tipAmount ?? this.tipAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      passengerType: passengerType ?? this.passengerType,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      paymentTransactionId: paymentTransactionId ?? this.paymentTransactionId,
    );
  }
}
