import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/puv_tracking_service.dart';
import '../models/puv_location.dart';

class PUVTrackingScreen extends StatefulWidget {
  const PUVTrackingScreen({super.key});

  @override
  State<PUVTrackingScreen> createState() => _PUVTrackingScreenState();
}

class _PUVTrackingScreenState extends State<PUVTrackingScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _userLocation;
  final PUVTrackingService _trackingService = PUVTrackingService();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _trackingService.subscribeToPUVLocations();
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      _updateCamera();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _updateCamera() {
    if (_mapController != null && _userLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _userLocation!, zoom: 15),
        ),
      );
    }
  }

  void _updateMarkers(List<PUVLocation> locations) {
    setState(() {
      _markers =
          locations.map((location) {
            return Marker(
              markerId: MarkerId(location.puvId),
              position: location.location,
              rotation: location.bearing,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
              infoWindow: InfoWindow(
                title: 'PUV ${location.routeNumber}',
                snippet: 'ETA: ${location.estimatedArrivalMinutes} mins',
              ),
            );
          }).toSet();

      // Add user location marker
      if (_userLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: _userLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PUV Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _updateCamera,
          ),
        ],
      ),
      body: StreamBuilder<List<PUVLocation>>(
        stream: _trackingService.puvLocations,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _updateMarkers(snapshot.data!);
          }

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target:
                  _userLocation ??
                  const LatLng(8.1470, 125.1276), // Default to Cagayan de Oro
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: true,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _trackingService.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
