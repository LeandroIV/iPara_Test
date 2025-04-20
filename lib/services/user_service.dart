import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_role.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static const String _roleKey = 'user_role';

  // Save user role to local storage
  static Future<void> saveUserRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_roleKey, role.index);

    // Also save to Firestore if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        print('Saving user role to Firestore: ${role.name}');
        // Use set with merge option instead of update, so it works even if the document doesn't exist
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {
            'role': role.index,
            'updatedAt': FieldValue.serverTimestamp(),
            // Ensure these fields exist in case this is first creation
            'email': user.email,
            'displayName':
                user.displayName ?? user.email?.split('@')[0] ?? 'User',
          },
          SetOptions(
            merge: true,
          ), // This allows updating without overwriting the entire document
        );
        print('User role saved successfully to Firestore: ${role.name}');
      } catch (e) {
        print('Error saving user role to Firestore: $e');
        // Rethrow to handle in UI
        throw e;
      }
    } else {
      print('No authenticated user found when trying to save role');
    }
  }

  // Get user role from local storage
  static Future<UserRole?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleIndex = prefs.getInt(_roleKey);
    if (roleIndex == null) {
      return null;
    }
    return UserRole.values[roleIndex];
  }

  // Check if user has selected a role
  static Future<bool> hasSelectedRole() async {
    final role = await getUserRole();
    return role != null;
  }

  // Clear user role (for logout)
  static Future<void> clearUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
  }

  // Get user role from Firestore
  static Future<UserRole?> fetchUserRoleFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists && doc.data()?['role'] != null) {
        final roleIndex = doc.data()?['role'] as int;
        return UserRole.values[roleIndex];
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }

    return null;
  }

  // Sync local role with Firestore
  static Future<void> syncUserRole() async {
    final firestoreRole = await fetchUserRoleFromFirestore();
    final localRole = await getUserRole();

    if (firestoreRole != null && firestoreRole != localRole) {
      await saveUserRole(firestoreRole);
    } else if (localRole != null && firestoreRole == null) {
      // Local role exists but not in Firestore, update Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'role': localRole.index});
      }
    }
  }
}
