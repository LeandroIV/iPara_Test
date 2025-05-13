import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/fare_model.dart';
import '../../services/payment_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  bool _isScanning = true;

  // Mock QR scan result
  String? _scanResult;

  // Payment details
  String? _routeId;
  String? _routeCode;
  double _amount = 0.0;
  PassengerType _passengerType = PassengerType.regular;

  @override
  void initState() {
    super.initState();
    // Simulate QR scanning after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _simulateScan();
      }
    });
  }

  void _simulateScan() {
    // Mock QR code data
    final qrData =
        'IPARA:PAY:route2:25.0:regular:${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _isScanning = false;
      _scanResult = qrData;
    });

    _processQRData(qrData);
  }

  void _processQRData(String data) {
    try {
      // Parse QR data (format: IPARA:PAY:routeId:amount:passengerType:timestamp)
      final parts = data.split(':');
      if (parts.length >= 6 && parts[0] == 'IPARA' && parts[1] == 'PAY') {
        setState(() {
          _routeId = parts[2];
          _routeCode = _getRouteCode(_routeId!);
          _amount = double.parse(parts[3]);
          _passengerType = _getPassengerType(parts[4]);
        });
      } else {
        _showErrorSnackBar('Invalid QR code format');
      }
    } catch (e) {
      _showErrorSnackBar('Error processing QR code');
    }
  }

  String _getRouteCode(String routeId) {
    // Mock route codes
    final Map<String, String> routeCodes = {
      'route1': 'R1',
      'route2': 'R2',
      'route3': 'R3',
      'route4': 'R4',
    };

    return routeCodes[routeId] ?? 'Unknown';
  }

  PassengerType _getPassengerType(String type) {
    switch (type.toLowerCase()) {
      case 'student':
        return PassengerType.student;
      case 'seniorcitizen':
        return PassengerType.seniorCitizen;
      default:
        return PassengerType.regular;
    }
  }

  Future<void> _confirmPayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, this would process the payment
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success dialog
        _showPaymentSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Payment failed');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            // Fix overflow by using a constrained width title
            titlePadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            title: const Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Text(
                  'Payment Successful',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxWidth: 280),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your payment for Route $_routeCode has been processed successfully.',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount', style: TextStyle(color: Colors.grey[400])),
                      Text(
                        '₱${_amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Passenger Type',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      Text(
                        _passengerType.displayName,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date & Time',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      Text(
                        _formatDateTime(DateTime.now()),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to payment screen
                },
                child: const Text(
                  'Done',
                  style: TextStyle(color: Colors.amber),
                ),
              ),
            ],
          ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
      ),
      backgroundColor: Colors.black,
      body: _isScanning ? _buildScannerView() : _buildPaymentConfirmation(),
    );
  }

  Widget _buildScannerView() {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.amber, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Mock camera preview
                  Container(
                    color: Colors.grey[900],
                    child: Center(
                      child: Icon(
                        Icons.qr_code_scanner,
                        color: Colors.grey[700],
                        size: 120,
                      ),
                    ),
                  ),

                  // Scanning animation
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                  ),

                  // Scanning line animation
                  AnimatedPositioned(
                    duration: const Duration(seconds: 2),
                    top: 0,
                    left: 0,
                    right: 0,
                    curve: Curves.easeInOut,
                    child: Container(height: 2, color: Colors.amber),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Position the QR code within the frame to scan',
            style: TextStyle(color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentConfirmation() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.amber))
        : Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // QR scan result
              Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QR Code Scanned',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _scanResult ?? 'No data',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Payment details
              const Text(
                'Payment Details',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDetailRow('Route', 'Route $_routeCode'),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Passenger Type',
                        _passengerType.displayName,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Amount',
                        '₱${_amount.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Confirm payment button
              ElevatedButton(
                onPressed: _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm Payment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel button
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber,
                  side: const BorderSide(color: Colors.amber),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400])),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
