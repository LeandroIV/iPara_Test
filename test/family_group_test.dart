import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipara_new/models/family_group_model.dart';

void main() {
  group('FamilyGroup Model Tests', () {
    test('FamilyGroup model should correctly parse from Firestore data', () {
      // Create a mock Firestore document data
      final mockData = {
        'hostId': 'user123',
        'groupName': 'Test Family',
        'inviteCode': 'ABC123',
        'createdAt': DateTime.now(),
        'memberLimit': 5,
        'members': ['user123', 'user456'],
        'isActive': true,
      };

      // Create a FamilyGroup from the mock data
      final familyGroup = FamilyGroup(
        id: 'group123',
        hostId: mockData['hostId'] as String,
        groupName: mockData['groupName'] as String,
        inviteCode: mockData['inviteCode'] as String,
        createdAt: mockData['createdAt'] as DateTime,
        memberLimit: mockData['memberLimit'] as int,
        members: List<String>.from(mockData['members'] as List),
        isActive: mockData['isActive'] as bool,
      );

      // Verify the model has the correct values
      expect(familyGroup.id, 'group123');
      expect(familyGroup.hostId, 'user123');
      expect(familyGroup.groupName, 'Test Family');
      expect(familyGroup.inviteCode, 'ABC123');
      expect(familyGroup.memberLimit, 5);
      expect(familyGroup.members, ['user123', 'user456']);
      expect(familyGroup.isActive, true);
    });

    test(
      'FamilyGroup copyWith should create a new instance with updated values',
      () {
        // Create a family group
        final originalGroup = FamilyGroup(
          id: 'group123',
          hostId: 'user123',
          groupName: 'Original Name',
          inviteCode: 'ABC123',
          createdAt: DateTime(2023, 1, 1),
          memberLimit: 5,
          members: ['user123'],
          isActive: true,
        );

        // Create a copy with updated values
        final updatedGroup = originalGroup.copyWith(
          groupName: 'Updated Name',
          members: ['user123', 'user456'],
          isActive: false,
        );

        // Verify original values are unchanged
        expect(originalGroup.groupName, 'Original Name');
        expect(originalGroup.members, ['user123']);
        expect(originalGroup.isActive, true);

        // Verify updated values
        expect(updatedGroup.id, 'group123'); // Unchanged
        expect(updatedGroup.hostId, 'user123'); // Unchanged
        expect(updatedGroup.groupName, 'Updated Name'); // Changed
        expect(updatedGroup.inviteCode, 'ABC123'); // Unchanged
        expect(updatedGroup.createdAt, DateTime(2023, 1, 1)); // Unchanged
        expect(updatedGroup.memberLimit, 5); // Unchanged
        expect(updatedGroup.members, ['user123', 'user456']); // Changed
        expect(updatedGroup.isActive, false); // Changed
      },
    );
  });
}
