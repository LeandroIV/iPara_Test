import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/payment_method_model.dart';
import '../models/fare_model.dart';

/// Service class for handling payment-related operations
class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Get collection reference for payment methods
  CollectionReference<Map<String, dynamic>> get _paymentMethodsCollection =>
      _firestore.collection('payment_methods');

  /// Get collection reference for fares
  CollectionReference<Map<String, dynamic>> get _faresCollection =>
      _firestore.collection('fares');

  /// Get collection reference for payment transactions
  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _firestore.collection('payment_transactions');

  /// Get all payment methods for the current user
  Future<List<PaymentMethod>> getPaymentMethods() async {
    if (_currentUserId == null) return [];

    try {
      final querySnapshot = await _paymentMethodsCollection
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PaymentMethod.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting payment methods: $e');
      return [];
    }
  }

  /// Get a specific payment method by ID
  Future<PaymentMethod?> getPaymentMethod(String id) async {
    try {
      final docSnapshot = await _paymentMethodsCollection.doc(id).get();
      if (docSnapshot.exists) {
        return PaymentMethod.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting payment method: $e');
      return null;
    }
  }

  /// Add a new payment method
  Future<String?> addPaymentMethod(PaymentMethod method) async {
    if (_currentUserId == null) return null;

    try {
      // Check if this is the first payment method for the user
      final existingMethods = await getPaymentMethods();
      final isFirst = existingMethods.isEmpty;

      // If this is the first method, make it the default
      final paymentData = method.copyWith(
        userId: _currentUserId,
        isDefault: method.isDefault || isFirst,
      ).toFirestore();

      // If this method is being set as default, update all other methods
      if (method.isDefault || isFirst) {
        await _updateDefaultPaymentMethod(null);
      }

      final docRef = await _paymentMethodsCollection.add(paymentData);
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding payment method: $e');
      return null;
    }
  }

  /// Update an existing payment method
  Future<bool> updatePaymentMethod(PaymentMethod method) async {
    try {
      // If this method is being set as default, update all other methods
      if (method.isDefault) {
        await _updateDefaultPaymentMethod(method.id);
      }

      await _paymentMethodsCollection.doc(method.id).update(method.toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error updating payment method: $e');
      return false;
    }
  }

  /// Delete a payment method
  Future<bool> deletePaymentMethod(String id) async {
    try {
      // Check if this is the default method
      final method = await getPaymentMethod(id);
      if (method != null && method.isDefault) {
        // If deleting the default method, we need to set another one as default
        final methods = await getPaymentMethods();
        final otherMethods = methods.where((m) => m.id != id).toList();
        if (otherMethods.isNotEmpty) {
          // Set the first other method as default
          await updatePaymentMethod(
            otherMethods.first.copyWith(isDefault: true),
          );
        }
      }

      await _paymentMethodsCollection.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting payment method: $e');
      return false;
    }
  }

  /// Update the default payment method
  Future<void> _updateDefaultPaymentMethod(String? newDefaultId) async {
    if (_currentUserId == null) return;

    try {
      // Get all payment methods except the new default
      final querySnapshot = await _paymentMethodsCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('isDefault', isEqualTo: true)
          .get();

      // Update all current default methods to non-default
      for (var doc in querySnapshot.docs) {
        if (doc.id != newDefaultId) {
          await doc.reference.update({'isDefault': false});
        }
      }
    } catch (e) {
      debugPrint('Error updating default payment method: $e');
    }
  }

  /// Get fare information for a route
  Future<Fare?> getFare(String routeId) async {
    try {
      final querySnapshot = await _faresCollection
          .where('routeId', isEqualTo: routeId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Fare.fromFirestore(querySnapshot.docs.first);
      }
      
      // If no fare found, return a default fare
      return Fare(
        id: 'default',
        routeId: routeId,
        routeCode: 'Unknown',
        basePrice: 11.0, // Default base price in PHP
        pricePerKm: 2.0,  // Default price per km in PHP
      );
    } catch (e) {
      debugPrint('Error getting fare: $e');
      return null;
    }
  }

  /// Create a new payment transaction
  Future<String?> createTransaction(PaymentTransaction transaction) async {
    if (_currentUserId == null) return null;

    try {
      final transactionData = transaction.copyWith(
        userId: _currentUserId,
      ).toFirestore();

      final docRef = await _transactionsCollection.add(transactionData);
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating transaction: $e');
      return null;
    }
  }

  /// Get payment transaction history for the current user
  Future<List<PaymentTransaction>> getTransactionHistory() async {
    if (_currentUserId == null) return [];

    try {
      final querySnapshot = await _transactionsCollection
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PaymentTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting transaction history: $e');
      return [];
    }
  }

  /// Generate a QR code for payment (mock implementation)
  String generatePaymentQR(String routeId, double amount, PassengerType passengerType) {
    // In a real implementation, this would generate a QR code with payment details
    // For now, we'll just return a mock QR code data string
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'IPARA:PAY:$routeId:$amount:${passengerType.toString().split('.').last}:$timestamp';
  }
}
