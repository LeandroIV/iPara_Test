import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_role.dart';

class AddDriverScreen extends StatefulWidget {
  const AddDriverScreen({super.key});

  @override
  State<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends State<AddDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _plateNumberController = TextEditingController();
  
  // Dropdown values
  String _selectedPuvType = 'Jeepney';
  final List<String> _puvTypes = ['Jeepney', 'Bus', 'Multicab', 'Motorela'];
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _plateNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveDriver() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final operatorId = _auth.currentUser?.uid;
      if (operatorId == null) {
        throw Exception('No authenticated user found');
      }

      // Create a new driver document in the driver_locations collection
      await _firestore.collection('driver_locations').add({
        'driverName': _nameController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneController.text,
        'licenseNumber': _licenseController.text,
        'plateNumber': _plateNumberController.text,
        'puvType': _selectedPuvType,
        'operatorId': operatorId,
        'isOnline': false,
        'isLocationVisible': true,
        'lastUpdated': FieldValue.serverTimestamp(),
        'location': const GeoPoint(8.4806, 124.6497), // Default to CDO center
        'heading': 0.0,
        'speed': 0.0,
        'status': 'Inactive',
        'rating': 5.0, // Default rating
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to the previous screen
        Navigator.pop(context, true); // Pass true to indicate success
      }
    } catch (e) {
      debugPrint('Error adding driver: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding driver: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Driver'),
        backgroundColor: Colors.grey[900],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Driver information section
                    const Text(
                      'Driver Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Driver name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Driver Name',
                        hintText: 'Enter full name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter driver name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter email address',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone number
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter phone number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // License number
                    TextFormField(
                      controller: _licenseController,
                      decoration: const InputDecoration(
                        labelText: 'License Number',
                        hintText: 'Enter driver license number',
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter license number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Vehicle information section
                    const Text(
                      'Vehicle Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Plate number
                    TextFormField(
                      controller: _plateNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Plate Number',
                        hintText: 'Enter vehicle plate number',
                        prefixIcon: Icon(Icons.directions_car),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter plate number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // PUV type dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedPuvType,
                      decoration: const InputDecoration(
                        labelText: 'PUV Type',
                        prefixIcon: Icon(Icons.local_taxi),
                      ),
                      items: _puvTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPuvType = value;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select PUV type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveDriver,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Add Driver',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
