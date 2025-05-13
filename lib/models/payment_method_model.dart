import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing different types of payment methods
enum PaymentMethodType {
  creditCard,
  debitCard,
  gcash,
  maya,
  gotyme,
}

/// Extension to provide display names for payment method types
extension PaymentMethodTypeExtension on PaymentMethodType {
  String get displayName {
    switch (this) {
      case PaymentMethodType.creditCard:
        return 'Credit Card';
      case PaymentMethodType.debitCard:
        return 'Debit Card';
      case PaymentMethodType.gcash:
        return 'GCash';
      case PaymentMethodType.maya:
        return 'Maya';
      case PaymentMethodType.gotyme:
        return 'GoTyme';
    }
  }

  String get iconAsset {
    switch (this) {
      case PaymentMethodType.creditCard:
      case PaymentMethodType.debitCard:
        return 'assets/icons/card.png';
      case PaymentMethodType.gcash:
        return 'assets/icons/gcash.png';
      case PaymentMethodType.maya:
        return 'assets/icons/maya.png';
      case PaymentMethodType.gotyme:
        return 'assets/icons/gotyme.png';
    }
  }
}

/// Model class for payment methods
class PaymentMethod {
  final String id;
  final String userId;
  final PaymentMethodType type;
  final String name;
  final String? cardNumber; // Last 4 digits for cards
  final String? expiryDate; // MM/YY format for cards
  final String? accountNumber; // For e-wallets
  final bool isDefault;
  final Timestamp createdAt;

  PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    this.cardNumber,
    this.expiryDate,
    this.accountNumber,
    this.isDefault = false,
    Timestamp? createdAt,
  }) : createdAt = createdAt ?? Timestamp.now();

  /// Create a payment method from a Firebase document
  factory PaymentMethod.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PaymentMethod(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: PaymentMethodType.values.firstWhere(
        (e) => e.toString() == 'PaymentMethodType.${data['type']}',
        orElse: () => PaymentMethodType.creditCard,
      ),
      name: data['name'] ?? '',
      cardNumber: data['cardNumber'],
      expiryDate: data['expiryDate'],
      accountNumber: data['accountNumber'],
      isDefault: data['isDefault'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  /// Convert payment method to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'name': name,
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'accountNumber': accountNumber,
      'isDefault': isDefault,
      'createdAt': createdAt,
    };
  }

  /// Create a copy of this payment method with updated fields
  PaymentMethod copyWith({
    String? id,
    String? userId,
    PaymentMethodType? type,
    String? name,
    String? cardNumber,
    String? expiryDate,
    String? accountNumber,
    bool? isDefault,
    Timestamp? createdAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      name: name ?? this.name,
      cardNumber: cardNumber ?? this.cardNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      accountNumber: accountNumber ?? this.accountNumber,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
