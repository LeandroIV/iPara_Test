import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class representing an emergency contact
class EmergencyContact {
  /// Unique identifier for the contact
  final String id;
  
  /// Name of the contact
  final String name;
  
  /// Phone number of the contact
  final String phoneNumber;
  
  /// Relationship to the user (e.g., family, friend)
  final String relationship;
  
  /// Whether this contact should be notified in emergencies
  final bool notifyInEmergency;
  
  /// Priority order (lower number = higher priority)
  final int priority;

  /// Constructor
  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.notifyInEmergency = true,
    this.priority = 1,
  });

  /// Create a copy of this contact with some fields replaced
  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? relationship,
    bool? notifyInEmergency,
    int? priority,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      notifyInEmergency: notifyInEmergency ?? this.notifyInEmergency,
      priority: priority ?? this.priority,
    );
  }

  /// Create a contact from a map
  factory EmergencyContact.fromMap(Map<String, dynamic> map, {String? id}) {
    return EmergencyContact(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      relationship: map['relationship'] ?? '',
      notifyInEmergency: map['notifyInEmergency'] ?? true,
      priority: map['priority'] ?? 1,
    );
  }

  /// Convert this contact to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'notifyInEmergency': notifyInEmergency,
      'priority': priority,
    };
  }
}

/// Model class representing an emergency alert
class EmergencyAlert {
  /// Unique identifier for the alert
  final String id;
  
  /// User ID who triggered the alert
  final String userId;
  
  /// User's name
  final String userName;
  
  /// Location of the emergency (latitude)
  final double latitude;
  
  /// Location of the emergency (longitude)
  final double longitude;
  
  /// When the alert was triggered
  final DateTime timestamp;
  
  /// Current status of the alert
  final EmergencyAlertStatus status;
  
  /// List of contact IDs who were notified
  final List<String> notifiedContacts;
  
  /// Additional notes about the emergency
  final String? notes;

  /// Constructor
  EmergencyAlert({
    required this.id,
    required this.userId,
    required this.userName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.status = EmergencyAlertStatus.active,
    required this.notifiedContacts,
    this.notes,
  });

  /// Create an alert from a Firebase document
  factory EmergencyAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return EmergencyAlert(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      latitude: (data['location'] as GeoPoint?)?.latitude ?? 0.0,
      longitude: (data['location'] as GeoPoint?)?.longitude ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: EmergencyAlertStatus.values[data['status'] ?? 0],
      notifiedContacts: List<String>.from(data['notifiedContacts'] ?? []),
      notes: data['notes'],
    );
  }

  /// Convert this alert to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'location': GeoPoint(latitude, longitude),
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.index,
      'notifiedContacts': notifiedContacts,
      'notes': notes,
    };
  }
}

/// Enum representing the status of an emergency alert
enum EmergencyAlertStatus {
  active,
  responded,
  resolved,
  cancelled
}

/// Extension to provide additional functionality to EmergencyAlertStatus
extension EmergencyAlertStatusExtension on EmergencyAlertStatus {
  String get name {
    switch (this) {
      case EmergencyAlertStatus.active:
        return 'Active';
      case EmergencyAlertStatus.responded:
        return 'Responded';
      case EmergencyAlertStatus.resolved:
        return 'Resolved';
      case EmergencyAlertStatus.cancelled:
        return 'Cancelled';
    }
  }
}
