import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle_model.dart';
import 'vehicle_service.dart';

/// Global navigator key for accessing context from service
GlobalKey<NavigatorState>? navigatorKey;

/// Service for handling push notifications and local notifications
class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Stream controller for notification clicks
  final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getter for the notification stream
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;

  /// Initialize the notification service
  Future<void> initialize() async {
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission for notifications
    await _requestPermissions();

    // Configure Firebase Messaging
    await _configureFirebaseMessaging();

    // Subscribe to topics based on user role
    await _subscribeToTopics();

    // Schedule maintenance checks
    _scheduleMaintenanceChecks();
  }

  /// Request permissions for notifications
  Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }
  }

  /// Configure Firebase Messaging
  Future<void> _configureFirebaseMessaging() async {
    // Get FCM token
    final token = await _firebaseMessaging.getToken();

    // Save token to Firestore
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Handle when user taps on notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // Check for initial message (app opened from terminated state)
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('user_tokens').doc(userId).set({
        'token': token,
        'platform': Platform.operatingSystem,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Subscribe to topics based on user role
  Future<void> _subscribeToTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final userRoleString = prefs.getString('user_role');

    if (userRoleString == null) return;

    // Subscribe to role-specific topics
    await _firebaseMessaging.subscribeToTopic('all_users');
    await _firebaseMessaging.subscribeToTopic(userRoleString);

    // For drivers and operators, subscribe to maintenance topics
    if (userRoleString == 'driver' || userRoleString == 'operator') {
      await _firebaseMessaging.subscribeToTopic('maintenance');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification for foreground messages
    if (message.notification != null) {
      showLocalNotification(
        id: message.hashCode,
        title: message.notification!.title ?? 'iPara Notification',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }

    // Add to stream for app to handle
    _notificationStreamController.add(message.data);
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    // Add to stream for app to handle navigation
    _notificationStreamController.add(message.data);
  }

  /// Show a local notification using Firebase Messaging
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      // Log notification for debugging
      debugPrint('NOTIFICATION: $title');
      debugPrint('CONTENT: $body');
      if (payload != null) {
        debugPrint('PAYLOAD: $payload');
      }

      // Show a snackbar if the app is in the foreground
      final context = navigatorKey?.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(body),
              ],
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                if (payload != null) {
                  _notificationStreamController.add({'payload': payload});
                }
              },
            ),
          ),
        );
      }

      // For background notifications, we could use Firebase Cloud Functions
      // to send a push notification to the device
      // This would require server-side code
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Schedule maintenance checks
  void _scheduleMaintenanceChecks() {
    // Check for maintenance reminders daily
    Timer.periodic(const Duration(hours: 24), (_) {
      _checkForMaintenanceReminders();
    });

    // Also check immediately on startup
    _checkForMaintenanceReminders();
  }

  /// Check for maintenance reminders
  Future<void> _checkForMaintenanceReminders() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final userRoleString = prefs.getString('user_role');

    if (userRoleString == null) return;

    try {
      // Get the VehicleService instance
      final vehicleService = VehicleService();
      List<Vehicle> vehicles = [];

      // Get vehicles based on user role
      if (userRoleString == 'driver') {
        vehicles = await vehicleService.getDriverVehicles();
      } else if (userRoleString == 'operator') {
        vehicles = await vehicleService.getOperatorVehicles();
      }

      // Check each vehicle for reminders
      for (final vehicle in vehicles) {
        // Check for overdue reminders
        final overdueReminders = vehicleService.getOverdueReminders(vehicle);
        for (final reminder in overdueReminders) {
          showMaintenanceReminder(
            vehicle: vehicle,
            reminder: reminder,
            isOverdue: true,
          );
        }

        // Check for upcoming reminders (due in the next 7 days)
        final upcomingReminders = vehicleService.getUpcomingReminders(
          vehicle,
          daysAhead: 7,
        );
        for (final reminder in upcomingReminders) {
          showMaintenanceReminder(
            vehicle: vehicle,
            reminder: reminder,
            isOverdue: false,
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking maintenance reminders: $e');
    }
  }

  /// Show maintenance reminder notification
  Future<void> showMaintenanceReminder({
    required Vehicle vehicle,
    required MaintenanceReminder reminder,
    required bool isOverdue,
  }) async {
    // Check if notifications are enabled
    final prefs = await SharedPreferences.getInstance();
    final enableReminders =
        prefs.getBool('enable_maintenance_reminders') ?? true;

    if (!enableReminders) {
      return;
    }

    // Check if we've already shown this reminder recently
    final lastShownKey = 'reminder_${reminder.id}_last_shown';
    final lastShown = prefs.getInt(lastShownKey) ?? 0;

    // Only show once per day
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastShown < const Duration(hours: 24).inMilliseconds) {
      return;
    }

    // Create notification content
    final title =
        isOverdue
            ? 'OVERDUE: ${reminder.type.name} for ${vehicle.plateNumber}'
            : 'Upcoming: ${reminder.type.name} for ${vehicle.plateNumber}';

    final daysUntil = reminder.dueDate.difference(DateTime.now()).inDays;
    final body =
        isOverdue
            ? '${reminder.description} is overdue by ${-daysUntil} days'
            : '${reminder.description} is due in $daysUntil days';

    // Show the notification
    await showLocalNotification(
      id: reminder.id.hashCode,
      title: title,
      body: body,
      payload:
          '{"type": "maintenance", "vehicleId": "${vehicle.id}", "reminderId": "${reminder.id}"}',
    );

    // Save last shown timestamp
    await prefs.setInt(lastShownKey, now);
  }

  /// Dispose resources
  void dispose() {
    _notificationStreamController.close();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This function will be called when the app is in the background or terminated
  // It needs to be a top-level function

  // No need to show a notification here as Firebase will automatically
  // display the notification for background messages

  debugPrint("Handling a background message: ${message.messageId}");
}
