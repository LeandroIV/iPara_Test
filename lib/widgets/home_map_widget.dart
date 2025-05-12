import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart' as location_pkg;
import '../config/api_keys.dart';
import '../models/driver_location_model.dart';
import '../models/commuter_location_model.dart';
import '../services/location_service.dart';
import '../utils/marker_generator.dart';

// Consistent API key declaration at the top level
const String googleApiKey = "AIzaSyDtm_kDatDOlKtvEMCA5lcVRFyTM6f6NNk";

class HomeMapWidget extends StatefulWidget {
  final Function(String) onDestinationSelected;
  final bool showUserLocation;
  final Function? onLocationPermissionGranted;
  final Function(String?)? onPuvTypeSelected;

  const HomeMapWidget({
    super.key,
    required this.onDestinationSelected,
    this.showUserLocation = true,
    this.onLocationPermissionGranted,
    this.onPuvTypeSelected,
  });

  @override
  State<HomeMapWidget> createState() => HomeMapWidgetState();
}

class HomeMapWidgetState extends State<HomeMapWidget> {
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  bool _isLoading = true;
  final Set<Marker> _markers = {};
  final Map<PolylineId, Polyline> _polylines = {};
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _debounceTimer;
  List<dynamic> _searchResults = [];
  final String _googleApiKey = googleApiKey; // Use the consistent API key

  // Streams for real-time location updates
  StreamSubscription<List<DriverLocation>>? _driversSubscription;
  StreamSubscription<List<CommuterLocation>>? _commutersSubscription;

  // Location service for getting nearby drivers/commuters
  final LocationService _locationService = LocationService();

  // Selected PUV type for filtering
  String? _selectedPuvType;

  // Flags for showing drivers and commuters
  bool _showDrivers = false;
  bool _showCommuters = false;

  // Make search functionality accessible from outside
  List<dynamic> get searchResults => _searchResults;

  // Check if the map is ready
  bool get isMapReady => _mapController != null;

