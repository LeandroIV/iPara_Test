import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../services/family_group_service.dart';
import '../../models/family_member_location_model.dart';

class FamilyMapScreen extends StatefulWidget {
  final String groupId;

  const FamilyMapScreen({super.key, required this.groupId});

  @override
  State<FamilyMapScreen> createState() => _FamilyMapScreenState();
}

class _FamilyMapScreenState extends State<FamilyMapScreen> {
  final FamilyGroupService _groupService = FamilyGroupService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;
  bool _isLocationVisible = true;
  StreamSubscription<List<FamilyMemberLocation>>? _membersLocationSubscription;
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  String? _selectedFamilyMemberId;
  String? _currentRouteDistance;
  String? _selectedFamilyMemberName;

  // Google Maps API key
  final String _googleApiKey = "AIzaSyDtm_kDatDOlKtvEMCA5lcVRFyTM6f6NNk";

  // Default location (will be updated with user's location)
  LatLng _currentLocation = const LatLng(8.4542, 124.6319); // CDO, Philippines

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
    _getCurrentLocation();
    _loadMarkerIcons();
  }

  @override
  void dispose() {
    _membersLocationSubscription?.cancel();
    _mapController?.dispose();
    _groupService.stopFamilyLocationSharing();
    super.dispose();
  }

  // Load custom marker icons
  void _loadMarkerIcons() {
    try {
      // Load default family member icon
      _markerIconCache['default'] = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
      );

      // Load current user icon
      _markerIconCache['user'] = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      );
    } catch (e) {
      debugPrint('Error loading marker icons: $e');
    }
  }

  Future<void> _loadFamilyMembers() async {
    try {
      // Start the family location sharing service
      await _groupService.startFamilyLocationSharing(
        isVisible: _isLocationVisible,
      );

      setState(() {
        _isLoading = false;
      });

      // Start tracking family members' locations
      _startTrackingMembersLocation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading family members: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      // Update camera position if map controller is available
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation, 15),
      );

      // Start tracking current user's location through the family group service
      await _groupService.startFamilyLocationSharing(
        isVisible: _isLocationVisible,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    }
  }

  void _startTrackingMembersLocation() {
    // Cancel any existing subscription
    _membersLocationSubscription?.cancel();

    // Use the family group service to get family member locations
    _membersLocationSubscription = _groupService
        .getFamilyMemberLocations(widget.groupId)
        .listen(_updateFamilyMemberMarkers);
  }

  void _updateFamilyMemberMarkers(List<FamilyMemberLocation> members) async {
    // Clear existing markers except the user's marker
    final currentUserId = _auth.currentUser?.uid;
    _markers.removeWhere(
      (marker) =>
          marker.markerId.value != 'user_location' &&
          marker.markerId.value != 'current_user',
    );

    // Add markers for each family member
    for (final member in members) {
      // Skip the current user
      if (member.userId == currentUserId) continue;

      // Get the icon for the marker
      final BitmapDescriptor icon =
          _markerIconCache['default'] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

      // Format the last updated time
      final lastUpdated = member.lastUpdated;
      final timeString =
          '${lastUpdated.hour}:${lastUpdated.minute.toString().padLeft(2, '0')}';

      // Create the marker
      final marker = Marker(
        markerId: MarkerId('family_${member.userId}'),
        position: member.location,
        icon: icon,
        infoWindow: InfoWindow(
          title: member.displayName ?? 'Unknown Family Member',
          snippet: 'Last seen at $timeString',
        ),
        onTap: () async {
          await _createPolylineToFamilyMember(member.userId, member.location);
        },
      );

      setState(() {
        _markers.add(marker);
      });
    }

    // Add current user marker
    if (currentUserId != null && _isLocationVisible) {
      final userMarker = Marker(
        markerId: const MarkerId('current_user'),
        position: _currentLocation,
        icon:
            _markerIconCache['user'] ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(
          title: 'You',
          snippet: 'Your current location',
        ),
      );

      setState(() {
        _markers.add(userMarker);
      });
    }
  }

  void _toggleLocationVisibility() {
    setState(() {
      _isLocationVisible = !_isLocationVisible;
    });

    // Update visibility using the family group service
    _groupService.updateLocationVisibility(_isLocationVisible);

    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isLocationVisible
              ? 'Your location is now visible to family members'
              : 'Your location is now hidden from family members',
        ),
        backgroundColor: _isLocationVisible ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Method to get directions from the Google Directions API
  Future<List<LatLng>> _getDirections(LatLng origin, LatLng destination) async {
    // For mobile, use the HTTP API
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=$_googleApiKey';

    try {
      debugPrint('Fetching directions from: $url');
      final response = await http.get(Uri.parse(url));
      debugPrint('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('API response status: ${data['status']}');

        if (data['status'] == 'OK') {
          // Decode polyline points
          final points = data['routes'][0]['overview_polyline']['points'];
          final polylinePoints = PolylinePoints().decodePolyline(points);

          // Convert to LatLng coordinates
          return polylinePoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        } else {
          debugPrint('Directions API error: ${data['status']}');
          debugPrint(
            'Error message: ${data['error_message'] ?? 'No error message'}',
          );
          // If error, return direct line between points as fallback
          return [origin, destination];
        }
      } else {
        debugPrint('Failed to fetch directions: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        // Return direct line as fallback
        return [origin, destination];
      }
    } catch (e) {
      debugPrint('Error fetching directions: $e');
      // Return direct line as fallback
      return [origin, destination];
    }
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
          start.latitude,
          start.longitude,
          end.latitude,
          end.longitude,
        ) /
        1000; // Convert meters to kilometers
  }

  /// Calculate the total distance of a polyline in kilometers
  double _calculatePolylineDistance(List<LatLng> points) {
    double totalDistance = 0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += _calculateDistance(points[i], points[i + 1]);
    }
    return totalDistance;
  }

  /// Creates a polyline between the current user and a selected family member
  Future<void> _createPolylineToFamilyMember(
    String familyMemberId,
    LatLng familyMemberLocation,
  ) async {
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Clear any existing polylines
      _polylines.clear();

      // Update the selected family member ID
      _selectedFamilyMemberId = familyMemberId;

      // Get directions that follow roads
      final List<LatLng> polylineCoordinates = await _getDirections(
        _currentLocation,
        familyMemberLocation,
      );

      // Calculate the distance
      final double distanceInKm = _calculatePolylineDistance(
        polylineCoordinates,
      );
      final String distanceText =
          distanceInKm < 1
              ? '${(distanceInKm * 1000).toStringAsFixed(0)} m'
              : '${distanceInKm.toStringAsFixed(1)} km';

      // Create a new polyline that follows roads
      final polyline = Polyline(
        polylineId: PolylineId('route_to_$familyMemberId'),
        points: polylineCoordinates,
        color: Colors.blue.shade700,
        width: 6,
        endCap: Cap.roundCap,
        startCap: Cap.roundCap,
      );

      // Find the family member's name
      final familyMemberMarker = _markers.firstWhere(
        (marker) => marker.markerId.value == 'family_$familyMemberId',
        orElse:
            () => Marker(
              markerId: MarkerId('not_found'),
              position: LatLng(0, 0),
              infoWindow: InfoWindow(title: 'Unknown Family Member'),
            ),
      );
      final familyMemberName =
          familyMemberMarker.infoWindow.title ?? 'Family Member';

      if (mounted) {
        setState(() {
          _polylines.add(polyline);
          _isLoading = false;
          _currentRouteDistance = distanceText;
          _selectedFamilyMemberName = familyMemberName;

          // Update the info window to include distance
          // We need to recreate the marker with updated info
          _updateMarkerWithDistance(
            familyMemberId,
            familyMemberLocation,
            distanceText,
          );
        });
      }

      // Safely animate camera to show the entire route
      if (mounted && _mapController != null && polylineCoordinates.isNotEmpty) {
        try {
          // Calculate bounds to include all points in the polyline
          double minLat = polylineCoordinates.first.latitude;
          double maxLat = polylineCoordinates.first.latitude;
          double minLng = polylineCoordinates.first.longitude;
          double maxLng = polylineCoordinates.first.longitude;

          for (var point in polylineCoordinates) {
            if (point.latitude < minLat) minLat = point.latitude;
            if (point.latitude > maxLat) maxLat = point.latitude;
            if (point.longitude < minLng) minLng = point.longitude;
            if (point.longitude > maxLng) maxLng = point.longitude;
          }

          final bounds = LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          );

          // Add a small delay to ensure the map is ready
          await Future.delayed(const Duration(milliseconds: 300));

          if (mounted && _mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 100), // 100 is padding
            );
          }
        } catch (cameraError) {
          debugPrint('Error animating camera: $cameraError');
          // Fallback to a simpler camera update if bounds calculation fails
          if (mounted && _mapController != null) {
            try {
              _mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(
                    (_currentLocation.latitude +
                            familyMemberLocation.latitude) /
                        2,
                    (_currentLocation.longitude +
                            familyMemberLocation.longitude) /
                        2,
                  ),
                  13, // Zoom level
                ),
              );
            } catch (e) {
              debugPrint('Fallback camera animation also failed: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error creating polyline: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Update a family member marker to include distance information
  void _updateMarkerWithDistance(
    String familyMemberId,
    LatLng location,
    String distance,
  ) {
    try {
      // Find if the marker exists
      final markerExists = _markers.any(
        (marker) => marker.markerId.value == 'family_$familyMemberId',
      );

      if (markerExists) {
        // Get the existing marker
        final existingMarker = _markers.firstWhere(
          (marker) => marker.markerId.value == 'family_$familyMemberId',
        );

        // Get the original info window data
        final originalTitle =
            existingMarker.infoWindow.title ?? 'Unknown Family Member';
        final originalSnippet = existingMarker.infoWindow.snippet ?? '';

        // Create updated marker with distance info
        final updatedMarker = Marker(
          markerId: existingMarker.markerId,
          position: existingMarker.position,
          icon: existingMarker.icon,
          infoWindow: InfoWindow(
            title: originalTitle,
            snippet: '$originalSnippet\nDistance: $distance',
          ),
          onTap: () async {
            await _createPolylineToFamilyMember(familyMemberId, location);
          },
        );

        // Replace the marker
        setState(() {
          _markers.remove(existingMarker);
          _markers.add(updatedMarker);
        });
      }
    } catch (e) {
      debugPrint('Error updating marker with distance: $e');
    }
  }

  /// Clears any existing polylines
  void _clearPolylines() {
    if (_polylines.isNotEmpty) {
      setState(() {
        _polylines.clear();
        _selectedFamilyMemberId = null;
        _currentRouteDistance = null;
        _selectedFamilyMemberName = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Map'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: Icon(
              _isLocationVisible ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: _toggleLocationVisibility,
            tooltip:
                _isLocationVisible ? 'Hide my location' : 'Show my location',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation,
                      zoom: 15,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                    mapType: MapType.normal,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    onTap: (_) => _clearPolylines(),
                  ),

                  // Distance indicator
                  if (_currentRouteDistance != null &&
                      _selectedFamilyMemberName != null)
                    Positioned(
                      bottom: 100,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(
                              red: 0,
                              green: 0,
                              blue: 0,
                              alpha: 179, // 0.7 * 255 = 179
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  red: 0,
                                  green: 0,
                                  blue: 0,
                                  alpha: 77, // 0.3 * 255 = 77
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Distance to $_selectedFamilyMemberName',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.directions_car,
                                    color: Colors.amber,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _currentRouteDistance!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
    );
  }
}
