import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing different passenger types for fare calculation
enum PassengerType { regular, student, seniorCitizen }

/// Extension to provide display names and discount rates for passenger types
extension PassengerTypeExtension on PassengerType {
  String get displayName {
    switch (this) {
      case PassengerType.regular:
        return 'Regular';
      case PassengerType.student:
        return 'Student';
      case PassengerType.seniorCitizen:
        return 'Senior Citizen';
    }
  }

  double get discountRate {
    switch (this) {
      case PassengerType.regular:
        return 0.0; // No discount
      case PassengerType.student:
        return 0.2; // 20% discount
      case PassengerType.seniorCitizen:
        return 0.2; // 20% discount
    }
  }

  String get iconAsset {
    switch (this) {
      case PassengerType.regular:
        return 'assets/icons/person.png';
      case PassengerType.student:
        return 'assets/icons/student.png';
      case PassengerType.seniorCitizen:
        return 'assets/icons/senior.png';
    }
  }
}

/// Model class for fare information
class Fare {
  final String id;
  final String routeId;
  final String routeCode;
  final double basePrice;
  final double pricePerKm;
  final Timestamp updatedAt;

  Fare({
    required this.id,
    required this.routeId,
    required this.routeCode,
    required this.basePrice,
    required this.pricePerKm,
    Timestamp? updatedAt,
  }) : updatedAt = updatedAt ?? Timestamp.now();

  /// Create a fare from a Firebase document
  factory Fare.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Fare(
      id: doc.id,
      routeId: data['routeId'] ?? '',
      routeCode: data['routeCode'] ?? '',
      basePrice: (data['basePrice'] ?? 0.0).toDouble(),
      pricePerKm: (data['pricePerKm'] ?? 0.0).toDouble(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  /// Convert fare to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'routeId': routeId,
      'routeCode': routeCode,
      'basePrice': basePrice,
      'pricePerKm': pricePerKm,
      'updatedAt': updatedAt,
    };
  }

  /// Calculate fare based on distance and passenger type
  double calculateFare(double distanceKm, PassengerType passengerType) {
    // Calculate the base fare
    double fare = basePrice + (pricePerKm * distanceKm);

    // Apply discount if applicable
    double discount = fare * passengerType.discountRate;

    // Return the discounted fare (rounded to 2 decimal places)
    return double.parse((fare - discount).toStringAsFixed(2));
  }
}

/// Model class for a payment transaction
class PaymentTransaction {
  final String id;
  final String userId;
  final String routeId;
  final String routeCode;
  final String? driverId;
  final String? vehicleId;
  final double amount;
  final double distance;
  final PassengerType passengerType;
  final String paymentMethodId;
  final bool isCompleted;
  final String? receiptUrl;
  final Timestamp timestamp;

  PaymentTransaction({
    required this.id,
    required this.userId,
    required this.routeId,
    required this.routeCode,
    this.driverId,
    this.vehicleId,
    required this.amount,
    required this.distance,
    required this.passengerType,
    required this.paymentMethodId,
    this.isCompleted = false,
    this.receiptUrl,
    Timestamp? timestamp,
  }) : timestamp = timestamp ?? Timestamp.now();

  /// Create a payment transaction from a Firebase document
  factory PaymentTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PaymentTransaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      routeId: data['routeId'] ?? '',
      routeCode: data['routeCode'] ?? '',
      driverId: data['driverId'],
      vehicleId: data['vehicleId'],
      amount: (data['amount'] ?? 0.0).toDouble(),
      distance: (data['distance'] ?? 0.0).toDouble(),
      passengerType: PassengerType.values.firstWhere(
        (e) => e.toString() == 'PassengerType.${data['passengerType']}',
        orElse: () => PassengerType.regular,
      ),
      paymentMethodId: data['paymentMethodId'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      receiptUrl: data['receiptUrl'],
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  /// Convert payment transaction to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'routeId': routeId,
      'routeCode': routeCode,
      'driverId': driverId,
      'vehicleId': vehicleId,
      'amount': amount,
      'distance': distance,
      'passengerType': passengerType.toString().split('.').last,
      'paymentMethodId': paymentMethodId,
      'isCompleted': isCompleted,
      'receiptUrl': receiptUrl,
      'timestamp': timestamp,
    };
  }

  /// Create a copy of this transaction with updated fields
  PaymentTransaction copyWith({
    String? id,
    String? userId,
    String? routeId,
    String? routeCode,
    String? driverId,
    String? vehicleId,
    double? amount,
    double? distance,
    PassengerType? passengerType,
    String? paymentMethodId,
    bool? isCompleted,
    String? receiptUrl,
    Timestamp? timestamp,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      routeId: routeId ?? this.routeId,
      routeCode: routeCode ?? this.routeCode,
      driverId: driverId ?? this.driverId,
      vehicleId: vehicleId ?? this.vehicleId,
      amount: amount ?? this.amount,
      distance: distance ?? this.distance,
      passengerType: passengerType ?? this.passengerType,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      isCompleted: isCompleted ?? this.isCompleted,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
