import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/fare_model.dart';
import '../../services/payment_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = true;
  List<PaymentTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactionHistory();
  }

  Future<void> _loadTransactionHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to get transactions from service
      final transactions = await _paymentService.getTransactionHistory();

      setState(() {
        // If no transactions found, use mock data
        if (transactions.isEmpty) {
          _transactions = _generateMockTransactions();
        } else {
          _transactions = transactions;
        }
        _isLoading = false;
      });
    } catch (e) {
      // On error, use mock data
      setState(() {
        _transactions = _generateMockTransactions();
        _isLoading = false;
      });
      _showMessage('Using sample data for demonstration', isError: true);
    }
  }

  // Show error message to user
  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
      ),
      backgroundColor: Colors.black,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              )
              : _transactions.isEmpty
              ? _buildEmptyState()
              : _buildTransactionList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, color: Colors.grey[700], size: 64),
          const SizedBox(height: 16),
          Text(
            'No payment history yet',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment transactions will appear here',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    // Group transactions by date
    final Map<String, List<PaymentTransaction>> groupedTransactions = {};

    for (final transaction in _transactions) {
      final date = DateFormat(
        'yyyy-MM-dd',
      ).format(transaction.timestamp.toDate());
      if (!groupedTransactions.containsKey(date)) {
        groupedTransactions[date] = [];
      }
      groupedTransactions[date]!.add(transaction);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final date = groupedTransactions.keys.elementAt(index);
        final transactions = groupedTransactions[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(date),
            const SizedBox(height: 8),
            ...transactions.map(
              (transaction) => _buildTransactionItem(transaction),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(String date) {
    final DateTime dateTime = DateTime.parse(date);
    final String formattedDate = _formatDate(dateTime);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        formattedDate,
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }

  Widget _buildTransactionItem(PaymentTransaction transaction) {
    final DateTime dateTime = transaction.timestamp.toDate();
    final String time = DateFormat('h:mm a').format(dateTime);

    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Transaction icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color.fromRGBO(
                  255,
                  193,
                  7,
                  0.2,
                ), // Amber with 20% opacity
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.directions_bus, color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 16),
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route ${transaction.routeCode}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.passengerType.displayName} • ${transaction.distance.toStringAsFixed(1)} km',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            // Transaction amount
            Text(
              '₱${transaction.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Mock data generator for preview purposes
List<PaymentTransaction> _generateMockTransactions() {
  final now = DateTime.now();

  return [
    PaymentTransaction(
      id: '1',
      userId: 'user1',
      routeId: 'route1',
      routeCode: 'R2',
      amount: 25.0,
      distance: 5.0,
      passengerType: PassengerType.regular,
      paymentMethodId: 'method1',
      timestamp: Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
    ),
    PaymentTransaction(
      id: '2',
      userId: 'user1',
      routeId: 'route2',
      routeCode: 'R3',
      amount: 20.0,
      distance: 4.0,
      passengerType: PassengerType.student,
      paymentMethodId: 'method1',
      timestamp: Timestamp.fromDate(now.subtract(const Duration(days: 1))),
    ),
    PaymentTransaction(
      id: '3',
      userId: 'user1',
      routeId: 'route1',
      routeCode: 'R2',
      amount: 20.0,
      distance: 5.0,
      passengerType: PassengerType.seniorCitizen,
      paymentMethodId: 'method2',
      timestamp: Timestamp.fromDate(now.subtract(const Duration(days: 2))),
    ),
    PaymentTransaction(
      id: '4',
      userId: 'user1',
      routeId: 'route3',
      routeCode: 'R4',
      amount: 30.0,
      distance: 6.0,
      passengerType: PassengerType.regular,
      paymentMethodId: 'method1',
      timestamp: Timestamp.fromDate(now.subtract(const Duration(days: 3))),
    ),
  ];
}
