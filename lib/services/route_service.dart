import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
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
      debugPrint('Attempting to fetch all routes from Firestore...');

      // First try to get all documents without any filters to see if the collection exists
      final allDocs = await _routesCollection.get();
      debugPrint(
        'Total documents in routes collection: ${allDocs.docs.length}',
      );

      if (allDocs.docs.isNotEmpty) {
        // Print some sample document IDs and data
        debugPrint(
          'Sample document IDs: ${allDocs.docs.take(3).map((d) => d.id).join(', ')}',
        );
        for (var doc in allDocs.docs.take(3)) {
          final data = doc.data();
          debugPrint(
            'Document ${doc.id} data: isActive=${data['isActive']}, routeCode=${data['routeCode']}, puvType=${data['puvType']}',
          );
        }
      }

      // Now try with the filter but without orderBy (in case of missing index)
      debugPrint('Fetching active routes without ordering...');
      final querySnapshot =
          await _routesCollection.where('isActive', isEqualTo: true).get();

      debugPrint('Found ${querySnapshot.docs.length} active routes');

      final routes =
          querySnapshot.docs.map((doc) => PUVRoute.fromFirestore(doc)).toList();

      if (routes.isNotEmpty) {
        debugPrint(
          'First route: ${routes.first.routeCode} (${routes.first.name})',
        );
      }

      return routes;
    } catch (e) {
      debugPrint('Error fetching routes: $e');
      debugPrint('Error details: ${e.toString()}');
      return [];
    }
  }

  /// Fetch routes by PUV type
  Future<List<PUVRoute>> getRoutesByType(String puvType) async {
    try {
      // Normalize PUV type to ensure consistent capitalization
      String normalizedPuvType = puvType;
      if (normalizedPuvType.isNotEmpty) {
        normalizedPuvType =
            normalizedPuvType[0].toUpperCase() +
            normalizedPuvType.substring(1).toLowerCase();
      }

      final querySnapshot =
          await _routesCollection
              .where('puvType', isEqualTo: normalizedPuvType)
              .where('isActive', isEqualTo: true)
              .orderBy('routeCode')
              .get();

      // If no results with normalized type, try getting all routes and filter manually
      if (querySnapshot.docs.isEmpty) {
        final allRoutes = await getAllRoutes();
        return allRoutes
            .where(
              (route) => route.puvType.toLowerCase() == puvType.toLowerCase(),
            )
            .toList();
      }

      return querySnapshot.docs
          .map((doc) => PUVRoute.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching routes by type: $e');
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
      debugPrint('Error fetching route by ID: $e');
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
      debugPrint('Error fetching route by code: $e');
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
      debugPrint('Error finding routes between points: $e');
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
      PUVRoute(
        id: 'LA',
        name: 'LA - Lapasan to Divisoria',
        description: 'Route from Lapasan to Divisoria',
        puvType: 'Jeepney',
        routeCode: 'LA',
        waypoints: [
          const LatLng(8.479595, 124.649240), // Cogon
          const LatLng(8.481712, 124.637232), // Carmen terminal
          const LatLng(8.490123, 124.652781), // Lapasan
          const LatLng(8.498177, 124.660786), // Pier
          const LatLng(8.490123, 124.652781), // Lapasan
          const LatLng(8.481712, 124.637232), // Carmen terminal
          const LatLng(8.479595, 124.649240), // Cogon
        ],
        startPointName: 'Pier',
        endPointName: 'Cogon',
        estimatedTravelTime: 45,
        farePrice: 15.0,
        colorValue: 0xFF9C27B0, // Purple
        isActive: true,
      ),
      // New Bus Route: R3 - Lapasan to Cogon Market (Loop)
      PUVRoute(
        id: 'R3',
        name: 'R3 - Lapasan-Cogon Market (Loop)',
        description: 'Route from Lapasan to Cogon Market and back in a loop',
        puvType: 'Bus',
        routeCode: 'R3',
        waypoints: [
          const LatLng(8.482776, 124.664608), // Lapasan
          const LatLng(8.486510, 124.648319), // Gaisano
          const LatLng(8.477458, 124.644200), // Cogon Market
          const LatLng(8.477023, 124.645975), // Yacapin
          const LatLng(8.478459, 124.646503), // Velez
          const LatLng(8.480728, 124.657680), // Back to Lapasan
          const LatLng(8.482776, 124.664608), // Lapasan
        ],
        startPointName: 'Lapasan',
        endPointName: 'Cogon Market',
        estimatedTravelTime: 40,
        farePrice: 15.0,
        colorValue: 0xFF3F51B5, // Indigo
        isActive: true,
      ),
      PUVRoute(
        id: 'RC',
        name: 'RC - Cugman - Velez - Divisoria - Cogon',
        description: 'Route from Cugman to Cogon via Velez',
        puvType: 'Bus',
        routeCode: 'RC',
        waypoints: [
          const LatLng(8.469449, 124.705358), // Cugman
          const LatLng(8.469031, 124.703102), // U-turn
          const LatLng(8.482910, 124.646112), // Velez_main
          const LatLng(8.486411, 124.648293), // Velez
          const LatLng(8.480066, 124.644827), // D-Morvie
          const LatLng(8.480302, 124.643627), // Rizal
          const LatLng(8.477783, 124.643120), // Divisoria
          const LatLng(8.477131, 124.646014), // xavier
          const LatLng(8.477219, 124.649640), // Borja
          const LatLng(8.476823, 124.652875), // Cogon
          const LatLng(8.477613, 124.653608), // pearlmont
          const LatLng(8.484305, 124.657059), // Shakeys
          const LatLng(8.469449, 124.705358), // Cugman
        ],
        startPointName: 'Cugman',
        endPointName: 'Cogon Market',
        estimatedTravelTime: 40,
        farePrice: 12.0,
        colorValue: 0xFFFFC0CB, // Pink
        isActive: true,
      ),
      // New Multicab Route: RB - Pier to Macabalan
      PUVRoute(
        id: 'RB',
        name: 'RB - Pier-Puregold-Cogon-Velez-Julio Pacana-Macabalan',
        description: 'Route from Pier through city center to Macabalan',
        puvType: 'Multicab',
        routeCode: 'RB',
        waypoints: [
          const LatLng(8.498177, 124.660786), // Pier
          const LatLng(8.489390, 124.657666), // Agora
          const LatLng(8.484315, 124.658291), // Puregold
          const LatLng(8.480585, 124.657328), // limketkai
          const LatLng(8.478014, 124.650861), // Cogon
          const LatLng(8.480090, 124.644857), // Velez
          const LatLng(8.498178, 124.660057), // Julio Pacana St
          const LatLng(8.502677, 124.664270), // Macabalan
          const LatLng(8.503693, 124.659047), // Macabalan
          const LatLng(8.498177, 124.660786), // Pier
        ],
        startPointName: 'Pier',
        endPointName: 'Macabalan',
        estimatedTravelTime: 35,
        farePrice: 12.0,
        colorValue: 0xFFFF5722, // Deep Orange
        isActive: true,
      ),
      // New Motorela Route: BLUE - Agora to Cogon (Loop)
      PUVRoute(
        id: 'BLUE',
        name: 'BLUE - Agora-Osmena-Cogon (Loop)',
        description: 'Route from Agora through Osmena to Cogon in a loop',
        puvType: 'Motorela',
        routeCode: 'BLUE',
        waypoints: [
          const LatLng(8.489290, 124.657606), // Agora Market
          const LatLng(8.488186, 124.659699), // Agora - tulay semento
          const LatLng(8.490775, 124.655332), // Osmena
          const LatLng(8.484709, 124.653492), // Osmena
          const LatLng(8.477754, 124.652605), // Cogon
          const LatLng(8.485069, 124.653629), // U-Turn
          const LatLng(8.490868, 124.655387), // Osmena
          const LatLng(8.489290, 124.657606), // Agora Market
        ],
        startPointName: 'Agora',
        endPointName: 'Cogon',
        estimatedTravelTime: 25,
        farePrice: 10.0,
        colorValue: 0xFF03A9F4, // Light Blue
        isActive: true,
      ),
    ];
  }
}
