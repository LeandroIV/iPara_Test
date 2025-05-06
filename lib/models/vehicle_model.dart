import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class representing a vehicle in the system
class Vehicle {
  /// Unique identifier for the vehicle
  final String id;

  /// The vehicle's registration plate number
  final String plateNumber;

  /// The type of vehicle (e.g., "Jeepney", "Bus", "Multicab")
  final String vehicleType;

  /// The model of the vehicle (e.g., "Toyota Hiace", "Isuzu Elf")
  final String model;

  /// The year the vehicle was manufactured
  final int year;

  /// The current odometer reading in kilometers
  final int odometerReading;

  /// The driver ID associated with this vehicle (if assigned)
  final String? driverId;

  /// The operator ID who owns this vehicle
  final String operatorId;

  /// The route ID this vehicle is assigned to (if any)
  final String? routeId;

  /// Whether this vehicle is currently active
  final bool isActive;

  /// List of maintenance reminders for this vehicle
  final List<MaintenanceReminder> maintenanceReminders;

  /// Constructor
  Vehicle({
    required this.id,
    required this.plateNumber,
    required this.vehicleType,
    required this.model,
    required this.year,
    required this.odometerReading,
    required this.operatorId,
    this.driverId,
    this.routeId,
    this.isActive = true,
    this.maintenanceReminders = const [],
  });

  /// Create a vehicle from a Firebase document
  factory Vehicle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse maintenance reminders
    List<MaintenanceReminder> reminders = [];
    if (data['maintenanceReminders'] != null) {
      reminders = (data['maintenanceReminders'] as List)
          .map((reminder) => MaintenanceReminder.fromMap(reminder))
          .toList();
    }

    return Vehicle(
      id: doc.id,
      plateNumber: data['plateNumber'] ?? '',
      vehicleType: data['vehicleType'] ?? '',
      model: data['model'] ?? '',
      year: data['year'] ?? 0,
      odometerReading: data['odometerReading'] ?? 0,
      driverId: data['driverId'],
      operatorId: data['operatorId'] ?? '',
      routeId: data['routeId'],
      isActive: data['isActive'] ?? true,
      maintenanceReminders: reminders,
    );
  }

  /// Convert vehicle to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'plateNumber': plateNumber,
      'vehicleType': vehicleType,
      'model': model,
      'year': year,
      'odometerReading': odometerReading,
      'driverId': driverId,
      'operatorId': operatorId,
      'routeId': routeId,
      'isActive': isActive,
      'maintenanceReminders': maintenanceReminders.map((r) => r.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy of this vehicle with updated fields
  Vehicle copyWith({
    String? id,
    String? plateNumber,
    String? vehicleType,
    String? model,
    int? year,
    int? odometerReading,
    String? driverId,
    String? operatorId,
    String? routeId,
    bool? isActive,
    List<MaintenanceReminder>? maintenanceReminders,
  }) {
    return Vehicle(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      model: model ?? this.model,
      year: year ?? this.year,
      odometerReading: odometerReading ?? this.odometerReading,
      driverId: driverId ?? this.driverId,
      operatorId: operatorId ?? this.operatorId,
      routeId: routeId ?? this.routeId,
      isActive: isActive ?? this.isActive,
      maintenanceReminders: maintenanceReminders ?? this.maintenanceReminders,
    );
  }
}

/// Enum representing the type of maintenance
enum MaintenanceType {
  oilChange,
  tireRotation,
  brakeService,
  engineTuneUp,
  transmission,
  airFilter,
  fuelFilter,
  batteryReplacement,
  coolantFlush,
  generalInspection,
  other
}

/// Extension to provide string representations for MaintenanceType
extension MaintenanceTypeExtension on MaintenanceType {
  String get name {
    switch (this) {
      case MaintenanceType.oilChange:
        return 'Oil Change';
      case MaintenanceType.tireRotation:
        return 'Tire Rotation';
      case MaintenanceType.brakeService:
        return 'Brake Service';
      case MaintenanceType.engineTuneUp:
        return 'Engine Tune-Up';
      case MaintenanceType.transmission:
        return 'Transmission Service';
      case MaintenanceType.airFilter:
        return 'Air Filter Replacement';
      case MaintenanceType.fuelFilter:
        return 'Fuel Filter Replacement';
      case MaintenanceType.batteryReplacement:
        return 'Battery Replacement';
      case MaintenanceType.coolantFlush:
        return 'Coolant Flush';
      case MaintenanceType.generalInspection:
        return 'General Inspection';
      case MaintenanceType.other:
        return 'Other';
    }
  }

  /// Get the maintenance type from a string
  static MaintenanceType fromString(String value) {
    return MaintenanceType.values.firstWhere(
      (type) => type.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MaintenanceType.other,
    );
  }
}

/// Model class representing a maintenance reminder
class MaintenanceReminder {
  /// Unique identifier for the reminder
  final String id;

  /// The type of maintenance
  final MaintenanceType type;

  /// Description of the maintenance task
  final String description;

  /// Due date for the maintenance
  final DateTime dueDate;

  /// Odometer reading at which maintenance is due
  final int? dueMileage;

  /// Whether the maintenance has been completed
  final bool isCompleted;

  /// Date when the maintenance was completed (if applicable)
  final DateTime? completedDate;

  /// Notes about the maintenance
  final String notes;

  /// Constructor
  MaintenanceReminder({
    required this.id,
    required this.type,
    required this.description,
    required this.dueDate,
    this.dueMileage,
    this.isCompleted = false,
    this.completedDate,
    this.notes = '',
  });

  /// Create a maintenance reminder from a Map
  factory MaintenanceReminder.fromMap(Map<String, dynamic> map) {
    return MaintenanceReminder(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: map['type'] != null 
          ? MaintenanceTypeExtension.fromString(map['type']) 
          : MaintenanceType.other,
      description: map['description'] ?? '',
      dueDate: map['dueDate'] != null 
          ? (map['dueDate'] as Timestamp).toDate() 
          : DateTime.now().add(const Duration(days: 30)),
      dueMileage: map['dueMileage'],
      isCompleted: map['isCompleted'] ?? false,
      completedDate: map['completedDate'] != null 
          ? (map['completedDate'] as Timestamp).toDate() 
          : null,
      notes: map['notes'] ?? '',
    );
  }

  /// Convert maintenance reminder to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'dueMileage': dueMileage,
      'isCompleted': isCompleted,
      'completedDate': completedDate != null ? Timestamp.fromDate(completedDate!) : null,
      'notes': notes,
    };
  }

  /// Create a copy of this reminder with updated fields
  MaintenanceReminder copyWith({
    String? id,
    MaintenanceType? type,
    String? description,
    DateTime? dueDate,
    int? dueMileage,
    bool? isCompleted,
    DateTime? completedDate,
    String? notes,
  }) {
    return MaintenanceReminder(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueMileage: dueMileage ?? this.dueMileage,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      notes: notes ?? this.notes,
    );
  }
}
