import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async' show TimeoutException;

class HomeMapWidget extends StatefulWidget {
  final Function(String) onDestinationSelected;

  const HomeMapWidget({super.key, required this.onDestinationSelected});

  @override
  State<HomeMapWidget> createState() => _HomeMapWidgetState();
}

class _HomeMapWidgetState extends State<HomeMapWidget> {
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    print('Initializing location...');
    try {
      if (kIsWeb) {
        print('Running on web platform');

        // First try with lower accuracy for faster response
        print('Attempting to get position with reduced accuracy...');
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.reduced,
            timeLimit: const Duration(seconds: 5),
          );

          print(
            'Initial position received: ${position.latitude}, ${position.longitude}',
          );
          if (mounted) {
            setState(() {
              _userLocation = LatLng(position.latitude, position.longitude);
              _isLoading = false;
            });

            if (_mapController != null) {
              _centerOnUserLocation();
            }

            // After getting initial position, try to get higher accuracy in background
            _getHighAccuracyLocation();
          }
        } catch (e) {
          print('Error with initial position, trying alternative method: $e');
          // If quick position fails, try the slower but more reliable method
          _getFallbackLocation();
        }
      } else {
        // Mobile platform location handling remains the same
        final status = await permission.Permission.locationWhenInUse.request();
        if (status.isGranted) {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          if (mounted) {
            setState(() {
              _userLocation = LatLng(position.latitude, position.longitude);
              _isLoading = false;
            });

            if (_mapController != null) {
              _centerOnUserLocation();
            }
          }

          LocationSettings locationSettings = const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          );

          Geolocator.getPositionStream(
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
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
            _showLocationPermissionDeniedDialog();
          }
        }
      }
    } catch (e) {
      print('Location initialization error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(
          'Location services error. Please try:\n\n'
          '1. Click the location icon in Chrome\'s address bar and allow access\n'
          '2. Clear Chrome\'s site settings for this website\n'
          '3. Disable and re-enable location services\n'
          '4. Try using incognito mode\n\n'
          'Error: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _getFallbackLocation() async {
    try {
      // Check permissions first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      // Try to get position with more lenient settings
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.lowest,
        timeLimit: const Duration(seconds: 20),
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });

        if (_mapController != null) {
          _centerOnUserLocation();
        }
      }
    } catch (e) {
      print('Fallback location failed: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(
          'Could not get your location. Please try:\n\n'
          '1. Click the refresh button in Chrome\'s address bar\n'
          '2. Clear your browser cache and cookies\n'
          '3. Try using incognito mode\n'
          '4. Restart Chrome\n\n'
          'Error: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _getHighAccuracyLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });

        if (_mapController != null) {
          _centerOnUserLocation();
        }
      }
    } catch (e) {
      // Ignore errors since this is a background improvement
      print('High accuracy location failed: $e');
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
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target:
                    _userLocation ??
                    const LatLng(8.4542, 124.6319), // Default to CDO center
                zoom: 15,
              ),
              onMapCreated: (controller) {
                print('Map created');
                _mapController = controller;
                _initializeLocation(); // Request location when map is ready
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
              compassEnabled: true,
              mapType: MapType.normal,
            ),
            // Custom location button
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.blue),
                  onPressed: () {
                    print('Location button pressed');
                    _initializeLocation();
                  },
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
