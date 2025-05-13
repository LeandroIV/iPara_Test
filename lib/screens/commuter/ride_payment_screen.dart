import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ride_request_model.dart';
import '../../models/payment_method_model.dart';

class RidePaymentScreen extends StatefulWidget {
  final RideRequest rideRequest;
  final double fareAmount;
  final Function(bool success) onPaymentComplete;

  const RidePaymentScreen({
    super.key,
    required this.rideRequest,
    required this.fareAmount,
    required this.onPaymentComplete,
  });

  @override
  State<RidePaymentScreen> createState() => _RidePaymentScreenState();
}

class _RidePaymentScreenState extends State<RidePaymentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  List<PaymentMethod> _paymentMethods = [];
  PaymentMethod? _selectedPaymentMethod;

  // Tip amount
  double _tipAmount = 0.0;
  final List<double> _tipOptions = [0.0, 5.0, 10.0, 20.0, 50.0];
  int _selectedTipIndex = 0;

  // Custom tip controller
  final TextEditingController _customTipController = TextEditingController();
  bool _isCustomTip = false;

  // Total amount (fare + tip)
  double get _totalAmount => widget.fareAmount + _tipAmount;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _customTipController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mock payment methods
      final methods = [
        PaymentMethod(
          id: 'card',
          userId: widget.rideRequest.commuterId,
          name: 'Credit Card',
          type: PaymentMethodType.creditCard,
          isDefault: true,
        ),
        PaymentMethod(
          id: 'gcash',
          userId: widget.rideRequest.commuterId,
          name: 'GCash',
          type: PaymentMethodType.gcash,
          isDefault: false,
        ),
        PaymentMethod(
          id: 'maya',
          userId: widget.rideRequest.commuterId,
          name: 'Maya',
          type: PaymentMethodType.maya,
          isDefault: false,
        ),
        PaymentMethod(
          id: 'gotyme',
          userId: widget.rideRequest.commuterId,
          name: 'GotYme',
          type: PaymentMethodType.gotyme,
          isDefault: false,
        ),
      ];

      setState(() {
        _paymentMethods = methods;
        // Set the default payment method as selected if available
        if (methods.isNotEmpty) {
          _selectedPaymentMethod = methods.firstWhere(
            (method) => method.isDefault,
            orElse: () => methods.first,
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading payment methods');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _setTipAmount(double amount, int index) {
    setState(() {
      _tipAmount = amount;
      _selectedTipIndex = index;
      _isCustomTip = false;
    });
  }

  void _setCustomTip() {
    setState(() {
      _isCustomTip = true;
      _selectedTipIndex = -1;
      _customTipController.text = _tipAmount.toString();
    });
  }

  void _applyCustomTip() {
    try {
      final customTip = double.parse(_customTipController.text);
      if (customTip >= 0) {
        setState(() {
          _tipAmount = customTip;
          _isCustomTip = false;
        });
      } else {
        _showErrorSnackBar('Tip amount cannot be negative');
      }
    } catch (e) {
      _showErrorSnackBar('Please enter a valid amount');
    }
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      _showErrorSnackBar('Please select a payment method');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update the ride request directly in Firestore

      // Update in Firestore
      await _firestore
          .collection('ride_requests')
          .doc(widget.rideRequest.id)
          .update({
            'status': RideRequestStatus.paid.index,
            'fareAmount': widget.fareAmount,
            'tipAmount': _tipAmount,
            'totalAmount': _totalAmount,
            'paymentMethodId': _selectedPaymentMethod!.id,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Create a payment transaction record
      await _firestore.collection('payment_transactions').add({
        'rideRequestId': widget.rideRequest.id,
        'driverId': widget.rideRequest.driverId,
        'commuterId': widget.rideRequest.commuterId,
        'fareAmount': widget.fareAmount,
        'tipAmount': _tipAmount,
        'totalAmount': _totalAmount,
        'paymentMethodId': _selectedPaymentMethod!.id,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Notify parent that payment is complete
        widget.onPaymentComplete(true);

        // Close the payment screen
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showErrorSnackBar('Payment failed: $e');
      widget.onPaymentComplete(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Payment'),
        backgroundColor: Colors.amber,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fare details
                    _buildFareDetails(),

                    const SizedBox(height: 24),

                    // Tip selection
                    _buildTipSelection(),

                    const SizedBox(height: 24),

                    // Payment methods
                    _buildPaymentMethods(),

                    const SizedBox(height: 32),

                    // Payment button
                    _buildPaymentButton(),
                  ],
                ),
              ),
    );
  }

  Widget _buildFareDetails() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ride Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFareRow('Fare', '₱${widget.fareAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildFareRow('Tip', '₱${_tipAmount.toStringAsFixed(2)}'),
            const Divider(height: 24),
            _buildFareRow(
              'Total',
              '₱${_totalAmount.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFareRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildTipSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add a Tip',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Show your appreciation to the driver',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (int i = 0; i < _tipOptions.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: () => _setTipAmount(_tipOptions[i], i),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _selectedTipIndex == i
                              ? Colors.amber
                              : Colors.grey.shade200,
                      foregroundColor:
                          _selectedTipIndex == i ? Colors.white : Colors.black,
                    ),
                    child: Text(
                      _tipOptions[i] == 0
                          ? 'No Tip'
                          : '₱${_tipOptions[i].toStringAsFixed(0)}',
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _isCustomTip
            ? Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customTipController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Custom Tip Amount',
                      prefixText: '₱',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}$'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _applyCustomTip,
                  child: const Text('Apply'),
                ),
              ],
            )
            : TextButton(
              onPressed: _setCustomTip,
              child: const Text('Custom Tip'),
            ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _paymentMethods.isEmpty
            ? const Center(child: Text('No payment methods available'))
            : Column(
              children:
                  _paymentMethods.map((method) {
                    final isSelected = _selectedPaymentMethod?.id == method.id;
                    return Card(
                      color: isSelected ? Colors.amber.withAlpha(25) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Colors.amber : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          _getPaymentIcon(method.type),
                          color: isSelected ? Colors.amber : Colors.grey,
                        ),
                        title: Text(method.name),
                        subtitle: Text(method.type.displayName),
                        trailing:
                            isSelected
                                ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.amber,
                                )
                                : null,
                        onTap: () {
                          setState(() {
                            _selectedPaymentMethod = method;
                          });
                        },
                      ),
                    );
                  }).toList(),
            ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            // Navigate to add payment method screen
            // This would be implemented in a real app
            _showErrorSnackBar('Add payment method not implemented');
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Payment Method'),
        ),
      ],
    );
  }

  IconData _getPaymentIcon(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.creditCard:
      case PaymentMethodType.debitCard:
        return Icons.credit_card;
      case PaymentMethodType.gcash:
        return Icons.account_balance_wallet;
      case PaymentMethodType.maya:
        return Icons.account_balance_wallet;
      case PaymentMethodType.gotyme:
        return Icons.account_balance_wallet;
    }
  }

  Widget _buildPaymentButton() {
    return ElevatedButton(
      onPressed: _processPayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        'Pay Now',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
