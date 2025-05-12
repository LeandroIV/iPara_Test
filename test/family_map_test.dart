import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipara_new/models/family_member_location_model.dart';
import 'package:ipara_new/screens/family/family_map_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:ipara_new/services/family_group_service.dart';

// Mock FamilyGroupService
class MockFamilyGroupService extends Mock implements FamilyGroupService {
  @override
  Stream<List<FamilyMemberLocation>> getFamilyMemberLocations(String groupId) {
    // Return a mock stream with test data
    return Stream.value([
      FamilyMemberLocation(
        userId: 'user1',
        location: const LatLng(8.4542, 124.6319),
        groupId: 'group1',
        isVisible: true,
        lastUpdated: DateTime.now(),
        displayName: 'Test User 1',
        userRole: 'commuter',
      ),
      FamilyMemberLocation(
        userId: 'user2',
        location: const LatLng(8.4642, 124.6419),
        groupId: 'group1',
        isVisible: true,
        lastUpdated: DateTime.now(),
        displayName: 'Test User 2',
        userRole: 'driver',
      ),
    ]);
  }
}

void main() {
  testWidgets('FamilyMapScreen shows family members on map', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        home: FamilyMapScreen(groupId: 'group1'),
      ),
    );

    // Verify that the loading indicator is shown initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the map to load
    await tester.pumpAndSettle();

    // Verify that the Google Map is displayed
    expect(find.byType(GoogleMap), findsOneWidget);

    // Verify that the visibility toggle button is present
    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });
}
