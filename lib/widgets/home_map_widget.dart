import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:js' as js;
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart' as location_pkg;
import '../config/api_keys.dart';

// Consistent API key declaration at the top level
const String googleApiKey = "AIzaSyDtm_kDatDOlKtvEMCA5lcVRFyTM6f6NNk";

class HomeMapWidget extends StatefulWidget {
  final Function(String) onDestinationSelected;

  const HomeMapWidget({super.key, required this.onDestinationSelected});

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
  dynamic _placesService;
  bool _isPlacesApiInitialized = false;
  Timer? _placesApiCheckTimer;
  List<dynamic> _searchResults = [];
  List<LatLng> _routePoints = [];
  final String _googleApiKey = googleApiKey; // Use the consistent API key
  bool _showLoading = false;
  bool _isLocationPermissionGranted = false;
  location_pkg.LocationData? _locationData;
  Map<String, dynamic>? _selectedPlaceDetails;

  // Make search functionality accessible from outside
  List<dynamic> get searchResults => _searchResults;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    if (kIsWeb) {
      _initializePlacesApi();
    }
  }

  void _initializePlacesApi() {
    // Create a hidden div for the map if it doesn't exist
    var mapDiv = html.document.getElementById('map');
    if (mapDiv == null) {
      mapDiv =
          html.DivElement()
            ..id = 'map'
            ..style.visibility = 'hidden'
            ..style.height = '0px'
            ..style.width = '0px';
      html.document.body!.children.add(mapDiv);
    }

    // Start checking for Places API initialization
    _placesApiCheckTimer?.cancel();
    _placesApiCheckTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        if (js.context.hasProperty('google') &&
            js.context['google'].hasProperty('maps') &&
            js.context['google']['maps'].hasProperty('places')) {
          final maps = js.context['google']['maps'];
          final placesService = js.JsObject(maps['places']['PlacesService'], [
            mapDiv,
          ]);

          setState(() {
            _placesService = placesService;
            _isPlacesApiInitialized = true;
          });

          print('Places API initialized successfully');
          timer.cancel();
        }
      } catch (e) {
        print('Waiting for Places API initialization: $e');
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    _debounceTimer?.cancel();
    _placesApiCheckTimer?.cancel();
    super.dispose();
  }

  // Add a method to display a route between two points
  Future<bool> showRoute(
    LatLng origin,
    LatLng destination, {
    String? routeName,
    Color routeColor = Colors.amber,
  }) async {
    if (_mapController == null) return false;

    try {
      setState(() {
        _isLoading = true;
      });

      // First clear any existing polylines
      _polylines.clear();

      // Get directions from Google API
      final List<LatLng> polylineCoordinates = await _getDirections(
        origin,
        destination,
      );

      final String polylineId =
          routeName ?? 'route_${DateTime.now().millisecondsSinceEpoch}';

      final Polyline polyline = Polyline(
        polylineId: PolylineId(polylineId),
        color: routeColor,
        width: 5,
        points: polylineCoordinates,
      );

      setState(() {
        _polylines[PolylineId(polylineId)] = polyline;
        _isLoading = false;
      });

      // Fit the map to include the entire route
      if (polylineCoordinates.isNotEmpty) {
        _updateCameraToShowRoute(polylineCoordinates);
      }

      return true;
    } catch (e) {
      print('Error showing route: $e');
      setState(() {
        _isLoading = false;
      });
      return false;
    }
  }

  // Method to get directions from the Google Directions API
  Future<List<LatLng>> _getDirections(LatLng origin, LatLng destination) async {
    if (kIsWeb) {
      // For web, use the JS DirectionsService to avoid CORS issues
      return await _getDirectionsWeb(origin, destination);
    }

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

  // Get lat/lng values properly from JavaScript objects
  dynamic _getLatLngValue(dynamic jsObject, String property) {
    if (jsObject is js.JsObject) {
      // Check if the property is a method that needs to be called
      if (jsObject[property] is js.JsFunction) {
        return jsObject.callMethod(property);
      } else {
        return jsObject[property];
      }
    }
    return 0.0; // Fallback
  }

  // Web-specific implementation using Google Maps JS API to avoid CORS issues
  Future<List<LatLng>> _getDirectionsWeb(
    LatLng origin,
    LatLng destination,
  ) async {
    final completer = Completer<List<LatLng>>();

    try {
      // Wait for Maps API to be fully loaded
      if (!js.context.hasProperty('google') ||
          !js.context['google'].hasProperty('maps') ||
          !js.context['google']['maps'].hasProperty('DirectionsService')) {
        print('Waiting for Google Maps API to initialize...');
        await Future.delayed(const Duration(milliseconds: 500));
        // If still not loaded, fall back to direct line
        if (!js.context.hasProperty('google') ||
            !js.context['google'].hasProperty('maps') ||
            !js.context['google']['maps'].hasProperty('DirectionsService')) {
          print('Google Maps API not loaded. Using fallback.');
          return [origin, destination];
        }
      }

      final directionsService = js.JsObject(
        js.context['google']['maps']['DirectionsService'],
      );

      final request = js.JsObject.jsify({
        'origin': {'lat': origin.latitude, 'lng': origin.longitude},
        'destination': {
          'lat': destination.latitude,
          'lng': destination.longitude,
        },
        'travelMode': 'DRIVING',
      });

      print('Requesting directions via JavaScript API...');
      directionsService.callMethod('route', [
        request,
        (result, status) {
          if (status == 'OK') {
            try {
              print('Got successful directions response');
              // Create coordinates manually from the route path
              final List<LatLng> polylineCoordinates = [];

              // Get route overview path for a smoother line
              final overviewPath = result['routes'][0]['overview_path'];
              if (overviewPath != null) {
                print('Using overview_path with ${overviewPath.length} points');
                for (var i = 0; i < overviewPath.length; i++) {
                  final point = overviewPath[i];
                  final lat = _getLatLngValue(point, 'lat');
                  final lng = _getLatLngValue(point, 'lng');
                  polylineCoordinates.add(LatLng(lat, lng));
                }
              } else {
                // Fallback to using legs and steps
                print('Falling back to legs and steps');
                final legs = result['routes'][0]['legs'];
                for (var i = 0; i < legs.length; i++) {
                  final steps = legs[i]['steps'];
                  for (var j = 0; j < steps.length; j++) {
                    final startLoc = steps[j]['start_location'];
                    final endLoc = steps[j]['end_location'];

                    // Extract coordinates safely
                    final startLat = _getLatLngValue(startLoc, 'lat');
                    final startLng = _getLatLngValue(startLoc, 'lng');
                    polylineCoordinates.add(LatLng(startLat, startLng));

                    // If it's the last step of the last leg, add the end location too
                    if (i == legs.length - 1 && j == steps.length - 1) {
                      final endLat = _getLatLngValue(endLoc, 'lat');
                      final endLng = _getLatLngValue(endLoc, 'lng');
                      polylineCoordinates.add(LatLng(endLat, endLng));
                    }
                  }
                }
              }

              print(
                'Generated polyline with ${polylineCoordinates.length} points',
              );
              completer.complete(polylineCoordinates);
            } catch (e) {
              print('Error parsing directions result: $e');
              completer.complete([origin, destination]);
            }
          } else {
            print('Directions service failed: $status');
            completer.complete([origin, destination]);
          }
        },
      ]);
    } catch (e) {
      print('Error getting directions via JavaScript API: $e');
      completer.complete([origin, destination]);
    }

    return completer.future;
  }

  // Method to display a predefined route
  Future<void> showPredefinedRoute(
    List<LatLng> routePoints,
    int routeColor, {
    String? routeName,
  }) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Clear previous polylines
      _polylines.clear();

      final List<LatLng> polylineCoordinates = [];

      // Get directions from Google API to follow actual roads
      for (int i = 0; i < routePoints.length - 1; i++) {
        final result = await _getDirections(routePoints[i], routePoints[i + 1]);

        // Skip the first point of each segment except the first to avoid duplicates
        if (i > 0 && result.isNotEmpty) {
          polylineCoordinates.addAll(result.sublist(1));
        } else {
          polylineCoordinates.addAll(result);
        }
      }

      // Create a polyline
      final PolylineId polylineId = PolylineId(routeName ?? 'route');
      final Polyline polyline = Polyline(
        polylineId: polylineId,
        color: Color(routeColor),
        points: polylineCoordinates,
        width: 5,
      );

      setState(() {
        _routePoints = polylineCoordinates;
        _polylines[polylineId] = polyline;
        _isLoading = false;
      });

      // Update camera to show the entire route
      _updateCameraToShowRoute(polylineCoordinates);
    } catch (e) {
      print('Error getting directions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to update camera position to show the entire route
  void _updateCameraToShowRoute(List<LatLng> points) {
    if (points.isEmpty) return;

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
  }

  // Clear all routes
  void clearRoutes() {
    setState(() {
      _polylines.clear();
    });
  }

  // Expose search functionality to be called from parent widget
  Future<List<dynamic>> searchPlaces(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      return _searchResults;
    }

    if (kIsWeb) {
      if (!_isPlacesApiInitialized) {
        print('Places API not initialized yet');
        return [];
      }

      try {
        final position = _userLocation ?? const LatLng(8.4542, 124.6319);
        final maps = js.context['google']['maps'];

        // Create the AutocompleteService instead of using PlacesService for text search
        final autocompleteService = js.JsObject(
          maps['places']['AutocompleteService'],
        );

        final request = js.JsObject.jsify({
          'input': query,
          'location': js.JsObject(maps['LatLng'], [
            position.latitude,
            position.longitude,
          ]),
          'radius': 50000, // 50km radius
          'componentRestrictions': {'country': 'PH'},
        });

        // Create a completer to handle the async response
        final completer = Completer<List<dynamic>>();

        autocompleteService.callMethod('getPlacePredictions', [
          request,
          (predictions, status) {
            if (status == maps['places']['PlacesServiceStatus']['OK']) {
              _searchResults = List.from(predictions);
              completer.complete(_searchResults);
            } else {
              print('Places API error: $status');
              _searchResults = [];
              completer.complete([]);
            }
          },
        ]);

        return completer.future;
      } catch (e) {
        print('Error searching places: $e');
        _searchResults = [];
        return [];
      }
    } else {
      // Fallback to HTTP request for non-web platforms
      try {
        final position = _userLocation ?? const LatLng(8.4542, 124.6319);

        final response = await http.post(
          Uri.parse('https://places.googleapis.com/v1/places:searchText'),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': googleApiKey,
            'X-Goog-FieldMask':
                'places.displayName,places.formattedAddress,places.location',
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

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['places'] != null) {
            _searchResults = data['places'];
            return _searchResults;
          }
        }
        return [];
      } catch (e) {
        print('Error searching places: $e');
        return [];
      }
    }
  }

  // Expose place details functionality
  Future<bool> getPlaceDetails(String placeId) async {
    if (kIsWeb) {
      if (!_isPlacesApiInitialized) {
        print('Places API not initialized yet');
        return false;
      }

      try {
        final maps = js.context['google']['maps'];
        final request = js.JsObject.jsify({
          'placeId': placeId,
          'fields': ['name', 'formatted_address', 'geometry', 'place_id'],
        });

        // Create a completer to handle the async response
        final completer = Completer<bool>();

        _placesService.callMethod('getDetails', [
          request,
          (place, status) {
            if (status == maps['places']['PlacesServiceStatus']['OK']) {
              final location = place['geometry']['location'];
              final lat = location.callMethod('lat');
              final lng = location.callMethod('lng');
              final name = place['name'];

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
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
              );

              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: destinationLocation, zoom: 15),
                ),
              );

              // Show route from user location to destination if user location is available
              if (_userLocation != null) {
                showRoute(_userLocation!, destinationLocation);
              }

              widget.onDestinationSelected(name);
              completer.complete(true);
            } else {
              print('Error getting place details: $status');
              completer.complete(false);
            }
          },
        ]);

        return completer.future;
      } catch (e) {
        print('Error getting place details: $e');
        return false;
      }
    } else {
      try {
        final response = await http.get(
          Uri.parse(
            'https://places.googleapis.com/v1/places/$placeId'
            '?fields=id,displayName,formattedAddress,location'
            '&key=$googleApiKey',
          ),
        );

        if (response.statusCode == 200) {
          final place = json.decode(response.body);
          final location = place['location'];
          final lat = location['latitude'];
          final lng = location['longitude'];
          final name = place['displayName']['text'];

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
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          );

          await _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: destinationLocation, zoom: 15),
            ),
          );

          // Show route from user location to destination if user location is available
          if (_userLocation != null) {
            await showRoute(_userLocation!, destinationLocation);
          }

          widget.onDestinationSelected(name);
          return true;
        }
        return false;
      } catch (e) {
        print('Error getting place details: $e');
        return false;
      }
    }
  }

  Future<void> _initializeLocation() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      ).catchError((e) async {
        // Fallback to reduced accuracy
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.reduced,
          timeLimit: const Duration(seconds: 10),
        );
      });

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });

        // Add the user location marker
        _updateUserLocationMarker();

        // Start location updates
        _startLocationUpdates();

        // Center map on user location
        await Future.delayed(const Duration(milliseconds: 500));
        _centerOnUserLocation();
      }
    } catch (e) {
      print('Error initializing location: $e');
      setState(() => _isLoading = false);
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
            _updateUserLocationMarker();
          });
        }
      },
      onError: (e) {
        print('Error getting location updates: $e');
      },
    );
  }

  // Add a method to update the user's location marker
  void _updateUserLocationMarker() {
    if (_userLocation == null) return;

    // Remove old user location marker if it exists
    _markers.removeWhere((marker) => marker.markerId.value == 'user_location');

    // Add new marker at current location
    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _userLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'You are here'),
        zIndex: 2, // Higher z-index to appear above other markers
      ),
    );
  }

  Future<void> _centerOnUserLocation() async {
    if (_mapController != null && _userLocation != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _userLocation!, zoom: 15),
        ),
      );
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

      // Show directions if user location is available
      if (_userLocation != null && placeName != null) {
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
      print('Error moving to location: $e');
    }
  }

  void _showLocationPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: Text(
              kIsWeb
                  ? 'Please enable location services in your browser settings to use this feature.'
                  : 'Please enable location services to use this feature.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              if (!kIsWeb)
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
                  _initializeLocation();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
    );
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
            onMapCreated: (controller) {
              _mapController = controller;
              if (_userLocation != null) {
                _centerOnUserLocation();
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
