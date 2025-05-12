import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'dart:async';
import '../models/family_group_model.dart';
import '../models/family_member_location_model.dart';

/// Service class for handling family group functionality
class FamilyGroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<Position>? _positionStream;
  bool _isLocationVisible = true;
  String? _currentGroupId;

  /// Get collection reference for family groups
  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _firestore.collection('family_groups');

  /// Get collection reference for family member locations
  CollectionReference<Map<String, dynamic>>
  get _familyMemberLocationsCollection =>
      _firestore.collection('family_member_locations');

  /// Get the current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Generate a unique invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6, // 6-character code
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Create a new family group
  Future<FamilyGroup?> createFamilyGroup(String groupName) async {
    if (_currentUserId == null) return null;

    try {
      // Generate a unique invite code
      final inviteCode = _generateInviteCode();

      // Create the group data
      final groupData = {
        'hostId': _currentUserId,
        'groupName': groupName,
        'inviteCode': inviteCode,
        'createdAt': FieldValue.serverTimestamp(),
        'memberLimit': 5,
        'members': [_currentUserId],
        'isActive': true,
      };

      // Add to Firestore
      final docRef = await _groupsCollection.add(groupData);

      // Update the user's record to include the group ID
      await _firestore.collection('users').doc(_currentUserId).update({
        'familyGroupId': docRef.id,
        'isSubscribed': true,
      });

      // Get the created document
      final doc = await docRef.get();
      return FamilyGroup.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error creating family group: $e');
      return null;
    }
  }

  /// Join an existing family group using an invite code
  Future<bool> joinFamilyGroup(String inviteCode) async {
    if (_currentUserId == null) return false;

    try {
      // Find the group with this invite code
      final querySnapshot =
          await _groupsCollection
              .where('inviteCode', isEqualTo: inviteCode)
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        return false; // No active group found with this code
      }

      final groupDoc = querySnapshot.docs.first;
      final groupData = groupDoc.data();

      // Check if the group has reached its member limit
      final members = List<String>.from(groupData['members'] ?? []);
      if (members.length >= (groupData['memberLimit'] ?? 5)) {
        return false; // Group is full
      }

      // Check if user is already a member
      if (members.contains(_currentUserId)) {
        return true; // Already a member, consider this a success
      }

      // Add the user to the group
      members.add(_currentUserId!);
      await groupDoc.reference.update({'members': members});

      // Update the user's record
      await _firestore.collection('users').doc(_currentUserId).update({
        'familyGroupId': groupDoc.id,
      });

      return true;
    } catch (e) {
      debugPrint('Error joining family group: $e');
      return false;
    }
  }

  /// Leave a family group
  Future<bool> leaveFamilyGroup() async {
    if (_currentUserId == null) return false;

    try {
      // Get the user's current group
      final userDoc =
          await _firestore.collection('users').doc(_currentUserId).get();
      final familyGroupId = userDoc.data()?['familyGroupId'];

      if (familyGroupId == null) {
        return false; // User is not in a group
      }

      // Get the group
      final groupDoc = await _groupsCollection.doc(familyGroupId).get();
      if (!groupDoc.exists) {
        // Group doesn't exist, just remove the reference from the user
        await _firestore.collection('users').doc(_currentUserId).update({
          'familyGroupId': FieldValue.delete(),
        });
        return true;
      }

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final members = List<String>.from(groupData['members'] ?? []);

      // Remove the user from the members list
      members.remove(_currentUserId);

      if (members.isEmpty) {
        // If no members left, delete or deactivate the group
        await groupDoc.reference.update({'isActive': false});
      } else if (groupData['hostId'] == _currentUserId) {
        // If the host is leaving, assign a new host
        await groupDoc.reference.update({
          'members': members,
          'hostId': members.first,
        });
      } else {
        // Just update the members list
        await groupDoc.reference.update({'members': members});
      }

      // Remove the group reference from the user
      await _firestore.collection('users').doc(_currentUserId).update({
        'familyGroupId': FieldValue.delete(),
      });

      return true;
    } catch (e) {
      debugPrint('Error leaving family group: $e');
      return false;
    }
  }

  /// Get the user's current family group
  Future<FamilyGroup?> getCurrentFamilyGroup() async {
    if (_currentUserId == null) return null;

    try {
      // Get the user's current group ID
      final userDoc =
          await _firestore.collection('users').doc(_currentUserId).get();
      final familyGroupId = userDoc.data()?['familyGroupId'];

      if (familyGroupId == null) {
        return null; // User is not in a group
      }

      // Get the group
      final groupDoc = await _groupsCollection.doc(familyGroupId).get();
      if (!groupDoc.exists) {
        return null;
      }

      return FamilyGroup.fromFirestore(groupDoc);
    } catch (e) {
      debugPrint('Error getting family group: $e');
      return null;
    }
  }

  /// Get a stream of the user's current family group
  Stream<FamilyGroup?> getCurrentFamilyGroupStream() {
    if (_currentUserId == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .snapshots()
        .asyncMap((userDoc) async {
          if (!userDoc.exists) return null;

          final familyGroupId = userDoc.data()?['familyGroupId'];
          if (familyGroupId == null) return null;

          final groupDoc = await _groupsCollection.doc(familyGroupId).get();
          if (!groupDoc.exists) return null;

          return FamilyGroup.fromFirestore(groupDoc);
        });
  }

  /// Get family group members with their details
  Future<List<Map<String, dynamic>>> getFamilyGroupMembers(
    String groupId,
  ) async {
    try {
      final groupDoc = await _groupsCollection.doc(groupId).get();
      if (!groupDoc.exists) return [];

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final members = List<String>.from(groupData['members'] ?? []);

      if (members.isEmpty) return [];

      // Get details for each member
      final memberDetails = <Map<String, dynamic>>[];

      for (final memberId in members) {
        final userDoc =
            await _firestore.collection('users').doc(memberId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          memberDetails.add({
            'userId': memberId,
            'displayName': userData['displayName'] ?? 'Unknown User',
            'email': userData['email'] ?? '',
            'isHost': memberId == groupData['hostId'],
            'role': userData['role'] ?? 0,
            'photoUrl': userData['photoUrl'],
          });
        }
      }

      return memberDetails;
    } catch (e) {
      debugPrint('Error getting family group members: $e');
      return [];
    }
  }

  /// Start tracking the user's location for family members
  Future<void> startFamilyLocationSharing({bool isVisible = true}) async {
    if (_currentUserId == null) return;

    // Get the current family group
    final group = await getCurrentFamilyGroup();
    if (group == null) return;

    _currentGroupId = group.id;
    _isLocationVisible = isVisible;

    // Cancel any existing location tracking
    await stopFamilyLocationSharing();

    // Get user details
    final userDoc =
        await _firestore.collection('users').doc(_currentUserId).get();
    final userData = userDoc.data();

    // Set up location tracking
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) async {
      // Update location in Firestore
      await _firestore
          .collection('family_member_locations')
          .doc(_currentUserId)
          .set({
            'userId': _currentUserId,
            'groupId': _currentGroupId,
            'location': GeoPoint(position.latitude, position.longitude),
            'isVisible': _isLocationVisible,
            'lastUpdated': FieldValue.serverTimestamp(),
            'displayName': userData?['displayName'] ?? 'Family Member',
            'photoUrl': userData?['photoUrl'],
            'userRole':
                userData?['role'] != null
                    ? _getUserRoleName(userData!['role'])
                    : 'commuter',
          }, SetOptions(merge: true));
    });
  }

  /// Stop tracking the user's location for family members
  Future<void> stopFamilyLocationSharing() async {
    await _positionStream?.cancel();
    _positionStream = null;

    // Update visibility status in Firestore
    if (_currentUserId != null) {
      await _firestore
          .collection('family_member_locations')
          .doc(_currentUserId)
          .update({'isVisible': false})
          .catchError((e) {
            // Ignore errors if document doesn't exist
            debugPrint('Error updating visibility: $e');
          });
    }
  }

  /// Update the visibility of the user's location
  Future<void> updateLocationVisibility(bool isVisible) async {
    _isLocationVisible = isVisible;

    if (_currentUserId != null) {
      await _firestore
          .collection('family_member_locations')
          .doc(_currentUserId)
          .update({'isVisible': isVisible})
          .catchError((e) {
            // Ignore errors if document doesn't exist
            debugPrint('Error updating visibility: $e');
          });
    }
  }

  /// Get a stream of family member locations for a specific group
  Stream<List<FamilyMemberLocation>> getFamilyMemberLocations(String groupId) {
    return _firestore
        .collection('family_member_locations')
        .where('groupId', isEqualTo: groupId)
        .where('isVisible', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FamilyMemberLocation.fromFirestore(doc))
              .toList();
        });
  }

  /// Helper method to convert role index to string
  String _getUserRoleName(int roleIndex) {
    switch (roleIndex) {
      case 0:
        return 'commuter';
      case 1:
        return 'driver';
      case 2:
        return 'operator';
      default:
        return 'commuter';
    }
  }

  /// Clean up resources
  void dispose() {
    _positionStream?.cancel();
  }
}
