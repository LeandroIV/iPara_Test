import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/vehicle_model.dart';
import 'notification_service.dart';

/// Service class for handling vehicle and maintenance data
class VehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get collection reference for vehicles
  CollectionReference<Map<String, dynamic>> get _vehiclesCollection =>
      _firestore.collection('vehicles');

  /// Get the current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Fetch all vehicles for the current operator
  Future<List<Vehicle>> getOperatorVehicles() async {
    if (_currentUserId == null) return [];

    try {
      final querySnapshot =
          await _vehiclesCollection
              .where('operatorId', isEqualTo: _currentUserId)
              .orderBy('plateNumber')
              .get();

      return querySnapshot.docs
          .map((doc) => Vehicle.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching operator vehicles: $e');
      return [];
    }
  }

  /// Fetch vehicles assigned to the current driver
  Future<List<Vehicle>> getDriverVehicles() async {
    if (_currentUserId == null) return [];

    try {
      final querySnapshot =
          await _vehiclesCollection
              .where('driverId', isEqualTo: _currentUserId)
              .where('isActive', isEqualTo: true)
              .get();

      return querySnapshot.docs
          .map((doc) => Vehicle.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching driver vehicles: $e');
      return [];
    }
  }

  /// Get a vehicle by ID
  Future<Vehicle?> getVehicleById(String vehicleId) async {
    try {
      final docSnapshot = await _vehiclesCollection.doc(vehicleId).get();

      if (docSnapshot.exists) {
        return Vehicle.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching vehicle by ID: $e');
      return null;
    }
  }

  /// Add a new vehicle
  Future<String?> addVehicle(Vehicle vehicle) async {
    if (_currentUserId == null) return null;

    try {
      // Ensure the current user is set as the operator
      final vehicleData =
          vehicle.copyWith(operatorId: _currentUserId).toFirestore();

      final docRef = await _vehiclesCollection.add(vehicleData);
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding vehicle: $e');
      return null;
    }
  }

  /// Update an existing vehicle
  Future<bool> updateVehicle(Vehicle vehicle) async {
    try {
      await _vehiclesCollection.doc(vehicle.id).update(vehicle.toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error updating vehicle: $e');
      return false;
    }
  }

  /// Delete a vehicle
  Future<bool> deleteVehicle(String vehicleId) async {
    try {
      await _vehiclesCollection.doc(vehicleId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting vehicle: $e');
      return false;
    }
  }

  /// Add a maintenance reminder to a vehicle
  Future<bool> addMaintenanceReminder(
    String vehicleId,
    MaintenanceReminder reminder,
  ) async {
    try {
      // Get the current vehicle
      final vehicle = await getVehicleById(vehicleId);
      if (vehicle == null) return false;

      // Add the reminder to the list
      final updatedReminders = [...vehicle.maintenanceReminders, reminder];

      // Update the vehicle with the new reminders list
      final updatedVehicle = vehicle.copyWith(
        maintenanceReminders: updatedReminders,
      );
      final result = await updateVehicle(updatedVehicle);

      if (result) {
        // Check if notifications are enabled
        final prefs = await SharedPreferences.getInstance();
        final enableReminders =
            prefs.getBool('enable_maintenance_reminders') ?? true;

        if (enableReminders) {
          // Get the notification service and show a notification for the new reminder
          final notificationService = NotificationService();

          // Calculate days until due
          final now = DateTime.now();
          final daysUntil = reminder.dueDate.difference(now).inDays;

          // Show notification if due date is within the next 30 days
          if (daysUntil <= 30 && daysUntil >= 0) {
            await notificationService.showMaintenanceReminder(
              vehicle: updatedVehicle,
              reminder: reminder,
              isOverdue: false,
            );
          }
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error adding maintenance reminder: $e');
      return false;
    }
  }

  /// Update a maintenance reminder
  Future<bool> updateMaintenanceReminder(
    String vehicleId,
    MaintenanceReminder updatedReminder,
  ) async {
    try {
      // Get the current vehicle
      final vehicle = await getVehicleById(vehicleId);
      if (vehicle == null) return false;

      // Find and update the specific reminder
      final updatedReminders =
          vehicle.maintenanceReminders.map((reminder) {
            if (reminder.id == updatedReminder.id) {
              return updatedReminder;
            }
            return reminder;
          }).toList();

      // Update the vehicle with the modified reminders list
      final updatedVehicle = vehicle.copyWith(
        maintenanceReminders: updatedReminders,
      );
      return await updateVehicle(updatedVehicle);
    } catch (e) {
      debugPrint('Error updating maintenance reminder: $e');
      return false;
    }
  }

  /// Delete a maintenance reminder
  Future<bool> deleteMaintenanceReminder(
    String vehicleId,
    String reminderId,
  ) async {
    try {
      // Get the current vehicle
      final vehicle = await getVehicleById(vehicleId);
      if (vehicle == null) return false;

      // Remove the specific reminder
      final updatedReminders =
          vehicle.maintenanceReminders
              .where((reminder) => reminder.id != reminderId)
              .toList();

      // Update the vehicle with the filtered reminders list
      final updatedVehicle = vehicle.copyWith(
        maintenanceReminders: updatedReminders,
      );
      return await updateVehicle(updatedVehicle);
    } catch (e) {
      debugPrint('Error deleting maintenance reminder: $e');
      return false;
    }
  }

  /// Mark a maintenance reminder as completed
  Future<bool> completeMaintenanceReminder(
    String vehicleId,
    String reminderId, {
    String notes = '',
  }) async {
    try {
      // Get the current vehicle
      final vehicle = await getVehicleById(vehicleId);
      if (vehicle == null) return false;

      // Find the reminder that's being completed
      MaintenanceReminder? completedReminder;

      // Find and update the specific reminder
      final updatedReminders =
          vehicle.maintenanceReminders.map((reminder) {
            if (reminder.id == reminderId) {
              completedReminder = reminder;
              return reminder.copyWith(
                isCompleted: true,
                completedDate: DateTime.now(),
                notes: notes.isNotEmpty ? notes : reminder.notes,
              );
            }
            return reminder;
          }).toList();

      // Update the vehicle with the modified reminders list
      final updatedVehicle = vehicle.copyWith(
        maintenanceReminders: updatedReminders,
      );
      final result = await updateVehicle(updatedVehicle);

      // Show a completion notification
      if (result && completedReminder != null) {
        try {
          final notificationService = NotificationService();
          await notificationService.showLocalNotification(
            id: completedReminder.hashCode,
            title: 'Maintenance Completed',
            body:
                '${completedReminder!.type.name} for ${vehicle.plateNumber} has been marked as completed.',
          );
        } catch (e) {
          // Don't let notification errors affect the result
          debugPrint('Error showing completion notification: $e');
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error completing maintenance reminder: $e');
      return false;
    }
  }

  /// Get upcoming maintenance reminders for a vehicle
  List<MaintenanceReminder> getUpcomingReminders(
    Vehicle vehicle, {
    int daysAhead = 30,
  }) {
    final now = DateTime.now();
    final cutoffDate = now.add(Duration(days: daysAhead));

    return vehicle.maintenanceReminders
        .where(
          (reminder) =>
              !reminder.isCompleted &&
              reminder.dueDate.isBefore(cutoffDate) &&
              reminder.dueDate.isAfter(now.subtract(const Duration(days: 1))),
        )
        .toList();
  }

  /// Get overdue maintenance reminders for a vehicle
  List<MaintenanceReminder> getOverdueReminders(Vehicle vehicle) {
    final now = DateTime.now();

    return vehicle.maintenanceReminders
        .where(
          (reminder) => !reminder.isCompleted && reminder.dueDate.isBefore(now),
        )
        .toList();
  }

  /// Get vehicles from Firestore
  Future<List<Vehicle>> getVehicles() async {
    try {
      // Check if user is authenticated
      if (_auth.currentUser == null) {
        debugPrint('User not authenticated, returning empty vehicle list');
        return [];
      }

      debugPrint('Fetching vehicles for user: ${_auth.currentUser!.uid}');

      // For now, fetch all vehicles to ensure we can see the data
      final querySnapshot = await _vehiclesCollection.get();

      debugPrint('Found ${querySnapshot.docs.length} vehicles in Firestore');

      final vehicles =
          querySnapshot.docs.map((doc) {
            debugPrint(
              'Vehicle ID: ${doc.id}, Plate: ${doc.data()['plateNumber']}',
            );
            return Vehicle.fromFirestore(doc);
          }).toList();

      return vehicles;
    } catch (e) {
      debugPrint('Error fetching vehicles: $e');
      return [];
    }
  }
}
