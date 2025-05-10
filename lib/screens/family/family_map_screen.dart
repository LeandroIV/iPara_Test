import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../services/family_group_service.dart';

class FamilyMapScreen extends StatefulWidget {
  final String groupId;

  const FamilyMapScreen({super.key, required this.groupId});

  @override
  State<FamilyMapScreen> createState() => _FamilyMapScreenState();
}

class _FamilyMapScreenState extends State<FamilyMapScreen> {
  final FamilyGroupService _groupService = FamilyGroupService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  List<String> _memberIds = [];
  bool _isLoading = true;
  bool _isLocationVisible = true;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _membersLocationSubscription;
  
  // Default location (will be updated with user's location)
  LatLng _currentLocation = const LatLng(8.4542, 124.6319); // CDO, Philippines

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _membersLocationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyMembers() async {
    try {
      final members = await _groupService.getFamilyGroupMembers(widget.groupId);
      setState(() {
        _memberIds = members.map((m) => m['userId'] as String).toList();
        _isLoading = false;
      });
      
      // Start tracking family members' locations
      _startTrackingMembersLocation();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading family members: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      
      // Update camera position if map controller is available
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation, 15),
      );
      
      // Start tracking current user's location
      _startTrackingUserLocation();
      
      // Update user's location in Firestore
      _updateUserLocation(position);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  void _startTrackingUserLocation() {
    // Cancel any existing subscription
    _locationSubscription?.cancel();
    
    // Set up the location stream
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      
      // Update user's location in Firestore
      _updateUserLocation(position);
    });
  }

  Future<void> _updateUserLocation(Position position) async {
    if (!_isLocationVisible) return;
    
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    try {
      await _firestore.collection('family_member_locations').doc(userId).set({
        'userId': userId,
        'groupId': widget.groupId,
        'location': GeoPoint(position.latitude, position.longitude),
        'heading': position.heading,
        'speed': position.speed,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isVisible': _isLocationVisible,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  void _startTrackingMembersLocation() {
    // Cancel any existing subscription
    _membersLocationSubscription?.cancel();
    
    // Set up the stream to listen for family members' locations
    _membersLocationSubscription = _firestore
        .collection('family_member_locations')
        .where('groupId', isEqualTo: widget.groupId)
        .where('isVisible', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      _updateMemberMarkers(snapshot);
    });
  }

  void _updateMemberMarkers(QuerySnapshot snapshot) async {
    // Clear existing markers except the user's marker
    final currentUserId = _auth.currentUser?.uid;
    _markers.removeWhere((marker) => 
      marker.markerId.value != 'user_location' && 
      marker.markerId.value != 'current_user'
    );
    
    // Add markers for each family member
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final userId = data['userId'] as String;
      
      // Skip the current user
      if (userId == currentUserId) continue;
      
      // Get the location
      final geoPoint = data['location'] as GeoPoint;
      final location = LatLng(geoPoint.latitude, geoPoint.longitude);
      
      // Get user details
      String userName = 'Family Member';
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          userName = userDoc.data()?['displayName'] ?? 'Family Member';
        }
      } catch (e) {
        debugPrint('Error getting user details: $e');
      }
      
      // Create the marker
      final marker = Marker(
        markerId: MarkerId('family_$userId'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: userName,
          snippet: 'Last updated: ${DateTime.now().toString().split('.')[0]}',
        ),
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
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
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
    
    // Update visibility in Firestore
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      _firestore.collection('family_member_locations').doc(userId).update({
        'isVisible': _isLocationVisible,
      });
    }
    
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Map'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: Icon(_isLocationVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: _toggleLocationVisibility,
            tooltip: _isLocationVisible ? 'Hide my location' : 'Show my location',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation,
                    zoom: 15,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapType: MapType.normal,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _getCurrentLocation,
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
    );
  }
}
