import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import '../services/route_service.dart';
import '../models/route_model.dart';

/// Utility class for generating and uploading mock data to Firestore
class MockDataGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();
  final RouteService _routeService = RouteService();

  /// Generate and upload mock driver locations
  Future<void> generateMockDriverLocations({
    required int count,
    required LatLng center,
    required double radiusKm,
  }) async {
    // Clear existing mock data
    await _clearMockDriverLocations();

    // Get all available routes
    final List<PUVRoute> routes = _routeService.getMockRoutes();

    // Distribute drivers across different PUV types
    final Map<String, int> puvTypeCounts = {
      'Jeepney': (count * 0.6).ceil(), // 60% Jeepneys
      'Bus': (count * 0.15).ceil(), // 15% Buses
      'Multicab': (count * 0.15).ceil(), // 15% Multicabs
      'Motorela': (count * 0.1).ceil(), // 10% Motorelas
    };

    // Ensure we don't exceed the total count
    int totalAssigned = puvTypeCounts.values.fold(
      0,
      (sum, count) => sum + count,
    );
    if (totalAssigned > count) {
      // Adjust the largest category down if needed
      String largestType =
          puvTypeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      puvTypeCounts[largestType] =
          puvTypeCounts[largestType]! - (totalAssigned - count);
    }

    int driverIndex = 0;

    // Generate Jeepney drivers along specific routes
    final List<PUVRoute> jeepneyRoutes =
        routes.where((r) => r.puvType == 'Jeepney').toList();
    if (jeepneyRoutes.isNotEmpty) {
      int jeepneyCount = puvTypeCounts['Jeepney'] ?? 0;
      for (int i = 0; i < jeepneyCount; i++) {
        // Select a route for this jeepney
        final PUVRoute route = jeepneyRoutes[i % jeepneyRoutes.length];

        // Place the driver somewhere along the route
        await _generateMockDriverAlongRoute(
          route: route,
          index: driverIndex++,
          puvType: 'Jeepney',
        );
      }
    }

    // Generate other PUV types
    for (final entry in puvTypeCounts.entries) {
      if (entry.key == 'Jeepney') continue; // Already handled

      for (int i = 0; i < entry.value; i++) {
        // For non-jeepney types, place them around the center with some randomness
        await _generateMockDriver(
          center: center,
          radiusKm: radiusKm,
          index: driverIndex++,
          forcePuvType: entry.key,
        );
      }
    }

    // Log the result
    print('Generated $count mock driver locations');
  }

  /// Clear existing mock driver locations
  Future<void> _clearMockDriverLocations() async {
    final QuerySnapshot snapshot =
        await _firestore
            .collection('driver_locations')
            .where('isMockData', isEqualTo: true)
            .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    print('Cleared existing mock driver locations');
  }

  /// Generate a single mock driver
  Future<void> _generateMockDriver({
    required LatLng center,
    required double radiusKm,
    required int index,
    String? forcePuvType,
  }) async {
    // Generate a random location within the radius
    final LatLng location = _generateRandomLocation(center, radiusKm);

    // Generate a random heading (0-360 degrees)
    final double heading = _random.nextDouble() * 360;

    // Generate a random speed (0-60 km/h)
    final double speed = _random.nextDouble() * 16.6; // 16.6 m/s = 60 km/h

    // Select a PUV type (use forced type if provided)
    final String puvType = forcePuvType ?? _getRandomPuvType();

    // Generate a random plate number
    final String plateNumber = _generatePlateNumber(puvType);

    // Generate a random capacity
    final int maxCapacity = _getMaxCapacity(puvType);
    final int currentPassengers = _random.nextInt(maxCapacity + 1);
    final String capacity = '$currentPassengers/$maxCapacity';

    // Generate a random ETA
    final int etaMinutes = 5 + _random.nextInt(26); // 5-30 minutes

    // Generate a random driver name
    final String driverName = _generateDriverName();

    // Generate a random rating (3.0-5.0)
    final double rating = 3.0 + _random.nextDouble() * 2.0;

    // Generate a random status
    final List<String> statuses = ['Available', 'En Route', 'Full', 'On Break'];
    final String status = statuses[_random.nextInt(statuses.length)];

    // Create the mock driver document
    final String docId = 'mock_driver_$index';
    await _firestore.collection('driver_locations').doc(docId).set({
      'userId': docId,
      'location': GeoPoint(location.latitude, location.longitude),
      'heading': heading,
      'speed': speed,
      'isLocationVisible': true,
      'isOnline': true,
      'lastUpdated': FieldValue.serverTimestamp(),
      'puvType': puvType,
      'plateNumber': plateNumber,
      'capacity': capacity,
      'driverName': driverName,
      'rating': rating,
      'status': status,
      'etaMinutes': etaMinutes,
      'isMockData': true,
      'iconType': 'car', // Use car icon for drivers
    });
  }

  /// Generate a mock driver along a specific route
  Future<void> _generateMockDriverAlongRoute({
    required PUVRoute route,
    required int index,
    required String puvType,
  }) async {
    // Get waypoints from the route
    final List<LatLng> waypoints = route.waypoints;
    if (waypoints.isEmpty) return;

    // Select a random position along the route
    final int waypointIndex = _random.nextInt(waypoints.length);
    final LatLng location = waypoints[waypointIndex];

    // Calculate heading based on next waypoint
    double heading = 0;
    if (waypoints.length > 1) {
      final int nextIndex = (waypointIndex + 1) % waypoints.length;
      final LatLng nextPoint = waypoints[nextIndex];
      heading = _calculateHeading(location, nextPoint);
    } else {
      heading = _random.nextDouble() * 360;
    }

    // Generate a random speed (10-40 km/h for vehicles on route)
    final double speed = 2.8 + _random.nextDouble() * 8.3; // 10-40 km/h in m/s

    // Generate a random plate number
    final String plateNumber = _generatePlateNumber(puvType);

    // Generate a random capacity
    final int maxCapacity = _getMaxCapacity(puvType);
    final int currentPassengers = _random.nextInt(maxCapacity + 1);
    final String capacity = '$currentPassengers/$maxCapacity';

    // Generate a random ETA based on route
    final int etaMinutes =
        (route.estimatedTravelTime * _random.nextDouble()).round() + 5;

    // Generate a random driver name
    final String driverName = _generateDriverName();

    // Generate a random rating (3.0-5.0)
    final double rating = 3.0 + _random.nextDouble() * 2.0;

    // Generate a status (more likely to be 'En Route' for route-based drivers)
    final List<String> statuses = [
      'En Route',
      'En Route',
      'En Route',
      'Available',
      'Full',
    ];
    final String status = statuses[_random.nextInt(statuses.length)];

    // Create the mock driver document
    final String docId = 'mock_driver_$index';
    await _firestore.collection('driver_locations').doc(docId).set({
      'userId': docId,
      'location': GeoPoint(location.latitude, location.longitude),
      'heading': heading,
      'speed': speed,
      'isLocationVisible': true,
      'isOnline': true,
      'lastUpdated': FieldValue.serverTimestamp(),
      'puvType': puvType,
      'plateNumber': plateNumber,
      'capacity': capacity,
      'driverName': driverName,
      'rating': rating,
      'status': status,
      'etaMinutes': etaMinutes,
      'isMockData': true,
      'routeId': route.id,
      'routeCode': route.routeCode,
      'iconType': 'car', // Use car icon for drivers
    });
  }

  /// Calculate heading between two points in degrees
  double _calculateHeading(LatLng start, LatLng end) {
    final double startLat = start.latitude * (pi / 180);
    final double startLng = start.longitude * (pi / 180);
    final double endLat = end.latitude * (pi / 180);
    final double endLng = end.longitude * (pi / 180);

    final double dLng = endLng - startLng;

    final double y = sin(dLng) * cos(endLat);
    final double x =
        cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLng);

    double heading = atan2(y, x) * (180 / pi);
    if (heading < 0) {
      heading += 360;
    }

    return heading;
  }

  /// Get a random PUV type
  String _getRandomPuvType() {
    final List<String> puvTypes = ['Bus', 'Jeepney', 'Multicab', 'Motorela'];
    return puvTypes[_random.nextInt(puvTypes.length)];
  }

  /// Generate a random location within a radius
  LatLng _generateRandomLocation(LatLng center, double radiusKm) {
    // Convert radius from km to degrees (approximate)
    final double radiusDegrees = radiusKm / 111.32;

    // Generate a random angle
    final double angle = _random.nextDouble() * 2 * pi;

    // Generate a random distance within the radius
    final double distance = _random.nextDouble() * radiusDegrees;

    // Calculate the new coordinates
    final double lat = center.latitude + distance * cos(angle);
    final double lng = center.longitude + distance * sin(angle);

    return LatLng(lat, lng);
  }

  /// Generate a random plate number based on PUV type
  String _generatePlateNumber(String puvType) {
    String prefix;

    switch (puvType) {
      case 'Bus':
        prefix = 'BUS';
        break;
      case 'Jeepney':
        prefix = 'JPN';
        break;
      case 'Multicab':
        prefix = 'MCB';
        break;
      case 'Motorela':
        prefix = 'MTR';
        break;
      default:
        prefix = 'PUV';
    }

    // Generate a random 3-digit number
    final int number = 100 + _random.nextInt(900);

    return '$prefix-$number';
  }

  /// Get the maximum capacity based on PUV type
  int _getMaxCapacity(String puvType) {
    switch (puvType) {
      case 'Bus':
        return 50;
      case 'Jeepney':
        return 20;
      case 'Multicab':
        return 12;
      case 'Motorela':
        return 8;
      default:
        return 10;
    }
  }

  /// Generate a random driver name
  String _generateDriverName() {
    final List<String> firstNames = [
      'Juan',
      'Pedro',
      'Miguel',
      'Jose',
      'Antonio',
      'Maria',
      'Rosa',
      'Ana',
      'Luisa',
      'Elena',
    ];

    final List<String> lastNames = [
      'Garcia',
      'Santos',
      'Reyes',
      'Cruz',
      'Bautista',
      'Gonzales',
      'Ramos',
      'Aquino',
      'Diaz',
      'Castro',
    ];

    final String firstName = firstNames[_random.nextInt(firstNames.length)];
    final String lastName = lastNames[_random.nextInt(lastNames.length)];

    return '$firstName $lastName';
  }

  /// Generate and upload mock commuter locations
  Future<void> generateMockCommuterLocations({
    required int count,
    required LatLng center,
    required double radiusKm,
  }) async {
    // Clear existing mock data
    await _clearMockCommuterLocations();

    // Get all available routes
    final List<PUVRoute> routes = _routeService.getMockRoutes();

    // Distribute commuters across different PUV types
    final Map<String, int> puvTypeCounts = {
      'Jeepney': (count * 0.7).ceil(), // 70% Jeepneys
      'Bus': (count * 0.1).ceil(), // 10% Buses
      'Multicab': (count * 0.1).ceil(), // 10% Multicabs
      'Motorela': (count * 0.1).ceil(), // 10% Motorelas
    };

    // Ensure we don't exceed the total count
    int totalAssigned = puvTypeCounts.values.fold(
      0,
      (total, value) => total + value,
    );
    if (totalAssigned > count) {
      // Adjust the largest category down if needed
      String largestType =
          puvTypeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      puvTypeCounts[largestType] =
          puvTypeCounts[largestType]! - (totalAssigned - count);
    }

    int commuterIndex = 0;

    // Generate commuters along routes based on PUV type
    for (final entry in puvTypeCounts.entries) {
      final String puvType = entry.key;
      final int typeCount = entry.value;

      // Get routes for this PUV type
      final List<PUVRoute> typeRoutes =
          routes.where((r) => r.puvType == puvType).toList();

      if (typeRoutes.isNotEmpty) {
        // Place 70% of commuters along routes
        final int routeCommuterCount = (typeCount * 0.7).ceil();
        for (int i = 0; i < routeCommuterCount; i++) {
          // Select a route for this commuter
          final PUVRoute route = typeRoutes[i % typeRoutes.length];

          // Place the commuter near the route
          await _generateMockCommuterNearRoute(
            route: route,
            index: commuterIndex++,
            selectedPuvType: puvType,
          );
        }

        // Place remaining commuters randomly
        final int remainingCount = typeCount - routeCommuterCount;
        for (int i = 0; i < remainingCount; i++) {
          await _generateMockCommuter(
            center: center,
            radiusKm: radiusKm,
            index: commuterIndex++,
            forcePuvType: puvType,
          );
        }
      } else {
        // If no routes for this type, place all commuters randomly
        for (int i = 0; i < typeCount; i++) {
          await _generateMockCommuter(
            center: center,
            radiusKm: radiusKm,
            index: commuterIndex++,
            forcePuvType: puvType,
          );
        }
      }
    }

    // Log the result
    print('Generated $count mock commuter locations');
  }

  /// Clear existing mock commuter locations
  Future<void> _clearMockCommuterLocations() async {
    final QuerySnapshot snapshot =
        await _firestore
            .collection('commuter_locations')
            .where('isMockData', isEqualTo: true)
            .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    print('Cleared existing mock commuter locations');
  }

  /// Generate a single mock commuter
  Future<void> _generateMockCommuter({
    required LatLng center,
    required double radiusKm,
    required int index,
    String? forcePuvType,
  }) async {
    // Generate a random location within the radius
    final LatLng location = _generateRandomLocation(center, radiusKm);

    // Select a PUV type (use forced type if provided)
    final String selectedPuvType = forcePuvType ?? _getRandomPuvType();

    // Generate a random commuter name
    final String userName = _generateCommuterName();

    // Create the mock commuter document
    final String docId = 'mock_commuter_$index';
    await _firestore.collection('commuter_locations').doc(docId).set({
      'userId': docId,
      'location': GeoPoint(location.latitude, location.longitude),
      'isLocationVisible': true,
      'lastUpdated': FieldValue.serverTimestamp(),
      'selectedPuvType': selectedPuvType,
      'userName': userName,
      'isMockData': true,
      'iconType': 'person', // Use person icon for commuters
    });
  }

  /// Generate a mock commuter near a specific route
  Future<void> _generateMockCommuterNearRoute({
    required PUVRoute route,
    required int index,
    required String selectedPuvType,
  }) async {
    // Get waypoints from the route
    final List<LatLng> waypoints = route.waypoints;
    if (waypoints.isEmpty) return;

    // Select a random waypoint from the route
    final LatLng routePoint = waypoints[_random.nextInt(waypoints.length)];

    // Generate a location slightly offset from the route (50-200 meters)
    final double offsetDistanceKm = 0.05 + (_random.nextDouble() * 0.15);
    final double angle = _random.nextDouble() * 2 * pi;

    // Calculate offset location
    final double offsetLat =
        routePoint.latitude + (offsetDistanceKm / 111.32) * cos(angle);
    final double offsetLng =
        routePoint.longitude +
        (offsetDistanceKm / (111.32 * cos(routePoint.latitude * pi / 180))) *
            sin(angle);
    final LatLng location = LatLng(offsetLat, offsetLng);

    // Generate a random commuter name
    final String userName = _generateCommuterName();

    // Create the mock commuter document
    final String docId = 'mock_commuter_$index';
    await _firestore.collection('commuter_locations').doc(docId).set({
      'userId': docId,
      'location': GeoPoint(location.latitude, location.longitude),
      'isLocationVisible': true,
      'lastUpdated': FieldValue.serverTimestamp(),
      'selectedPuvType': selectedPuvType,
      'userName': userName,
      'isMockData': true,
      'routeId': route.id,
      'routeCode': route.routeCode,
      'iconType': 'person', // Use person icon for commuters
    });
  }

  /// Generate a random commuter name
  String _generateCommuterName() {
    final List<String> firstNames = [
      'John',
      'Mary',
      'James',
      'Patricia',
      'Robert',
      'Jennifer',
      'Michael',
      'Linda',
      'William',
      'Elizabeth',
    ];

    final List<String> lastNames = [
      'Smith',
      'Johnson',
      'Williams',
      'Jones',
      'Brown',
      'Davis',
      'Miller',
      'Wilson',
      'Moore',
      'Taylor',
    ];

    final String firstName = firstNames[_random.nextInt(firstNames.length)];
    final String lastName = lastNames[_random.nextInt(lastNames.length)];

    return '$firstName $lastName';
  }
}
