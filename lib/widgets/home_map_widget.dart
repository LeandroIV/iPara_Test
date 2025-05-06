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

// Consistent API key declaration at the top level
const String googleApiKey = "AIzaSyDtm_kDatDOlKtvEMCA5lcVRFyTM6f6NNk";

class HomeMapWidget extends StatefulWidget {
  final Function(String) onDestinationSelected;
  final bool showUserLocation;
  final Function? onLocationPermissionGranted;

  const HomeMapWidget({
    super.key,
    required this.onDestinationSelected,
    this.showUserLocation = true,
    this.onLocationPermissionGranted,
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
    // For Android/iOS, ensure the Google Maps services are initialized
    _checkGooglePlayServices();
  }

  @override
  void dispose() {
    // Cancel position subscription first
    _positionStreamSubscription?.cancel();
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
        _routePoints = polylineCoordinates;
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

  Future<void> _initializeLocation() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorDialog('Location services are disabled');
        }
        return;
      }

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

      // Increase timeouts to avoid TimeoutExceptions
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20), // Increased timeout
        );
      } catch (e) {
        print(
          'Error getting high accuracy position: $e, falling back to lower accuracy',
        );
        // Fallback to reduced accuracy
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.reduced,
          timeLimit: const Duration(seconds: 30), // Increased timeout further
        );
      }

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
          _isLocationPermissionGranted = true;
        });

        // Add the user location marker
        _updateUserLocationMarker();

        // Start location updates
        _startLocationUpdates();

        // Center map on user location only if controller is ready
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && _mapController != null) {
          _centerOnUserLocation();
        }
      }
    } catch (e) {
      print('Error initializing location: $e');
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
        print('Error getting location updates: $e');
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
      print('Error centering on user location: $e');
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
      print('Error moving to location: $e');
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
                  _initializeLocation();
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
        print('Checking Google Play Services availability...');
        await Geolocator.isLocationServiceEnabled(); // This will indirectly check Google Play Services
        print('Google Play Services are available');
      } catch (e) {
        print('Error verifying Google Play Services: $e');
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
            onMapCreated: (controller) {
              if (mounted) {
                setState(() {
                  _mapController = controller;
                });
                if (_userLocation != null) {
                  _centerOnUserLocation();
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
