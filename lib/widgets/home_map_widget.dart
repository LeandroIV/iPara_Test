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
  Timer? _debounceTimer;
  dynamic _placesService;
  bool _isPlacesApiInitialized = false;
  Timer? _placesApiCheckTimer;
  List<dynamic> _searchResults = [];

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
            'X-Goog-Api-Key': 'AIzaSyDtm_kDatDOlKtvEMCA5lcVRFyTM6f6NNk',
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

              _markers.clear();
              _markers.add(
                Marker(
                  markerId: const MarkerId('selected_location'),
                  position: LatLng(lat, lng),
                  infoWindow: InfoWindow(title: name),
                ),
              );

              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: LatLng(lat, lng), zoom: 15),
                ),
              );

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
            '&key=AIzaSyDtm_kDatDOlKtvEMCA5lcVRFyTM6f6NNk',
          ),
        );

        if (response.statusCode == 200) {
          final place = json.decode(response.body);
          final location = place['location'];
          final lat = location['latitude'];
          final lng = location['longitude'];
          final name = place['displayName']['text'];

          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('selected_location'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(title: name),
            ),
          );

          await _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: LatLng(lat, lng), zoom: 15),
            ),
          );

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
          });
        }
      },
      onError: (e) {
        print('Error getting location updates: $e');
      },
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
      // Clear existing markers
      _markers.clear();

      // Add marker for the selected location if name is provided
      if (placeName != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('selected_location'),
            position: location,
            infoWindow: InfoWindow(title: placeName),
          ),
        );
      }

      // Move camera to the location
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 15),
        ),
      );

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
        GoogleMap(
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
          compassEnabled: true,
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
