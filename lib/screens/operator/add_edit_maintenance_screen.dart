import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vehicle_model.dart';

class AddEditMaintenanceScreen extends StatefulWidget {
  final Vehicle vehicle;
  final MaintenanceReminder? reminder;

  const AddEditMaintenanceScreen({
    super.key,
    required this.vehicle,
    this.reminder,
  });

  @override
  State<AddEditMaintenanceScreen> createState() =>
      _AddEditMaintenanceScreenState();
}

class _AddEditMaintenanceScreenState extends State<AddEditMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _dueDateController;
  late TextEditingController _dueMileageController;
  late TextEditingController _notesController;

  MaintenanceType _selectedType = MaintenanceType.oilChange;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.reminder != null;

    // Initialize controllers with existing data if editing
    if (_isEditing) {
      _selectedType = widget.reminder!.type;
      _dueDate = widget.reminder!.dueDate;

      _descriptionController = TextEditingController(
        text: widget.reminder!.description,
      );
      _dueMileageController = TextEditingController(
        text: widget.reminder!.dueMileage?.toString() ?? '',
      );
      _notesController = TextEditingController(text: widget.reminder!.notes);
    } else {
      _descriptionController = TextEditingController();
      _dueMileageController = TextEditingController();
      _notesController = TextEditingController();
    }

    // Initialize date controller with formatted date
    _dueDateController = TextEditingController(
      text: DateFormat('MMM d, yyyy').format(_dueDate),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _dueDateController.dispose();
    _dueMileageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.amber,
              onPrimary: Colors.black,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
        _dueDateController.text = DateFormat('MMM d, yyyy').format(_dueDate);
      });
    }
  }

  void _saveReminder() {
    if (_formKey.currentState!.validate()) {
      // Create a new reminder object
      final reminder = MaintenanceReminder(
        id:
            _isEditing
                ? widget.reminder!.id
                : DateTime.now().millisecondsSinceEpoch.toString(),
        type: _selectedType,
        description: _descriptionController.text.trim(),
        dueDate: _dueDate,
        dueMileage:
            _dueMileageController.text.isNotEmpty
                ? int.parse(_dueMileageController.text)
                : null,
        isCompleted: _isEditing ? widget.reminder!.isCompleted : false,
        completedDate: _isEditing ? widget.reminder!.completedDate : null,
        notes: _notesController.text.trim(),
      );

      // Return the reminder to the calling screen
      Navigator.of(context).pop(reminder);
    }
  }

  IconData _getVehicleTypeIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'jeepney':
        return Icons.airport_shuttle;
      case 'bus':
        return Icons.directions_bus;
      case 'van':
        return Icons.local_taxi;
      case 'taxi':
        return Icons.local_taxi;
      case 'multicab':
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Maintenance' : 'Add Maintenance'),
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
                // Vehicle info card
                _buildVehicleCard(),

                // Maintenance type dropdown
                const Text(
                  'Maintenance Type',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTypeDropdown(),
                const SizedBox(height: 16),

                // Description field
                _buildDescriptionField(),
                const SizedBox(height: 16),

                // Due date field
                _buildDateField(),
                const SizedBox(height: 16),

                // Due mileage field
                _buildMileageField(),
                const SizedBox(height: 16),

                // Notes field
                _buildNotesField(),
                const SizedBox(height: 24),

                // Save button
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF222222),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getVehicleTypeIcon(widget.vehicle.vehicleType),
                color: Colors.amber,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.vehicle.plateNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${widget.vehicle.model} (${widget.vehicle.year})',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Current Odometer: ${widget.vehicle.odometerReading} km',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<MaintenanceType>(
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white30),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.amber),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        fillColor: Colors.black.withAlpha(100),
        filled: true,
      ),
      dropdownColor: Color(0xFF222222),
      style: TextStyle(color: Colors.white),
      value: _selectedType,
      items:
          MaintenanceType.values.map((type) {
            return DropdownMenuItem<MaintenanceType>(
              value: type,
              child: Text(type.name),
            );
          }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedType = value;

            // Auto-fill description if it's empty
            if (_descriptionController.text.isEmpty) {
              _descriptionController.text = value.name;
            }
          });
        }
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Description',
        labelStyle: TextStyle(color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.amber),
        ),
        fillColor: Colors.black.withAlpha(100),
        filled: true,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: AbsorbPointer(
        child: TextFormField(
          controller: _dueDateController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Due Date',
            labelStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.amber),
            ),
            suffixIcon: const Icon(Icons.calendar_today, color: Colors.amber),
            fillColor: Colors.black.withAlpha(100),
            filled: true,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a due date';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildMileageField() {
    return TextFormField(
      controller: _dueMileageController,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Due Mileage (km, optional)',
        labelStyle: TextStyle(color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.amber),
        ),
        suffixIcon: const Icon(Icons.speed, color: Colors.amber),
        fillColor: Colors.black.withAlpha(100),
        filled: true,
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final mileage = int.tryParse(value);
          if (mileage == null) {
            return 'Please enter a valid number';
          }
          if (mileage <= widget.vehicle.odometerReading) {
            return 'Mileage must be greater than current odometer reading';
          }
        }
        return null;
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Notes (optional)',
        labelStyle: TextStyle(color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.amber),
        ),
        alignLabelWithHint: true,
        fillColor: Colors.black.withAlpha(100),
        filled: true,
      ),
      maxLines: 3,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveReminder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(_isEditing ? 'Update Reminder' : 'Add Reminder'),
      ),
    );
  }
}
