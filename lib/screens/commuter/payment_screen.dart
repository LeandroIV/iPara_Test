import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/payment_method_model.dart';
import '../../models/fare_model.dart';
import '../../services/payment_service.dart';
import 'add_payment_method_screen.dart';
import 'payment_history_screen.dart';
import 'qr_scanner_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = true;
  List<PaymentMethod> _paymentMethods = [];

  // Selected payment method
  PaymentMethod? _selectedPaymentMethod;

  // Selected passenger type (default to regular)
  PassengerType _selectedPassengerType = PassengerType.regular;

  // Mock route data for demonstration
  final Map<String, String> _mockRoutes = {
    'R1': 'Divisoria to Uptown',
    'R2': 'Carmen to Divisoria',
    'R3': 'Bulua to Divisoria',
    'R4': 'Bugo to Lapasan',
  };

  // Selected route
  String? _selectedRouteId;

  // Fare amount
  double _fareAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final methods = await _paymentService.getPaymentMethods();

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

      // Load fare for the first route if available
      if (_mockRoutes.isNotEmpty) {
        _selectedRouteId = _mockRoutes.keys.first;
        _updateFare();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading payment methods');
    }
  }

  Future<void> _updateFare() async {
    if (_selectedRouteId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final fare = await _paymentService.getFare(_selectedRouteId!);

      if (fare != null) {
        // Mock distance for demonstration (5 km)
        const double distance = 5.0;

        setState(() {
          _fareAmount = fare.calculateFare(distance, _selectedPassengerType);
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error calculating fare');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _navigateToAddPaymentMethod() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPaymentMethodScreen()),
    );

    if (result == true) {
      _loadPaymentMethods();
    }
  }

  void _navigateToPaymentHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentHistoryScreen()),
    );
  }

  void _navigateToQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _navigateToPaymentHistory,
            tooltip: 'Payment History',
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Methods Section
                    _buildSectionTitle('Payment Methods'),
                    const SizedBox(height: 8),
                    _buildPaymentMethodsList(),

                    const SizedBox(height: 24),

                    // Route Selection Section
                    _buildSectionTitle('Select Route'),
                    const SizedBox(height: 8),
                    _buildRouteSelector(),

                    const SizedBox(height: 24),

                    // Passenger Type Section
                    _buildSectionTitle('Passenger Type'),
                    const SizedBox(height: 8),
                    _buildPassengerTypeSelector(),

                    const SizedBox(height: 24),

                    // Fare Summary Section
                    _buildSectionTitle('Fare Summary'),
                    const SizedBox(height: 8),
                    _buildFareSummary(),

                    const SizedBox(height: 32),

                    // Payment Buttons
                    _buildPaymentButtons(),
                  ],
                ),
              ),
      // Removed floating action button as it's redundant with the "Scan QR to Pay" button
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPaymentMethodsList() {
    if (_paymentMethods.isEmpty) {
      return Card(
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.credit_card, color: Colors.grey, size: 48),
              const SizedBox(height: 16),
              const Text(
                'No payment methods added yet',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _navigateToAddPaymentMethod,
                child: const Text('Add Payment Method'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children:
          _paymentMethods.map((method) {
            final isSelected = _selectedPaymentMethod?.id == method.id;

            return Card(
              color:
                  isSelected
                      ? Color.fromRGBO(255, 193, 7, 0.2)
                      : Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? Colors.amber : Colors.transparent,
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = method;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Payment method icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getPaymentMethodIcon(method.type),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Payment method details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getPaymentMethodDetails(method),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Default indicator
                      if (method.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  IconData _getPaymentMethodIcon(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.creditCard:
        return Icons.credit_card;
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

  String _getPaymentMethodDetails(PaymentMethod method) {
    switch (method.type) {
      case PaymentMethodType.creditCard:
      case PaymentMethodType.debitCard:
        return method.cardNumber != null
            ? '•••• ${method.cardNumber}'
            : method.type.displayName;
      case PaymentMethodType.gcash:
      case PaymentMethodType.maya:
      case PaymentMethodType.gotyme:
        return method.accountNumber != null
            ? '${method.accountNumber}'
            : method.type.displayName;
    }
  }

  Widget _buildRouteSelector() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          value: _selectedRouteId,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          dropdownColor: Colors.grey[800],
          style: const TextStyle(color: Colors.white),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.amber),
          items:
              _mockRoutes.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text('${entry.key} - ${entry.value}'),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedRouteId = value;
            });
            _updateFare();
          },
        ),
      ),
    );
  }

  Widget _buildPassengerTypeSelector() {
    return Row(
      children:
          PassengerType.values.map((type) {
            final isSelected = _selectedPassengerType == type;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPassengerType = type;
                  });
                  _updateFare();
                },
                child: Card(
                  color:
                      isSelected
                          ? Color.fromRGBO(255, 193, 7, 0.2)
                          : Colors.grey[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? Colors.amber : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Icon(
                          _getPassengerTypeIcon(type),
                          color: isSelected ? Colors.amber : Colors.white,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          type.displayName,
                          style: TextStyle(
                            color: isSelected ? Colors.amber : Colors.white,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (type != PassengerType.regular)
                          Text(
                            '${(type.discountRate * 100).toInt()}% OFF',
                            style: TextStyle(
                              color: isSelected ? Colors.amber : Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  IconData _getPassengerTypeIcon(PassengerType type) {
    switch (type) {
      case PassengerType.regular:
        return Icons.person;
      case PassengerType.student:
        return Icons.school;
      case PassengerType.seniorCitizen:
        return Icons.elderly;
    }
  }

  Widget _buildFareSummary() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Route', style: TextStyle(color: Colors.grey)),
                Text(
                  _selectedRouteId != null
                      ? '$_selectedRouteId - ${_mockRoutes[_selectedRouteId]}'
                      : 'Not selected',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Passenger Type',
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  _selectedPassengerType.displayName,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Distance', style: TextStyle(color: Colors.grey)),
                const Text(
                  '5.0 km', // Mock distance
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            const Divider(color: Colors.grey),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Fare',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '₱${_fareAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed:
              _selectedPaymentMethod != null && _selectedRouteId != null
                  ? _processPayment
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Pay Now',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _navigateToQRScanner,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.amber,
            side: const BorderSide(color: Colors.amber),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan QR to Pay', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  void _processPayment() {
    // In a real app, this would process the payment
    // For now, just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
