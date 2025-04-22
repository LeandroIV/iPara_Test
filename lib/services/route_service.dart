import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_model.dart';

/// Service class for handling PUV route data
class RouteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get collection reference for routes
  CollectionReference<Map<String, dynamic>> get _routesCollection =>
      _firestore.collection('routes');

  /// Fetch all routes
  Future<List<PUVRoute>> getAllRoutes() async {
    try {
      final querySnapshot =
          await _routesCollection
              .where('isActive', isEqualTo: true)
              .orderBy('routeCode')
              .get();

      return querySnapshot.docs
          .map((doc) => PUVRoute.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching routes: $e');
      return [];
    }
  }

  /// Fetch routes by PUV type
  Future<List<PUVRoute>> getRoutesByType(String puvType) async {
    try {
      final querySnapshot =
          await _routesCollection
              .where('puvType', isEqualTo: puvType)
              .where('isActive', isEqualTo: true)
              .orderBy('routeCode')
              .get();

      return querySnapshot.docs
          .map((doc) => PUVRoute.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching routes by type: $e');
      return [];
    }
  }

  /// Get route by ID
  Future<PUVRoute?> getRouteById(String routeId) async {
    try {
      final docSnapshot = await _routesCollection.doc(routeId).get();

      if (docSnapshot.exists) {
        return PUVRoute.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      print('Error fetching route by ID: $e');
      return null;
    }
  }

  /// Get route by route code
  Future<PUVRoute?> getRouteByCode(String routeCode) async {
    try {
      final querySnapshot =
          await _routesCollection
              .where('routeCode', isEqualTo: routeCode)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return PUVRoute.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error fetching route by code: $e');
      return null;
    }
  }

  /// Find routes that pass through two points
  /// This is a simple implementation - in a real app you would need
  /// a more sophisticated algorithm to find routes between points
  Future<List<PUVRoute>> findRoutesBetweenPoints(
    LatLng startPoint,
    LatLng endPoint, {
    String? puvType,
    double radiusInKm = 0.5,
  }) async {
    try {
      // Fetch all routes of the specified type, or all routes if type not specified
      List<PUVRoute> routes =
          puvType != null
              ? await getRoutesByType(puvType)
              : await getAllRoutes();

      // Filter routes that pass near both points
      return routes.where((route) {
        // Check if any waypoint is within radiusInKm of the start point
        bool passesNearStart = route.waypoints.any(
          (waypoint) => _isPointNearby(waypoint, startPoint, radiusInKm),
        );

        // Check if any waypoint is within radiusInKm of the end point
        bool passesNearEnd = route.waypoints.any(
          (waypoint) => _isPointNearby(waypoint, endPoint, radiusInKm),
        );

        // Route must pass near both points
        return passesNearStart && passesNearEnd;
      }).toList();
    } catch (e) {
      print('Error finding routes between points: $e');
      return [];
    }
  }

  /// Calculate if a point is within radius of another point using Haversine formula
  bool _isPointNearby(LatLng point1, LatLng point2, double radiusInKm) {
    // Approximate distance calculation using Haversine formula
    const double earthRadius = 6371.0; // Earth's radius in km

    // Convert latitude and longitude from degrees to radians
    final lat1 = point1.latitude * (pi / 180);
    final lon1 = point1.longitude * (pi / 180);
    final lat2 = point2.latitude * (pi / 180);
    final lon2 = point2.longitude * (pi / 180);

    // Haversine formula
    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadius * c;

    return distance <= radiusInKm;
  }

  /// Get mockup test route data (for testing without Firestore)
  List<PUVRoute> getMockRoutes() {
    return [
      PUVRoute(
        id: 'r2',
        name: 'R2 - Gaisano-Agora-Cogon-Carmen',
        description: 'Route from Carmen to Divisoria via Corrales Avenue',
        puvType: 'Jeepney',
        routeCode: 'R2',
        waypoints: [
          const LatLng(8.486261, 124.649210), // gaisano
          const LatLng(8.488737, 124.654004), //osmena
          const LatLng(8.488257, 124.657648), // agora market
          const LatLng(8.484704, 124.656401), // ustp
          const LatLng(8.484704, 124.656401), // ustp
          const LatLng(8.478534, 124.654355), // pearl mont
          const LatLng(8.478744, 124.652822), // pearl mont unahan
          const LatLng(8.479595, 124.649240), // cogon
          const LatLng(8.477819, 124.642316), // capistrano
          const LatLng(8.476322, 124.640128), // yselina bridge
          const LatLng(8.481712, 124.637232), // coc terminal
          const LatLng(8.484994, 124.637248), // mango st
          const LatLng(8.486158, 124.638827), // liceo
          const LatLng(8.486261, 124.649210), // gaisano
        ],
        startPointName: 'Gaisano',
        endPointName: 'Carmen',
        estimatedTravelTime: 25,
        farePrice: 12.0,
        colorValue: 0xFFFF6D00, // Deep Orange
        isActive: true,
      ),
      PUVRoute(
        id: 'C2',
        name: 'C2 - Patag-Gaisano-Limketkai-Cogon',
        description: 'Route from Patag to Cogon via Gaisano',
        puvType: 'Jeepney',
        routeCode: 'C2',
        waypoints: [
          const LatLng(8.477434, 124.649630), // Cogon
          const LatLng(8.476343, 124.639981), // ysalina bridge
          const LatLng(8.480251, 124.637131), // carmen cogon
          const LatLng(8.485040, 124.637276), // mango st
          const LatLng(8.487765, 124.626766), // Patag
          const LatLng(8.486605, 124.638888), // lieo
          const LatLng(8.486261, 124.649210), // gaisano
          const LatLng(8.477434, 124.649630), // Cogon
        ],
        startPointName: 'Patag',
        endPointName: 'Cogon',
        estimatedTravelTime: 30,
        farePrice: 13.0,
        colorValue: 0xFF2196F3, // Blue
        isActive: true,
      ),
      PUVRoute(
        id: 'RA',
        name: 'RA - Pier-Gaisano-Ayala-Cogon',
        description: 'Route from Pier to Cogon via Gaisano',
        puvType: 'Jeepney',
        routeCode: 'RA',
        waypoints: [
          const LatLng(8.486684, 124.650807), // Gaisano main
          const LatLng(8.498177, 124.660786), // Pier
          const LatLng(8.504380, 124.661618), // Macabalan Edge
          const LatLng(8.503708, 124.659001), // Macabalan
          const LatLng(8.498178, 124.660057), // Juliu Pacana St
          const LatLng(8.476927, 124.644083), // Divisoria Plaza
          const LatLng(8.476425, 124.645800), // Xavier
          const LatLng(8.476817, 124.652773), // borja st
          const LatLng(8.477448, 124.652930), // Roxas St
          const LatLng(8.477855, 124.651483), // yacapin to vicente
          const LatLng(8.480664, 124.650289), // Ebarle st
          const LatLng(8.485169, 124.650207), // Ayala
          const LatLng(8.486684, 124.650807), // Gaisano main
        ],
        startPointName: 'Pier',
        endPointName: 'Cogon',
        estimatedTravelTime: 45,
        farePrice: 15.0,
        colorValue: 0xFF4CAF50, // Green
        isActive: true,
      ),
      PUVRoute(
        id: 'RD',
        name: 'RD - Gusa-Cugman-Cogon-Limketkai',
        description: 'Route from Cugman to Limketkai via Gusa',
        puvType: 'Jeepney',
        routeCode: 'RD',
        waypoints: [
          const LatLng(8.469899, 124.705196), // cugman
          const LatLng(8.477536, 124.676559), // Gusa
          const LatLng(8.486028, 124.650684), // Gaisano
          const LatLng(8.485010, 124.647179), // Velez
          const LatLng(8.485627, 124.646200), // capistrano
          const LatLng(8.477565, 124.642297), // Divisoria
          const LatLng(8.476425, 124.645800), // Xavier
          const LatLng(8.476817, 124.652773), // borja
          const LatLng(8.477595, 124.653591), // yacapin
          const LatLng(8.484484, 124.657109), // ketkai
          const LatLng(8.469899, 124.705196), // cugman
        ],
        startPointName: 'Cugman',
        endPointName: 'Limketkai',
        estimatedTravelTime: 35,
        farePrice: 14.0,
        colorValue: 0xFFE91E63, // Pink
        isActive: true,
      ),
    ];
  }
}
