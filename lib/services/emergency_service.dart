import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/emergency_contact_model.dart';

/// Service class for handling emergency functionality
class EmergencyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get collection reference for emergency contacts
  CollectionReference<Map<String, dynamic>> get _contactsCollection =>
      _firestore.collection('emergency_contacts');

  /// Get collection reference for emergency alerts
  CollectionReference<Map<String, dynamic>> get _alertsCollection =>
      _firestore.collection('emergency_alerts');

  /// Get collection reference for family groups
  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _firestore.collection('family_groups');

  /// Get the current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Add a new emergency contact
  Future<String?> addEmergencyContact(EmergencyContact contact) async {
    if (_currentUserId == null) return null;

    try {
      // Check if the user already has a document in the contacts collection
      final userContactsDoc =
          await _contactsCollection.doc(_currentUserId).get();

      if (userContactsDoc.exists) {
        // User already has contacts, add this one to the array
        final contacts = List<Map<String, dynamic>>.from(
          userContactsDoc.data()?['contacts'] ?? [],
        );

        // Generate a unique ID for this contact
        final contactId = DateTime.now().millisecondsSinceEpoch.toString();
        final contactWithId = contact.copyWith(id: contactId);

        contacts.add(contactWithId.toMap());

        await _contactsCollection.doc(_currentUserId).update({
          'contacts': contacts,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return contactId;
      } else {
        // User doesn't have contacts yet, create the document
        final contactId = DateTime.now().millisecondsSinceEpoch.toString();
        final contactWithId = contact.copyWith(id: contactId);

        await _contactsCollection.doc(_currentUserId).set({
          'userId': _currentUserId,
          'contacts': [contactWithId.toMap()],
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return contactId;
      }
    } catch (e) {
      debugPrint('Error adding emergency contact: $e');
      return null;
    }
  }

  /// Update an existing emergency contact
  Future<bool> updateEmergencyContact(EmergencyContact contact) async {
    if (_currentUserId == null) return false;

    try {
      final userContactsDoc =
          await _contactsCollection.doc(_currentUserId).get();
      if (!userContactsDoc.exists) return false;

      final contacts = List<Map<String, dynamic>>.from(
        userContactsDoc.data()?['contacts'] ?? [],
      );

      // Find the contact to update
      final index = contacts.indexWhere((c) => c['id'] == contact.id);
      if (index == -1) return false;

      // Update the contact
      contacts[index] = contact.toMap();

      await _contactsCollection.doc(_currentUserId).update({
        'contacts': contacts,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error updating emergency contact: $e');
      return false;
    }
  }

  /// Delete an emergency contact
  Future<bool> deleteEmergencyContact(String contactId) async {
    if (_currentUserId == null) return false;

    try {
      final userContactsDoc =
          await _contactsCollection.doc(_currentUserId).get();
      if (!userContactsDoc.exists) return false;

      final contacts = List<Map<String, dynamic>>.from(
        userContactsDoc.data()?['contacts'] ?? [],
      );

      // Remove the contact
      contacts.removeWhere((c) => c['id'] == contactId);

      await _contactsCollection.doc(_currentUserId).update({
        'contacts': contacts,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error deleting emergency contact: $e');
      return false;
    }
  }

  /// Get all emergency contacts for the current user
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    if (_currentUserId == null) return [];

    try {
      final userContactsDoc =
          await _contactsCollection.doc(_currentUserId).get();
      if (!userContactsDoc.exists) return [];

      final contacts = List<Map<String, dynamic>>.from(
        userContactsDoc.data()?['contacts'] ?? [],
      );

      return contacts.map((c) => EmergencyContact.fromMap(c)).toList()
        ..sort((a, b) => a.priority.compareTo(b.priority));
    } catch (e) {
      debugPrint('Error getting emergency contacts: $e');
      return [];
    }
  }

  /// Create an emergency alert
  Future<String?> createEmergencyAlert({
    required LatLng location,
    String? notes,
    bool notifyContacts = true,
    bool callPolice = false,
  }) async {
    if (_currentUserId == null) return null;

    try {
      // Get user details
      final userDoc =
          await _firestore.collection('users').doc(_currentUserId).get();
      final userName = userDoc.data()?['displayName'] ?? 'Unknown User';

      // Create the alert
      final alertData = {
        'userId': _currentUserId,
        'userName': userName,
        'location': GeoPoint(location.latitude, location.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'status': EmergencyAlertStatus.active.index,
        'notifiedContacts': [],
        'notes': notes,
      };

      final alertRef = await _alertsCollection.add(alertData);

      // Notify emergency contacts if requested
      if (notifyContacts) {
        await _notifyEmergencyContacts(alertRef.id, location);
      }

      // Call police if requested
      if (callPolice) {
        await _callEmergencyServices();
      }

      return alertRef.id;
    } catch (e) {
      debugPrint('Error creating emergency alert: $e');
      return null;
    }
  }

  /// Notify emergency contacts about an alert
  Future<void> _notifyEmergencyContacts(String alertId, LatLng location) async {
    if (_currentUserId == null) return;

    try {
      // Get the user's emergency contacts
      final contacts = await getEmergencyContacts();
      final notifiedContacts = <String>[];

      // In a real app, this would send SMS or push notifications to contacts
      // For now, we'll just mark them as notified in the alert
      for (final contact in contacts) {
        if (contact.notifyInEmergency) {
          notifiedContacts.add(contact.id);

          // In a real implementation, you would send SMS here
          debugPrint('Would notify ${contact.name} at ${contact.phoneNumber}');
        }
      }

      // Update the alert with the notified contacts
      if (notifiedContacts.isNotEmpty) {
        await _alertsCollection.doc(alertId).update({
          'notifiedContacts': notifiedContacts,
        });
      }
    } catch (e) {
      debugPrint('Error notifying emergency contacts: $e');
    }
  }

  /// Call emergency services (police)
  Future<void> _callEmergencyServices() async {
    try {
      // In the Philippines, 911 is the emergency number
      const phoneNumber = '911';

      // For now, just log that we would call emergency services
      // In a real implementation, we would use the url_launcher package
      // to make the actual call
      debugPrint('EMERGENCY: Would call emergency services at $phoneNumber');

      // Show a notification to the user that they need to manually call
      // emergency services for now
    } catch (e) {
      debugPrint('Error calling emergency services: $e');
    }
  }

  /// Update the status of an emergency alert
  Future<bool> updateAlertStatus(
    String alertId,
    EmergencyAlertStatus status,
  ) async {
    if (_currentUserId == null) return false;

    try {
      final alertDoc = await _alertsCollection.doc(alertId).get();
      if (!alertDoc.exists) return false;

      // Check if this is the user's alert
      final alertData = alertDoc.data() as Map<String, dynamic>;
      if (alertData['userId'] != _currentUserId) return false;

      await _alertsCollection.doc(alertId).update({'status': status.index});

      return true;
    } catch (e) {
      debugPrint('Error updating alert status: $e');
      return false;
    }
  }

  /// Get all emergency alerts for the current user
  Future<List<EmergencyAlert>> getUserAlerts() async {
    if (_currentUserId == null) return [];

    try {
      final querySnapshot =
          await _alertsCollection
              .where('userId', isEqualTo: _currentUserId)
              .orderBy('timestamp', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => EmergencyAlert.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user alerts: $e');
      return [];
    }
  }

  /// Sync family members as emergency contacts
  Future<bool> syncFamilyMembersAsContacts() async {
    if (_currentUserId == null) return false;

    try {
      // Get the user's current family group ID
      final userDoc =
          await _firestore.collection('users').doc(_currentUserId).get();
      final familyGroupId = userDoc.data()?['familyGroupId'];

      if (familyGroupId == null) {
        return false; // User is not in a family group
      }

      // Get the family group document
      final groupDoc =
          await _firestore.collection('family_groups').doc(familyGroupId).get();
      if (!groupDoc.exists) {
        return false;
      }

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final members = List<String>.from(groupData['members'] ?? []);

      // Remove the current user from the list
      members.remove(_currentUserId);

      if (members.isEmpty) {
        return false; // No other family members
      }

      // Get existing emergency contacts
      final existingContacts = await getEmergencyContacts();
      final existingContactIds = existingContacts.map((c) => c.id).toList();

      // Get details for each family member
      bool anyAdded = false;
      for (final memberId in members) {
        final memberDoc =
            await _firestore.collection('users').doc(memberId).get();
        if (memberDoc.exists) {
          final userData = memberDoc.data() as Map<String, dynamic>;
          final displayName = userData['displayName'] ?? 'Family Member';
          final phoneNumber = userData['phoneNumber'] ?? 'N/A';
          final email = userData['email'] ?? '';

          // Check if this member is already an emergency contact
          final memberContactId = 'family_$memberId';
          if (!existingContactIds.contains(memberContactId)) {
            // Create a new emergency contact for this family member
            final newContact = EmergencyContact(
              id: memberContactId,
              name: displayName,
              phoneNumber: phoneNumber,
              email: email,
              relationship: 'Family',
              notifyInEmergency: true,
              priority: 1, // Family members get highest priority
            );

            // Add the contact
            await addEmergencyContact(newContact);
            anyAdded = true;
          }
        }
      }

      return anyAdded;
    } catch (e) {
      debugPrint('Error syncing family members as contacts: $e');
      return false;
    }
  }
}
