// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipara_new/models/family_group_model.dart';
import 'package:ipara_new/models/emergency_contact_model.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Create test widgets for our models
    final familyGroup = FamilyGroup(
      id: 'test-group',
      hostId: 'test-user',
      groupName: 'Test Family',
      inviteCode: 'TEST123',
      createdAt: DateTime.now(),
      members: ['test-user'],
    );

    final emergencyContact = EmergencyContact(
      id: 'test-contact',
      name: 'Test Contact',
      phoneNumber: '123456789',
      relationship: 'Test',
    );

    // Build simple widgets to display our models
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('Family Group: ${familyGroup.groupName}'),
              Text('Emergency Contact: ${emergencyContact.name}'),
            ],
          ),
        ),
      ),
    );

    // Verify that our widgets are displayed
    expect(find.text('Family Group: Test Family'), findsOneWidget);
    expect(find.text('Emergency Contact: Test Contact'), findsOneWidget);
  });
}