  @override
  void initState() {
    super.initState();

    // Delay map initialization slightly to ensure widget is fully mounted
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        initializeLocation();
        // For Android/iOS, ensure the Google Maps services are initialized
        _checkGooglePlayServices();
        // Initialize the location service
        _initializeLocationService();
      }
    });
  }

  // Initialize the location service
  Future<void> _initializeLocationService() async {
    try {
      // Initialize the location service with the appropriate role
      await _locationService.initialize(
        widget.onPuvTypeSelected != null ? 'driver' : 'commuter',
      );
    } catch (e) {
      print('Error initializing location service: $e');
    }
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    _positionStreamSubscription?.cancel();
    _driversSubscription?.cancel();
    _commutersSubscription?.cancel();
    // Cancel timers before disposing controller
    _debounceTimer?.cancel();
    // Safely dispose map controller
    if (_mapController != null) {
      try {
        _mapController!.dispose();
      } catch (e) {
        print('Error disposing map controller: $e');
      }
    }
    super.dispose();
  }

  /// Start tracking nearby drivers based on PUV type
  void startTrackingDrivers(String? puvType) {
    // Cancel any existing subscription
    _driversSubscription?.cancel();

    // Update selected PUV type
    _selectedPuvType = puvType;

    // Update the location service with the selected PUV type
    _locationService.updateSelectedPuvType(puvType);

    // If no PUV type is selected, clear drivers from map
    if (puvType == null) {
      _clearDriverMarkers();
      setState(() {
        _showDrivers = false;
      });
      return;
    }

    // Set flag to show drivers
    setState(() {
      _showDrivers = true;
    });

    // Start tracking nearby drivers
    if (_userLocation != null) {
      _driversSubscription = _locationService
          .getNearbyDrivers(
            center: _userLocation!,
            radiusKm: 5.0,
            puvType: puvType,
          )
          .listen(_updateDriverMarkers);
    }

    // Notify parent widget if callback is provided
    if (widget.onPuvTypeSelected != null) {
      widget.onPuvTypeSelected!(puvType);
    }
  }

  /// Start tracking nearby commuters based on PUV type
  void startTrackingCommuters(String? puvType) {
    // Cancel any existing subscription
    _commutersSubscription?.cancel();

    // Update selected PUV type
    _selectedPuvType = puvType;

    // Update the location service with the selected PUV type
    _locationService.updateSelectedPuvType(puvType);

    // If no PUV type is selected, clear commuters from map
    if (puvType == null) {
      _clearCommuterMarkers();
      setState(() {
        _showCommuters = false;
      });
      return;
    }

    // Set flag to show commuters
    setState(() {
      _showCommuters = true;
    });

    // Start tracking nearby commuters
    if (_userLocation != null) {
      _commutersSubscription = _locationService
          .getNearbyCommuters(
            center: _userLocation!,
            radiusKm: 5.0,
            puvType: puvType,
          )
          .listen(_updateCommuterMarkers);
    }

    // Notify parent widget if callback is provided
    if (widget.onPuvTypeSelected != null) {
      widget.onPuvTypeSelected!(puvType);
    }
  }

  /// Update driver markers on the map
  void _updateDriverMarkers(List<DriverLocation> drivers) async {
    if (!mounted) return;

    // Debug print to check if we're getting drivers
    debugPrint('Updating driver markers with ${drivers.length} drivers');

    // Remove existing driver markers
    _clearDriverMarkers();

    // Create new markers for each driver
    final Set<Marker> driverMarkers = {};

    // If no drivers, log and return early
    if (drivers.isEmpty) {
      debugPrint('No drivers to display on the map');
      return;
    }

    for (final driver in drivers) {
      // Create a unique marker ID
      final markerId = MarkerId('driver_${driver.userId}');

      // Debug print to check driver details
      debugPrint(
        'Adding driver: ${driver.driverName} (${driver.userId}) - PUV type: ${driver.puvType}',
      );
      debugPrint(
        'Driver location: ${driver.location.latitude}, ${driver.location.longitude}',
      );

      // Create info window content
      final infoWindow = InfoWindow(
        title: driver.plateNumber ?? 'PUV ${driver.puvType}',
        snippet: driver.capacity ?? 'Tap for details',
        onTap: () => _showDriverDetails(driver),
      );

      // Get the icon for this driver
      final icon = await _getDriverIcon(driver.iconType ?? driver.puvType);

      // Create the marker with fixed rotation (no rotation)
      final marker = Marker(
        markerId: markerId,
        position: driver.location,
        icon: icon,
        infoWindow: infoWindow,
        rotation:
            0, // Fixed rotation (no rotation) to make icons always face in a fixed direction
        flat: true, // Make the marker flat on the map
        anchor: const Offset(0.5, 0.5), // Center the marker
        zIndex: 2, // Higher z-index to appear above other markers
        visible: true, // Explicitly set to visible
      );

      driverMarkers.add(marker);
      debugPrint('Created marker for driver: ${driver.userId}');
    }

    // Update the map with new markers
    if (mounted) {
      setState(() {
        // First check if any existing markers with the same IDs
        for (var marker in driverMarkers) {
          _markers.removeWhere((m) => m.markerId == marker.markerId);
        }

        // Then add all the new markers
        _markers.addAll(driverMarkers);
        debugPrint(
          'Added ${driverMarkers.length} driver markers to the map. Total markers: ${_markers.length}',
        );
      });
    }
  }

  /// Update commuter markers on the map
  void _updateCommuterMarkers(List<CommuterLocation> commuters) async {
    if (!mounted) return;

    // Debug print to check if we're getting commuters
    debugPrint('Updating commuter markers with ${commuters.length} commuters');

    // Remove existing commuter markers
    _clearCommuterMarkers();

    // Create new markers for each commuter
    final Set<Marker> commuterMarkers = {};

    // If no commuters, log and return early
    if (commuters.isEmpty) {
      debugPrint('No commuters to display on the map');
      return;
    }

    // Get the commuter icon once to reuse for all markers
    final commuterIcon = await _getCommuterIcon();
    debugPrint('Successfully loaded commuter icon for all markers');

    for (final commuter in commuters) {
      // Create a unique marker ID
      final markerId = MarkerId('commuter_${commuter.userId}');

      // Debug print to check commuter details
      debugPrint(
        'Adding commuter: ${commuter.userName} (${commuter.userId}) - PUV type: ${commuter.selectedPuvType}',
      );
      debugPrint(
        'Commuter location: ${commuter.location.latitude}, ${commuter.location.longitude}',
      );

      // Create info window content
      final infoWindow = InfoWindow(
        title: commuter.userName ?? 'Commuter',
        snippet:
            commuter.destinationName != null
                ? 'Going to ${commuter.destinationName}'
                : 'Looking for ${commuter.selectedPuvType}',
      );

      // Create the marker
      final marker = Marker(
        markerId: markerId,
        position: commuter.location,
        icon: commuterIcon,
        infoWindow: infoWindow,
        zIndex: 1, // Lower z-index than drivers
        visible: true, // Explicitly set to visible
      );

      commuterMarkers.add(marker);
      debugPrint('Created marker for commuter: ${commuter.userId}');
    }

    // Update the map with new markers
    if (mounted) {
      setState(() {
        // First check if any existing markers with the same IDs
        for (var marker in commuterMarkers) {
          _markers.removeWhere((m) => m.markerId == marker.markerId);
        }

        // Then add all the new markers
        _markers.addAll(commuterMarkers);
        debugPrint(
          'Added ${commuterMarkers.length} commuter markers to the map. Total markers: ${_markers.length}',
        );
      });
    }
  }

  /// Clear driver markers from the map
  void _clearDriverMarkers() {
    // Count driver markers before removal
    int driverMarkerCount =
        _markers
            .where((marker) => marker.markerId.value.startsWith('driver_'))
            .length;

    debugPrint('Clearing $driverMarkerCount driver markers from the map');

    setState(() {
      _markers.removeWhere(
        (marker) => marker.markerId.value.startsWith('driver_'),
      );
    });

    // Verify markers were removed
    int remainingDriverMarkers =
        _markers
            .where((marker) => marker.markerId.value.startsWith('driver_'))
            .length;

    debugPrint('After clearing, $remainingDriverMarkers driver markers remain');
  }

  /// Clear commuter markers from the map
  void _clearCommuterMarkers() {
    // Count commuter markers before removal
    int commuterMarkerCount =
        _markers
            .where((marker) => marker.markerId.value.startsWith('commuter_'))
            .length;

    debugPrint('Clearing $commuterMarkerCount commuter markers from the map');

    setState(() {
      _markers.removeWhere(
        (marker) => marker.markerId.value.startsWith('commuter_'),
      );
    });

    // Verify markers were removed
    int remainingCommuterMarkers =
        _markers
            .where((marker) => marker.markerId.value.startsWith('commuter_'))
            .length;

    debugPrint(
      'After clearing, $remainingCommuterMarkers commuter markers remain',
    );
  }

  /// Show driver details in a bottom sheet
  void _showDriverDetails(DriverLocation driver) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver info header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getColorForPuvType(driver.puvType),
                      radius: 24,
                      child: Icon(
                        _getIconForPuvType(driver.puvType),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.plateNumber ?? 'Unknown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            driver.puvType,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Rating display
                    if (driver.rating != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              driver.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Driver details
                _buildDriverInfoItem(
                  'Driver',
                  driver.driverName ?? 'Unknown',
                  Icons.person,
                ),
                _buildDriverInfoItem(
                  'Status',
                  driver.status ?? 'Available',
                  Icons.info_outline,
                ),
                _buildDriverInfoItem(
                  'Capacity',
                  driver.capacity ?? 'Unknown',
                  Icons.people,
                ),
                if (driver.etaMinutes != null)
                  _buildDriverInfoItem(
                    'ETA',
                    '${driver.etaMinutes} minutes',
                    Icons.access_time,
                  ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      'Call Driver',
                      Icons.call,
                      Colors.green,
                      () => Navigator.pop(context),
                    ),
                    _buildActionButton(
                      'Message',
                      Icons.message,
                      Colors.blue,
                      () => Navigator.pop(context),
                    ),
                    _buildActionButton(
                      'Track',
                      Icons.location_on,
                      Colors.amber,
                      () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  /// Build a driver info item
  Widget _buildDriverInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Build an action button
  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            radius: 20,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  /// Get the appropriate icon for a driver based on PUV type
  Future<BitmapDescriptor> _getDriverIcon(String puvType) async {
    // Use custom PUV icons with highlight for map markers
    String iconPath;
    switch (puvType.toLowerCase()) {
      case 'bus':
        iconPath = 'assets/icons/bus_highlight.png';
        break;
      case 'jeepney':
        iconPath = 'assets/icons/jeepney_highlight.png';
        break;
      case 'multicab':
        iconPath = 'assets/icons/multicab_highlight.png';
        break;
      case 'motorela':
        iconPath = 'assets/icons/motorela_highlight.png';
        break;
      default:
        // Fallback to default marker if no matching icon
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        );
    }

    try {
      // Pre-cache the image to ensure it's loaded
      final AssetImage assetImage = AssetImage(iconPath);
      await precacheImage(assetImage, context);

      // Load the custom icon using the non-deprecated method with 86x86 size
      final icon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(86, 86)),
        iconPath,
      );

      debugPrint(
        'Successfully loaded icon for PUV type: ${puvType.toLowerCase()}',
      );
      return icon;
    } catch (e) {
      // Fallback to colored markers if custom icon fails to load
      debugPrint('Error loading PUV icon: $e, using default marker instead');

      // Select the appropriate fallback icon based on PUV type
      switch (puvType.toLowerCase()) {
        case 'bus':
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          );
        case 'jeepney':
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow,
          );
        case 'multicab':
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          );
        case 'motorela':
          return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        default:
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          );
      }
    }
  }

  /// Get the icon for a commuter
  Future<BitmapDescriptor> _getCommuterIcon() async {
    try {
      // Pre-cache the image to ensure it's loaded
      final String iconPath = 'assets/icons/person.png';
      final AssetImage assetImage = AssetImage(iconPath);
      await precacheImage(assetImage, context);

      // Load the custom icon using the non-deprecated method with 86x86 size
      final icon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(86, 86)),
        iconPath,
      );

      debugPrint('Successfully loaded commuter icon');
      return icon;
    } catch (e) {
      // Fallback to default marker if the custom icon fails to load
      debugPrint(
        'Error loading commuter icon: $e, using default marker instead',
      );
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  /// Get color for PUV type
  Color _getColorForPuvType(String type) {
    switch (type.toLowerCase()) {
      case 'bus':
        return Colors.blue;
      case 'jeepney':
        return Colors.amber;
      case 'multicab':
        return Colors.green;
      case 'motorela':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get icon for PUV type
  IconData _getIconForPuvType(String type) {
    switch (type.toLowerCase()) {
      case 'bus':
        return Icons.directions_bus;
      case 'jeepney':
      case 'multicab':
        return Icons.airport_shuttle;
      case 'motorela':
        return Icons.motorcycle;
      default:
        return Icons.directions_car;
    }
  }

  // Add a method to display a route between two points
  Future<bool> showRoute(
    LatLng origin,
    LatLng destination, {
    String? routeName,
    Color routeColor = Colors.amber,
  }) async {
    if (_mapController == null || !mounted) return false;

    try {
      setState(() {
        _isLoading = true;
      });

      // Only update the user route polyline
      final List<LatLng> polylineCoordinates = await _getDirections(
        origin,
        destination,
      );

      if (!mounted) return false;

      final PolylineId userRouteId = PolylineId('user_route');
      final Polyline polyline = Polyline(
        polylineId: userRouteId,
        color: routeColor,
        width: 5,
        points: polylineCoordinates,
      );

      setState(() {
        _polylines[userRouteId] = polyline;
        _isLoading = false;
      });

      // Fit the map to include the entire route
      if (polylineCoordinates.isNotEmpty && mounted && _mapController != null) {
        _updateCameraToShowRoute(polylineCoordinates);
      }

      return true;
    } catch (e) {
      print('Error showing route: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return false;
    }
  }

  // Method to get directions from the Google Directions API
  Future<List<LatLng>> _getDirections(LatLng origin, LatLng destination) async {
    // For mobile, use the HTTP API
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=$_googleApiKey';

    try {
      print('Fetching directions from: $url');
      final response = await http.get(Uri.parse(url));
      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API response status: ${data['status']}');

        if (data['status'] == 'OK') {
          // Decode polyline points
          final points = data['routes'][0]['overview_polyline']['points'];
          final polylinePoints = PolylinePoints().decodePolyline(points);

          // Convert to LatLng coordinates
          return polylinePoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        } else {
          print('Directions API error: ${data['status']}');
          print(
            'Error message: ${data['error_message'] ?? 'No error message'}',
          );
          // If error, return direct line between points as fallback
          return [origin, destination];
        }
      } else {
        print('Failed to fetch directions: ${response.statusCode}');
        print('Response body: ${response.body}');
        // Return direct line as fallback
        return [origin, destination];
      }
    } catch (e) {
      print('Error fetching directions: $e');
      // Return direct line as fallback
      return [origin, destination];
    }
  }

  // Method to display a predefined route
  Future<void> showPredefinedRoute(
    List<LatLng> routePoints,
    int routeColor, {
    String? routeName,
  }) async {
    if (!mounted || _mapController == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Only update the PUV route polyline
      final List<LatLng> polylineCoordinates = [];

      // Get directions from Google API to follow actual roads
      for (int i = 0; i < routePoints.length - 1; i++) {
        final result = await _getDirections(routePoints[i], routePoints[i + 1]);
        if (!mounted) return;

        // Skip the first point of each segment except the first to avoid duplicates
        if (i > 0 && result.isNotEmpty) {
          polylineCoordinates.addAll(result.sublist(1));
        } else {
          polylineCoordinates.addAll(result);
        }
      }

      if (!mounted) return;

      // Create a polyline
      final PolylineId puvRouteId = PolylineId('puv_route');
      final Polyline polyline = Polyline(
        polylineId: puvRouteId,
        color: Color(routeColor),
        points: polylineCoordinates,
        width: 5,
      );

      setState(() {
        _polylines[puvRouteId] = polyline;
        _isLoading = false;
      });

      // Update camera to show the entire route
      if (_mapController != null && mounted) {
        _updateCameraToShowRoute(polylineCoordinates);
      }
    } catch (e) {
      print('Error getting directions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Method to update camera position to show the entire route
  void _updateCameraToShowRoute(List<LatLng> points) {
    if (points.isEmpty || _mapController == null || !mounted) return;

    try {
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;

      for (var point in points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      // Create a LatLngBounds
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      // Animate camera to show all the points with padding
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } catch (e) {
      print('Error updating camera position: $e');
    }
  }

  // Clear routes
  void clearRoutes({bool clearUserRoute = true, bool clearPUVRoute = true}) {
    setState(() {
      if (clearUserRoute) {
        _polylines.remove(PolylineId('user_route'));
      }
      if (clearPUVRoute) {
        _polylines.remove(PolylineId('puv_route'));
      }
    });
  }

  // Expose search functionality to be called from parent widget
  Future<List<dynamic>> searchPlaces(String query) async {
    if (!mounted || query.isEmpty) {
      return [];
    }

    // Mobile implementation using HTTP request
    try {
      final position = _userLocation ?? const LatLng(8.4542, 124.6319);

      // First try the Places API v1
      try {
        final response = await http.post(
          Uri.parse('https://places.googleapis.com/v1/places:searchText'),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': googleApiKey,
            'X-Goog-FieldMask':
                'places.id,places.displayName,places.formattedAddress,places.location',
          },
          body: jsonEncode({
            'textQuery': query,
            'locationBias': {
              'circle': {
                'center': {
                  'latitude': position.latitude,
                  'longitude': position.longitude,
                },
                'radius': 50000.0,
              },
            },
            'languageCode': 'en',
            'regionCode': 'PH',
          }),
        );

        if (!mounted) return [];

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['places'] != null && data['places'].isNotEmpty) {
            // Format the results to match the expected structure in the UI
            final List<dynamic> formattedResults = [];
            for (var place in data['places']) {
              formattedResults.add({
                'place_id': place['id'],
                'description': place['formattedAddress'],
                'structured_formatting': {
                  'main_text': place['displayName']['text'],
                  'secondary_text': place['formattedAddress'],
                },
              });
            }

            if (mounted) {
              setState(() => _searchResults = formattedResults);
            }

            print('Formatted search results: $formattedResults');
            return formattedResults;
          }
        }
      } catch (e) {
        print(
          'Error with Places API v1: $e, falling back to Places Autocomplete API',
        );
      }

      // Fallback to the Places Autocomplete API
      final autocompleteResponse = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
          'input=$query&location=${position.latitude},${position.longitude}'
          '&radius=50000&key=$googleApiKey',
        ),
      );

      if (!mounted) return [];

      if (autocompleteResponse.statusCode == 200) {
        final data = json.decode(autocompleteResponse.body);
        if (data['status'] == 'OK' && data['predictions'] != null) {
          final predictions = data['predictions'];
          if (mounted) {
            setState(() => _searchResults = predictions);
          }

          print('Autocomplete search results: $predictions');
          return predictions;
        }
      }

      print(
        'All search APIs failed. HTTP error: ${autocompleteResponse.statusCode}',
      );
      return [];
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  // Expose place details functionality
  Future<bool> getPlaceDetails(String placeId) async {
    if (!mounted || _mapController == null) return false;

    try {
      // First try the Places API v1
      try {
        final response = await http.get(
          Uri.parse(
            'https://places.googleapis.com/v1/places/$placeId'
            '?fields=id,displayName,formattedAddress,location'
            '&key=$googleApiKey',
          ),
        );

        if (!mounted) return false;

        if (response.statusCode == 200) {
          final place = json.decode(response.body);
          final location = place['location'];
          final lat = location['latitude'];
          final lng = location['longitude'];
          final name = place['displayName']['text'];

          return _handlePlaceLocation(lat, lng, name);
        }
      } catch (e) {
        print(
          'Error with Places API v1 details: $e, falling back to Places Details API',
        );
      }

      // Fallback to the Places Details API
      final detailsResponse = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&fields=name,geometry,formatted_address'
          '&key=$googleApiKey',
        ),
      );

      if (!mounted) return false;

      if (detailsResponse.statusCode == 200) {
        final data = json.decode(detailsResponse.body);
        if (data['status'] == 'OK' && data['result'] != null) {
          final result = data['result'];
          final location = result['geometry']['location'];
          final lat = location['lat'];
          final lng = location['lng'];
          final name = result['name'];

          return _handlePlaceLocation(lat, lng, name);
        }
      }

      print(
        'All place details APIs failed. HTTP error: ${detailsResponse.statusCode}',
      );
      return false;
    } catch (e) {
      print('Error getting place details: $e');
      return false;
    }
  }

  // Helper method to handle place location
  Future<bool> _handlePlaceLocation(double lat, double lng, String name) async {
    if (!mounted || _mapController == null) return false;

    // Only remove the destination marker, not all markers
    _markers.removeWhere(
      (marker) => marker.markerId.value == 'selected_location',
    );

    // Add the destination marker
    final destinationLocation = LatLng(lat, lng);
    _markers.add(
      Marker(
        markerId: const MarkerId('selected_location'),
        position: destinationLocation,
        infoWindow: InfoWindow(title: name),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    if (mounted && _mapController != null) {
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: destinationLocation, zoom: 15),
        ),
      );

      // Show route from user location to destination if user location is available and visible
      if (_userLocation != null && widget.showUserLocation) {
        await showRoute(_userLocation!, destinationLocation);
      }
    }

    widget.onDestinationSelected(name);
    return true;
  }

  /// Initialize location services and get the user's current location
  /// This method is made public so it can be called from the MapRefresherWidget
  Future<void> initializeLocation() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorDialog('Location services are disabled');
        }
        return;
      }

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showLocationPermissionDeniedDialog();
          }
          return;
        }

        // If we get here, permission was just granted - notify the parent
        if (mounted && widget.onLocationPermissionGranted != null) {
          widget.onLocationPermissionGranted!();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showLocationPermissionDeniedDialog();
        }
        return;
      }

      // Use modern location settings
      final locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );

      // Get current position with retry mechanism
      Position? position;
      int retryCount = 0;
      const maxRetries = 3;

      while (position == null && retryCount < maxRetries) {
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: locationSettings,
          );
        } catch (e) {
          retryCount++;
          debugPrint('Location attempt $retryCount failed: $e');

          if (retryCount >= maxRetries) {
            // Last attempt with reduced accuracy
            try {
              final fallbackSettings = LocationSettings(
                accuracy: LocationAccuracy.reduced,
                timeLimit: const Duration(seconds: 30),
              );
              position = await Geolocator.getCurrentPosition(
                locationSettings: fallbackSettings,
              );
            } catch (finalError) {
              debugPrint('Final location attempt failed: $finalError');
              // Use a default location as last resort (CDO)
              position = Position(
                latitude: 8.4542,
                longitude: 124.6319,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                heading: 0,
                speed: 0,
                speedAccuracy: 0,
                altitudeAccuracy: 0,
                headingAccuracy: 0,
              );
            }
          } else {
            // Wait before retry
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position!.latitude, position.longitude);
          _isLoading = false;
        });

        // Add the user location marker
        _updateUserLocationMarker();

        // Start location updates
        _startLocationUpdates();

        // Force map refresh if controller is ready
        if (_mapController != null) {
          // Small delay to ensure map is ready
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted && _mapController != null) {
            try {
              // Force map refresh with a small camera movement
              final currentZoom = await _mapController!.getZoomLevel();
              await _mapController!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: _userLocation!,
                    zoom: currentZoom + 0.1,
                  ),
                ),
              );
              await Future.delayed(const Duration(milliseconds: 300));
              await _mapController!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: _userLocation!, zoom: currentZoom),
                ),
              );
            } catch (e) {
              debugPrint('Error refreshing map: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
      if (mounted) {
        setState(() => _isLoading = false);

        // Show error dialog with more details if it's a timeout
        if (e.toString().contains('TimeoutException')) {
          _showErrorDialog(
            'Location request timed out. Please check your location settings and try again.',
          );
        }
      }
    }
  }

  void _startLocationUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        if (mounted) {
          setState(() {
            _userLocation = LatLng(position.latitude, position.longitude);
            // Update the user location marker
            if (widget.showUserLocation) {
              _updateUserLocationMarker();
            } else {
              // Remove the user marker if visibility is off
              _markers.removeWhere(
                (marker) => marker.markerId.value == 'user_location',
              );
            }
          });
        }
      },
      onError: (e) {
        debugPrint('Error getting location updates: $e');
      },
      cancelOnError: false, // Don't cancel subscription on error
    );
  }

  // Add a method to update the user's location marker
  void _updateUserLocationMarker() {
    if (_userLocation == null) return;

    // Remove old user location marker if it exists
    _markers.removeWhere((marker) => marker.markerId.value == 'user_location');

    // Only add the user location marker if showUserLocation is true
    if (!widget.showUserLocation) return;

    // Add new marker at current location
    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _userLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'You are here'),
        zIndex: 2, // Higher z-index to appear above other markers
      ),
    );
  }

  Future<void> _centerOnUserLocation() async {
    if (_mapController == null || _userLocation == null || !mounted) return;

    try {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _userLocation!, zoom: 15),
        ),
      );
    } catch (e) {
      debugPrint('Error centering on user location: $e');
    }
  }

  Future<void> moveToLocation(LatLng location, {String? placeName}) async {
    if (_mapController == null) return;

    try {
      // Remove only the selected location marker, not all markers
      _markers.removeWhere(
        (marker) => marker.markerId.value == 'selected_location',
      );

      // Add marker for the selected location if name is provided
      if (placeName != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('selected_location'),
            position: location,
            infoWindow: InfoWindow(title: placeName),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }

      // Move camera to the location
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 15),
        ),
      );

      // Show directions if user location is available and visible
      if (_userLocation != null &&
          placeName != null &&
          widget.showUserLocation) {
        await showRoute(_userLocation!, location);
      }

      // Show the info window for the marker
      if (placeName != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        _mapController!.showMarkerInfoWindow(
          const MarkerId('selected_location'),
        );

        // Notify parent widget about the selected destination
        widget.onDestinationSelected(placeName);
      }
    } catch (e) {
      debugPrint('Error moving to location: $e');
    }
  }

  void _showLocationPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
              'Please enable location services to use this feature.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () => permission.openAppSettings(),
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  initializeLocation();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
    );
  }

  // Public method to update the user location visibility
  void updateUserLocationVisibility(bool isVisible) {
    // Update map markers based on visibility
    if (isVisible) {
      if (_userLocation != null) {
        _updateUserLocationMarker();
      }
    } else {
      // Remove user location marker
      _markers.removeWhere(
        (marker) => marker.markerId.value == 'user_location',
      );
    }

    // Force rebuild
    setState(() {});
  }

  // Method to clear the destination marker
  void clearDestinationMarker() {
    setState(() {
      _markers.removeWhere(
        (marker) => marker.markerId.value == 'selected_location',
      );
    });
  }

  // Method to verify Google Play Services are available on Android
  Future<void> _checkGooglePlayServices() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        debugPrint('Checking Google Play Services availability...');
        await Geolocator.isLocationServiceEnabled(); // This will indirectly check Google Play Services
        debugPrint('Google Play Services are available');
      } catch (e) {
        debugPrint('Error verifying Google Play Services: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Google Play Services not available. Maps functionality may be limited.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _userLocation ?? const LatLng(8.4542, 124.6319),
              zoom: 15,
            ),
            onMapCreated: (controller) async {
              if (mounted) {
                setState(() {
                  _mapController = controller;
                });

                // Apply map styling to ensure proper loading
                try {
                  // Wait a moment to ensure map is properly initialized
                  await Future.delayed(const Duration(milliseconds: 500));

                  // Force map to refresh by changing zoom slightly
                  if (mounted && _mapController != null) {
                    final currentZoom = await _mapController!.getZoomLevel();
                    await _mapController!.animateCamera(
                      CameraUpdate.zoomTo(currentZoom + 0.1),
                    );
                    await Future.delayed(const Duration(milliseconds: 300));
                    await _mapController!.animateCamera(
                      CameraUpdate.zoomTo(currentZoom),
                    );
                  }

                  // Center on user location if available
                  if (_userLocation != null && mounted) {
                    _centerOnUserLocation();
                  }
                } catch (e) {
                  debugPrint('Error initializing map: $e');
                }
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            markers: _markers,
            polylines: Set<Polyline>.of(_polylines.values),
            compassEnabled: true,
          ),
        ),
        Positioned(
          right: 16,
          top: 16,
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _centerOnUserLocation,
                child: const Center(
                  child: Icon(
                    Icons.my_location,
                    color: Colors.black54,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
