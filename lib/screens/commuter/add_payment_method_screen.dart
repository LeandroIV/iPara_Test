import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/payment_method_model.dart';
import '../../services/payment_service.dart';

class AddPaymentMethodScreen extends StatefulWidget {
  final PaymentMethod? paymentMethod; // For editing existing method

  const AddPaymentMethodScreen({super.key, this.paymentMethod});

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  final PaymentService _paymentService = PaymentService();
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  
  // Selected payment method type
  PaymentMethodType _selectedType = PaymentMethodType.creditCard;
  
  // Is default payment method
  bool _isDefault = false;
  
  // Loading state
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    // If editing existing payment method, populate the form
    if (widget.paymentMethod != null) {
      _nameController.text = widget.paymentMethod!.name;
      _selectedType = widget.paymentMethod!.type;
      _isDefault = widget.paymentMethod!.isDefault;
      
      // Populate type-specific fields
      switch (_selectedType) {
        case PaymentMethodType.creditCard:
        case PaymentMethodType.debitCard:
          _cardNumberController.text = widget.paymentMethod!.cardNumber ?? '';
          _expiryDateController.text = widget.paymentMethod!.expiryDate ?? '';
          break;
        case PaymentMethodType.gcash:
        case PaymentMethodType.maya:
        case PaymentMethodType.gotyme:
          _accountNumberController.text = widget.paymentMethod!.accountNumber ?? '';
          break;
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }
  
  Future<void> _savePaymentMethod() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Create payment method object
      final PaymentMethod method = PaymentMethod(
        id: widget.paymentMethod?.id ?? '',
        userId: widget.paymentMethod?.userId ?? '',
        type: _selectedType,
        name: _nameController.text,
        cardNumber: _isCardPayment() ? _cardNumberController.text : null,
        expiryDate: _isCardPayment() ? _expiryDateController.text : null,
        accountNumber: !_isCardPayment() ? _accountNumberController.text : null,
        isDefault: _isDefault,
      );
      
      bool success;
      if (widget.paymentMethod == null) {
        // Add new payment method
        final id = await _paymentService.addPaymentMethod(method);
        success = id != null;
      } else {
        // Update existing payment method
        success = await _paymentService.updatePaymentMethod(method);
      }
      
      if (success) {
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        _showErrorSnackBar('Failed to save payment method');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  bool _isCardPayment() {
    return _selectedType == PaymentMethodType.creditCard || 
           _selectedType == PaymentMethodType.debitCard;
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.paymentMethod == null 
            ? 'Add Payment Method' 
            : 'Edit Payment Method'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment method type selector
                    _buildSectionTitle('Payment Method Type'),
                    const SizedBox(height: 8),
                    _buildPaymentTypeSelector(),
                    
                    const SizedBox(height: 24),
                    
                    // Payment method details
                    _buildSectionTitle('Payment Details'),
                    const SizedBox(height: 8),
                    _buildPaymentDetailsForm(),
                    
                    const SizedBox(height: 24),
                    
                    // Default payment method toggle
                    _buildDefaultToggle(),
                    
                    const SizedBox(height: 32),
                    
                    // Save button
                    ElevatedButton(
                      onPressed: _savePaymentMethod,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.paymentMethod == null ? 'Add Payment Method' : 'Save Changes',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
  
  Widget _buildPaymentTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: PaymentMethodType.values.map((type) {
          final isSelected = _selectedType == type;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = type;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.amber.withAlpha(50) : Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.amber : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getPaymentTypeIcon(type),
                      color: isSelected ? Colors.amber : Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      type.displayName,
                      style: TextStyle(
                        color: isSelected ? Colors.amber : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  IconData _getPaymentTypeIcon(PaymentMethodType type) {
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
  
  Widget _buildPaymentDetailsForm() {
    return Column(
      children: [
        // Name field (common for all payment types)
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Name on ${_isCardPayment() ? 'Card' : 'Account'}',
            labelStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.person, color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Card-specific fields
        if (_isCardPayment()) ...[
          // Card number field
          TextFormField(
            controller: _cardNumberController,
            decoration: InputDecoration(
              labelText: 'Card Number',
              labelStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.credit_card, color: Colors.grey),
            ),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberFormatter(),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a card number';
              }
              if (value.replaceAll(' ', '').length < 16) {
                return 'Please enter a valid 16-digit card number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Expiry date and CVV fields
          Row(
            children: [
              // Expiry date field
              Expanded(
                child: TextFormField(
                  controller: _expiryDateController,
                  decoration: InputDecoration(
                    labelText: 'Expiry Date (MM/YY)',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _ExpiryDateFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter expiry date';
                    }
                    if (value.length < 5) {
                      return 'Invalid format';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              
              // CVV field
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.security, color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter CVV';
                    }
                    if (value.length < 3) {
                      return 'Invalid CVV';
                    }
                    return null;
                  },
                  obscureText: true,
                ),
              ),
            ],
          ),
        ],
        
        // E-wallet specific fields
        if (!_isCardPayment()) ...[
          // Account number field
          TextFormField(
            controller: _accountNumberController,
            decoration: InputDecoration(
              labelText: 'Account Number / Mobile Number',
              labelStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.phone_android, color: Colors.grey),
            ),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an account number';
              }
              if (value.length < 11) {
                return 'Please enter a valid 11-digit mobile number';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
  
  Widget _buildDefaultToggle() {
    return SwitchListTile(
      title: const Text(
        'Set as Default Payment Method',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: const Text(
        'This payment method will be selected by default',
        style: TextStyle(color: Colors.grey),
      ),
      value: _isDefault,
      onChanged: (value) {
        setState(() {
          _isDefault = value;
        });
      },
      activeColor: Colors.amber,
      contentPadding: EdgeInsets.zero,
    );
  }
}

/// Custom formatter for credit card numbers
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Remove all non-digits
    String value = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    // Format with spaces after every 4 digits
    final buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      buffer.write(value[i]);
      if ((i + 1) % 4 == 0 && i != value.length - 1) {
        buffer.write(' ');
      }
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// Custom formatter for expiry dates
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Remove all non-digits
    String value = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    // Format as MM/YY
    final buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      buffer.write(value[i]);
      if (i == 1 && i != value.length - 1) {
        buffer.write('/');
      }
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
