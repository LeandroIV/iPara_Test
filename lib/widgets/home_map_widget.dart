import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_keys.dart';

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
  StreamSubscription<Position>? _positionStreamSubscription;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<dynamic> _searchResults = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Search for places using Google Places API
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Get the current location for search bias
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.reduced,
      );

      // Use Google Places API to search for places
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=$query'
          '&location=${position.latitude},${position.longitude}'
          '&radius=50000' // 50km radius
          '&key=AIzaSyDtm_kDatDOlKtvEMCA5lcVRFyTM6f6NNk', // Use the web API key directly
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _searchResults = data['predictions'];
          });
        } else {
          print('Places API error: ${data['status']}');
          setState(() {
            _searchResults = [];
          });
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        setState(() {
          _searchResults = [];
        });
      }
    } catch (e) {
      print('Error searching places: $e');
      setState(() {
        _searchResults = [];
      });
    }
  }

  // Get place details from place ID
  Future<void> _getPlaceDetails(String placeId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&fields=geometry,name,formatted_address'
          '&key=AIzaSyDtm_kDatDOlKtvEMCA5lcVRFyTM6f6NNk', // Use the web API key directly
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          final location = result['geometry']['location'];
          final lat = location['lat'];
          final lng = location['lng'];
          final name = result['name'];
          final address = result['formatted_address'];

          // Move to the selected location
          await moveToLocation(LatLng(lat, lng), placeName: name);

          // Notify parent widget
          widget.onDestinationSelected(name);

          // Clear search
          setState(() {
            _searchController.clear();
            _isSearching = false;
            _searchResults = [];
          });
        }
      }
    } catch (e) {
      print('Error getting place details: $e');
    }
  }

  Future<void> _initializeLocation() async {
    setState(() => _isLoading = true);

    try {
      // First check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check location permission
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

      // Get position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      ).catchError((e) {
        // If high accuracy fails, try with reduced accuracy
        return Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.reduced,
          timeLimit: const Duration(seconds: 20),
        );
      });

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });

        // Center map on user location with a slight delay to ensure marker is visible
        await Future.delayed(const Duration(milliseconds: 500));
        await _centerOnUserLocation();

        // Start listening to location updates
        LocationSettings locationSettings = const LocationSettings(
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
              });
            }
          },
          onError: (e) {
            print('Error getting location updates: $e');
          },
        );
      }
    } catch (e) {
      print('Location error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(
          'Unable to get your location. Please make sure:\n\n'
          '1. Location services are enabled\n'
          '2. You have granted location permission\n'
          '3. You have an active internet connection\n\n'
          'Error: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _centerOnUserLocation() async {
    if (_mapController == null || _userLocation == null) return;

    try {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _userLocation!,
            zoom: 16.0,
            tilt: 0.0,
            bearing: 0.0,
          ),
        ),
      );
    } catch (e) {
      print('Error centering map: $e');
    }
  }

  // Method to move to a specific location
  Future<void> moveToLocation(LatLng location, {String? placeName}) async {
    if (_mapController == null) return;

    try {
      // Clear existing markers (except user location marker)
      setState(() {
        _markers.removeWhere(
          (marker) => marker.markerId.value != 'user_location',
        );

        // Add marker for the selected location
        if (placeName != null) {
          _markers.add(
            Marker(
              markerId: MarkerId('selected_location'),
              position: location,
              infoWindow: InfoWindow(title: placeName),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );
        }
      });

      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 17.0, tilt: 0.0, bearing: 0.0),
        ),
      );

      // Show the info window for the marker
      if (placeName != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        _mapController!.showMarkerInfoWindow(
          const MarkerId('selected_location'),
        );
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
        GoogleMap(
          onMapCreated: (controller) async {
            _mapController = controller;
            await controller.setMapStyle('''[
              {
                "featureType": "poi",
                "elementType": "labels",
                "stylers": [
                  {
                    "visibility": "simplified"
                  }
                ]
              }
            ]''');
            _initializeLocation();
          },
          initialCameraPosition: CameraPosition(
            target:
                _userLocation ??
                const LatLng(8.4542, 124.6319), // Default to Cagayan de Oro
            zoom: 12,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          zoomGesturesEnabled: true,
          mapType: MapType.normal,
          trafficEnabled: false,
          buildingsEnabled: true,
          indoorViewEnabled: false,
          markers: _markers,
        ),
        // Search Bar
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Input
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a place',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black54,
                      ),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _isSearching = false;
                                    _searchResults = [];
                                  });
                                },
                              )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (value) {
                      // Debounce search to avoid too many API calls
                      _debounceTimer?.cancel();
                      _debounceTimer = Timer(
                        const Duration(milliseconds: 500),
                        () {
                          _searchPlaces(value);
                        },
                      );
                    },
                  ),
                  // Search Results
                  if (_isSearching && _searchResults.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey, width: 0.5),
                        ),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                            ),
                            title: Text(
                              result['structured_formatting']['main_text'],
                            ),
                            subtitle: Text(
                              result['structured_formatting']['secondary_text'],
                            ),
                            onTap: () {
                              _getPlaceDetails(result['place_id']);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Custom location button
        if (!_isLoading)
          Positioned(
            right: 10,
            bottom: 80,
            child: Material(
              elevation: 2,
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              child: InkWell(
                onTap: _centerOnUserLocation,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.my_location,
                    size: 23,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        // Loading indicator
        if (_isLoading)
          Container(
            color: Colors.white70,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Getting your location...',
                    style: TextStyle(color: Colors.black87, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
