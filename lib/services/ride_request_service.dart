import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ride_request_model.dart';
import '../models/driver_location_model.dart';

class RideRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection references
  final CollectionReference _rideRequestsCollection;
  final CollectionReference _driverLocationsCollection;
  final CollectionReference _commuterLocationsCollection;
  
  // Stream controllers
  final StreamController<List<RideRequest>> _commuterRequestsController = 
      StreamController<List<RideRequest>>.broadcast();
  final StreamController<List<RideRequest>> _driverRequestsController = 
      StreamController<List<RideRequest>>.broadcast();
  
  // Getters for the streams
  Stream<List<RideRequest>> get commuterRequests => _commuterRequestsController.stream;
  Stream<List<RideRequest>> get driverRequests => _driverRequestsController.stream;
  
  // Constructor
  RideRequestService() 
      : _rideRequestsCollection = FirebaseFirestore.instance.collection('ride_requests'),
        _driverLocationsCollection = FirebaseFirestore.instance.collection('driver_locations'),
        _commuterLocationsCollection = FirebaseFirestore.instance.collection('commuter_locations') {
    // Initialize listeners
    _initListeners();
  }
  
  // Initialize listeners for ride requests
  void _initListeners() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    // Listen for commuter's ride requests
    _rideRequestsCollection
        .where('commuterId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      final requests = snapshot.docs
          .map((doc) => RideRequest.fromFirestore(doc))
          .toList();
      _commuterRequestsController.add(requests);
    });
    
    // Listen for driver's ride requests
    _rideRequestsCollection
        .where('driverId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      final requests = snapshot.docs
          .map((doc) => RideRequest.fromFirestore(doc))
          .toList();
      _driverRequestsController.add(requests);
    });
  }
  
  // Create a new ride request
  Future<RideRequest?> createRideRequest({
    required String driverId,
    required LatLng driverLocation,
    required String puvType,
    String? driverName,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('User not logged in');
        return null;
      }
      
      // Get commuter's current location
      final position = await Geolocator.getCurrentPosition();
      final commuterLocation = LatLng(position.latitude, position.longitude);
      
      // Get commuter's name from Firestore
      String? commuterName;
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        commuterName = userDoc.data()?['displayName'];
      }
      
      // Calculate distance and ETA
      final distanceInMeters = Geolocator.distanceBetween(
        commuterLocation.latitude,
        commuterLocation.longitude,
        driverLocation.latitude,
        driverLocation.longitude,
      );
      
      final distanceKm = distanceInMeters / 1000;
      final etaMinutes = _calculateEta(distanceKm);
      
      // Create the ride request document
      final now = DateTime.now();
      final requestData = {
        'commuterId': userId,
        'commuterName': commuterName,
        'commuterLocation': GeoPoint(commuterLocation.latitude, commuterLocation.longitude),
        'driverId': driverId,
        'driverName': driverName,
        'driverLocation': GeoPoint(driverLocation.latitude, driverLocation.longitude),
        'puvType': puvType,
        'distanceKm': distanceKm,
        'etaMinutes': etaMinutes,
        'status': RideRequestStatus.pending.index,
        'createdAt': now,
        'updatedAt': now,
      };
      
      // Add to Firestore
      final docRef = await _rideRequestsCollection.add(requestData);
      
      // Return the created request
      return RideRequest(
        id: docRef.id,
        commuterId: userId,
        commuterName: commuterName,
        commuterLocation: commuterLocation,
        driverId: driverId,
        driverName: driverName,
        driverLocation: driverLocation,
        puvType: puvType,
        distanceKm: distanceKm,
        etaMinutes: etaMinutes,
        status: RideRequestStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      debugPrint('Error creating ride request: $e');
      return null;
    }
  }
  
  // Update the status of a ride request
  Future<bool> updateRequestStatus(String requestId, RideRequestStatus status) async {
    try {
      await _rideRequestsCollection.doc(requestId).update({
        'status': status.index,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating ride request status: $e');
      return false;
    }
  }
  
  // Get a specific ride request
  Future<RideRequest?> getRideRequest(String requestId) async {
    try {
      final doc = await _rideRequestsCollection.doc(requestId).get();
      if (doc.exists) {
        return RideRequest.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting ride request: $e');
      return null;
    }
  }
  
  // Get the nearest driver for a specific PUV type
  Future<DriverLocation?> getNearestDriver(String puvType) async {
    try {
      // Get current location
      final position = await Geolocator.getCurrentPosition();
      final userLocation = LatLng(position.latitude, position.longitude);
      
      // Query online drivers with the specified PUV type
      final snapshot = await _driverLocationsCollection
          .where('isOnline', isEqualTo: true)
          .where('isLocationVisible', isEqualTo: true)
          .where('puvType', isEqualTo: puvType)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return null;
      }
      
      // Find the nearest driver
      DriverLocation? nearestDriver;
      double minDistance = double.infinity;
      
      for (final doc in snapshot.docs) {
        final driver = DriverLocation.fromFirestore(doc);
        final distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          driver.location.latitude,
          driver.location.longitude,
        );
        
        if (distance < minDistance) {
          minDistance = distance;
          nearestDriver = driver;
        }
      }
      
      return nearestDriver;
    } catch (e) {
      debugPrint('Error finding nearest driver: $e');
      return null;
    }
  }
  
  // Calculate ETA based on distance (assuming average speed of 40 km/h)
  int _calculateEta(double distanceKm, {double speedKmh = 40.0}) {
    return (distanceKm / speedKmh * 60).round(); // Convert to minutes
  }
  
  // Dispose resources
  void dispose() {
    _commuterRequestsController.close();
    _driverRequestsController.close();
  }
}
