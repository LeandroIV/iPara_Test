import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/vehicle_model.dart';

class AddEditVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const AddEditVehicleScreen({super.key, this.vehicle});

  @override
  State<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends State<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TextEditingController _plateNumberController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _odometerController;

  String _selectedVehicleType = 'Jeepney';
  bool _isActive = true;
  bool _isEditing = false;

  final List<String> _vehicleTypes = [
    'Jeepney',
    'Bus',
    'Multicab',
    'Van',
    'Taxi',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.vehicle != null;

    // Initialize controllers with existing data if editing
    if (_isEditing) {
      _plateNumberController = TextEditingController(
        text: widget.vehicle!.plateNumber,
      );
      _modelController = TextEditingController(text: widget.vehicle!.model);
      _yearController = TextEditingController(
        text: widget.vehicle!.year.toString(),
      );
      _odometerController = TextEditingController(
        text: widget.vehicle!.odometerReading.toString(),
      );
      _selectedVehicleType = widget.vehicle!.vehicleType;
      _isActive = widget.vehicle!.isActive;
    } else {
      _plateNumberController = TextEditingController();
      _modelController = TextEditingController();
      _yearController = TextEditingController(
        text: DateTime.now().year.toString(),
      );
      _odometerController = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _plateNumberController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  void _saveVehicle() {
    if (_formKey.currentState!.validate()) {
      // Get the current user ID
      final currentUserId = _auth.currentUser?.uid;

      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to add a vehicle'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create a new vehicle object
      final vehicle = Vehicle(
        id:
            _isEditing
                ? widget.vehicle!.id
                : DateTime.now().millisecondsSinceEpoch.toString(),
        plateNumber: _plateNumberController.text.trim().toUpperCase(),
        vehicleType: _selectedVehicleType,
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text),
        odometerReading: int.parse(_odometerController.text),
        operatorId: _isEditing ? widget.vehicle!.operatorId : currentUserId,
        driverId: _isEditing ? widget.vehicle!.driverId : null,
        routeId: _isEditing ? widget.vehicle!.routeId : null,
        isActive: _isActive,
        maintenanceReminders:
            _isEditing ? widget.vehicle!.maintenanceReminders : [],
      );

      // Return the vehicle to the calling screen
      Navigator.of(context).pop(vehicle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Vehicle' : 'Add Vehicle'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF1A1A1A)],
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plate number field
                TextFormField(
                  controller: _plateNumberController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Plate Number',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.amber),
                    ),
                    prefixIcon: const Icon(
                      Icons.directions_car,
                      color: Colors.amber,
                    ),
                    fillColor: Colors.black.withAlpha(100),
                    filled: true,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a plate number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Vehicle type dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Vehicle Type',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.amber),
                    ),
                    prefixIcon: const Icon(Icons.category, color: Colors.amber),
                    fillColor: Colors.black.withAlpha(100),
                    filled: true,
                  ),
                  dropdownColor: Color(0xFF222222),
                  style: TextStyle(color: Colors.white),
                  value: _selectedVehicleType,
                  items:
                      _vehicleTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedVehicleType = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a vehicle type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Model field
                TextFormField(
                  controller: _modelController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Model',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.amber),
                    ),
                    prefixIcon: const Icon(
                      Icons.model_training,
                      color: Colors.amber,
                    ),
                    fillColor: Colors.black.withAlpha(100),
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a model';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Year field
                TextFormField(
                  controller: _yearController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Year',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.amber),
                    ),
                    prefixIcon: const Icon(
                      Icons.calendar_today,
                      color: Colors.amber,
                    ),
                    fillColor: Colors.black.withAlpha(100),
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a year';
                    }
                    final year = int.tryParse(value);
                    if (year == null) {
                      return 'Please enter a valid year';
                    }
                    if (year < 1900 || year > DateTime.now().year + 1) {
                      return 'Please enter a valid year between 1900 and ${DateTime.now().year + 1}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Odometer field
                TextFormField(
                  controller: _odometerController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Odometer Reading (km)',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.amber),
                    ),
                    prefixIcon: const Icon(Icons.speed, color: Colors.amber),
                    fillColor: Colors.black.withAlpha(100),
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the odometer reading';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Active status switch
                SwitchListTile(
                  title: const Text(
                    'Active Status',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    _isActive ? 'Vehicle is active' : 'Vehicle is inactive',
                    style: TextStyle(color: Colors.white70),
                  ),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  activeColor: Colors.amber,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white30),
                  ),
                  tileColor: Colors.black.withAlpha(100),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveVehicle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      _isEditing ? 'Update Vehicle' : 'Add Vehicle',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
