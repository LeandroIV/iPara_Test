import 'package:google_maps_flutter/google_maps_flutter.dart';

class PUVLocation {
  final String puvId;
  final String routeNumber;
  final LatLng location;
  final double speed;
  final double bearing;
  final DateTime timestamp;
  final int estimatedArrivalMinutes;

  PUVLocation({
    required this.puvId,
    required this.routeNumber,
    required this.location,
    required this.speed,
    required this.bearing,
    required this.timestamp,
    required this.estimatedArrivalMinutes,
  });

  factory PUVLocation.fromMap(Map<String, dynamic> map) {
    return PUVLocation(
      puvId: map['puvId'],
      routeNumber: map['routeNumber'],
      location: LatLng(map['latitude'], map['longitude']),
      speed: map['speed'].toDouble(),
      bearing: map['bearing'].toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
      estimatedArrivalMinutes: map['estimatedArrivalMinutes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'puvId': puvId,
      'routeNumber': routeNumber,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'speed': speed,
      'bearing': bearing,
      'timestamp': timestamp.toIso8601String(),
      'estimatedArrivalMinutes': estimatedArrivalMinutes,
    };
  }
}
