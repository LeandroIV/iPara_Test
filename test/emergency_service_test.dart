import 'package:flutter_test/flutter_test.dart';
import 'package:ipara_new/models/emergency_contact_model.dart';

void main() {
  group('EmergencyContact Model Tests', () {
    test('EmergencyContact model should correctly parse from map data', () {
      // Create a mock map data
      final mockData = {
        'id': 'contact123',
        'name': 'John Doe',
        'phoneNumber': '+639123456789',
        'relationship': 'Family',
        'notifyInEmergency': true,
        'priority': 1,
      };

      // Create an EmergencyContact from the mock data
      final contact = EmergencyContact.fromMap(mockData);

      // Verify the model has the correct values
      expect(contact.id, 'contact123');
      expect(contact.name, 'John Doe');
      expect(contact.phoneNumber, '+639123456789');
      expect(contact.relationship, 'Family');
      expect(contact.notifyInEmergency, true);
      expect(contact.priority, 1);
    });

    test(
      'EmergencyContact copyWith should create a new instance with updated values',
      () {
        // Create an emergency contact
        final originalContact = EmergencyContact(
          id: 'contact123',
          name: 'John Doe',
          phoneNumber: '+639123456789',
          relationship: 'Family',
          notifyInEmergency: true,
          priority: 1,
        );

        // Create a copy with updated values
        final updatedContact = originalContact.copyWith(
          name: 'Jane Doe',
          phoneNumber: '+639987654321',
          notifyInEmergency: false,
        );

        // Verify original values are unchanged
        expect(originalContact.name, 'John Doe');
        expect(originalContact.phoneNumber, '+639123456789');
        expect(originalContact.notifyInEmergency, true);

        // Verify updated values
        expect(updatedContact.id, 'contact123'); // Unchanged
        expect(updatedContact.name, 'Jane Doe'); // Changed
        expect(updatedContact.phoneNumber, '+639987654321'); // Changed
        expect(updatedContact.relationship, 'Family'); // Unchanged
        expect(updatedContact.notifyInEmergency, false); // Changed
        expect(updatedContact.priority, 1); // Unchanged
      },
    );
  });

  group('EmergencyAlert Model Tests', () {
    test('EmergencyAlertStatus should have correct string representations', () {
      expect(EmergencyAlertStatus.active.name, 'Active');
      expect(EmergencyAlertStatus.responded.name, 'Responded');
      expect(EmergencyAlertStatus.resolved.name, 'Resolved');
      expect(EmergencyAlertStatus.cancelled.name, 'Cancelled');
    });
  });
}
