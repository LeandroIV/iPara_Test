import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vehicle_model.dart';
import '../../services/vehicle_service.dart';
import '../operator/add_edit_maintenance_screen.dart';

class VehicleMaintenanceScreen extends StatefulWidget {
  final String? vehicleId;

  const VehicleMaintenanceScreen({super.key, this.vehicleId});

  @override
  State<VehicleMaintenanceScreen> createState() =>
      _VehicleMaintenanceScreenState();
}

class _VehicleMaintenanceScreenState extends State<VehicleMaintenanceScreen> {
  final VehicleService _vehicleService = VehicleService();
  bool _isLoading = true;
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  List<MaintenanceReminder> _upcomingReminders = [];
  List<MaintenanceReminder> _overdueReminders = [];
  List<MaintenanceReminder> _completedReminders = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch vehicles from Firestore
      final vehicles = await _vehicleService.getVehicles();

      setState(() {
        _vehicles = vehicles;

        // If a specific vehicle ID was passed, select that vehicle
        if (widget.vehicleId != null) {
          if (_vehicles.any((v) => v.id == widget.vehicleId)) {
            _selectedVehicle = _vehicles.firstWhere(
              (v) => v.id == widget.vehicleId,
            );
          } else if (_vehicles.isNotEmpty) {
            _selectedVehicle = _vehicles.first;
          }
        } else if (_vehicles.isNotEmpty) {
          _selectedVehicle = _vehicles.first;
        }

        _updateReminderLists();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading vehicles: $e');

      setState(() {
        _isLoading = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading vehicles: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _updateReminderLists() {
    if (_selectedVehicle == null) {
      _upcomingReminders = [];
      _overdueReminders = [];
      _completedReminders = [];
      return;
    }

    final allReminders = _selectedVehicle!.maintenanceReminders;

    // Get completed reminders
    _completedReminders =
        allReminders.where((reminder) => reminder.isCompleted).toList();

    // Get overdue reminders
    _overdueReminders = _vehicleService.getOverdueReminders(_selectedVehicle!);

    // Get upcoming reminders (not overdue and not completed)
    _upcomingReminders = _vehicleService.getUpcomingReminders(
      _selectedVehicle!,
    );
  }

  Future<void> _markReminderComplete(MaintenanceReminder reminder) async {
    if (_selectedVehicle == null) return;

    // Show a dialog to confirm and add notes
    final TextEditingController notesController = TextEditingController();
    notesController.text = reminder.notes;

    final bool? shouldComplete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Color(0xFF222222),
            title: Text(
              'Complete Maintenance',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mark "${reminder.description}" as completed?',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    labelStyle: TextStyle(color: Colors.amber),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.amber),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                child: Text('Complete'),
              ),
            ],
          ),
    );

    if (shouldComplete == true) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Update Firestore
        await _vehicleService.completeMaintenanceReminder(
          _selectedVehicle!.id,
          reminder.id,
          notes: notesController.text,
        );

        // Refresh the vehicle list
        await _loadVehicles();

        setState(() {
          _isLoading = false;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maintenance marked as completed'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Maintenance'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading && _vehicles.isNotEmpty && _selectedVehicle != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                // Navigate to add maintenance screen
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AddEditMaintenanceScreen(
                          vehicle: _selectedVehicle!,
                        ),
                  ),
                );

                // If a reminder was added, refresh the list
                if (result != null && result is MaintenanceReminder) {
                  await _vehicleService.addMaintenanceReminder(
                    _selectedVehicle!.id,
                    result,
                  );
                  _loadVehicles();
                }
              },
              tooltip: 'Add Maintenance Reminder',
            ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.amber),
                    const SizedBox(height: 16),
                    Text(
                      'Loading vehicle data...',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              )
              : _vehicles.isEmpty
              ? _buildNoVehiclesMessage()
              : _buildMainContent(),
    );
  }

  Widget _buildNoVehiclesMessage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Color(0xFF1A1A1A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.no_crash, size: 64, color: Colors.amber),
            ),
            const SizedBox(height: 24),
            const Text(
              'No vehicles assigned to you',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Contact your operator to assign a vehicle',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Refresh the vehicle list
                _loadVehicles();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        if (_vehicles.length > 1) _buildVehicleSelector(),
        Expanded(
          child:
              _selectedVehicle == null
                  ? const Center(child: Text('Select a vehicle'))
                  : _buildVehicleDetails(),
        ),
      ],
    );
  }

  Widget _buildVehicleSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Color(0xFF1A1A1A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Vehicle',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withAlpha(25),
              border: Border.all(color: Colors.white30),
            ),
            child: DropdownButtonFormField<String>(
              isExpanded: true, // Make dropdown take full width
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              dropdownColor: Color(0xFF1A1A1A),
              icon: Icon(Icons.arrow_drop_down, color: Colors.amber),
              style: TextStyle(color: Colors.white, fontSize: 16),
              value: _selectedVehicle?.id,
              items:
                  _vehicles.map((vehicle) {
                    return DropdownMenuItem<String>(
                      value: vehicle.id,
                      child: Row(
                        children: [
                          Icon(
                            _getVehicleTypeIcon(vehicle.vehicleType),
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              '${vehicle.plateNumber} - ${vehicle.model}',
                              style: TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedVehicle = _vehicles.firstWhere(
                      (v) => v.id == value,
                    );
                    _updateReminderLists();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
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
      case 'tricycle':
        return Icons.motorcycle;
      default:
        return Icons.directions_car;
    }
  }

  Widget _buildVehicleDetails() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Color(0xFF1A1A1A)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVehicleInfoCard(),
            const SizedBox(height: 24),

            // Overdue maintenance section
            if (_overdueReminders.isNotEmpty) ...[
              _buildSectionHeader('Overdue Maintenance', Colors.red),
              ..._overdueReminders.map(
                (reminder) => _buildReminderCard(reminder, isOverdue: true),
              ),
              const SizedBox(height: 16),
            ],

            // Upcoming maintenance section
            if (_upcomingReminders.isNotEmpty) ...[
              _buildSectionHeader('Upcoming Maintenance', Colors.blue),
              ..._upcomingReminders.map(
                (reminder) => _buildReminderCard(reminder),
              ),
              const SizedBox(height: 16),
            ],

            // Completed maintenance section
            if (_completedReminders.isNotEmpty) ...[
              _buildSectionHeader('Completed Maintenance', Colors.green),
              ..._completedReminders.map(
                (reminder) => _buildReminderCard(reminder, isCompleted: true),
              ),
            ],

            // No reminders message
            if (_overdueReminders.isEmpty &&
                _upcomingReminders.isEmpty &&
                _completedReminders.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No maintenance reminders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    if (_selectedVehicle == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color(0xFF222222),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              color: Colors.black,
            ),
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
                    _getVehicleTypeIcon(_selectedVehicle!.vehicleType),
                    size: 30,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedVehicle!.plateNumber,
                        style: const TextStyle(
                          fontSize: 20, // Slightly smaller font
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_selectedVehicle!.model} (${_selectedVehicle!.year})',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Vehicle info items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  flex: 1,
                  child: _buildVehicleInfoItem(
                    'Type',
                    _selectedVehicle!.vehicleType,
                    Icons.category,
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: _buildVehicleInfoItem(
                    'Odometer',
                    '${_selectedVehicle!.odometerReading} km',
                    Icons.speed,
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: _buildVehicleInfoItem(
                    'Status',
                    _selectedVehicle!.isActive ? 'Active' : 'Inactive',
                    Icons.info,
                    color:
                        _selectedVehicle!.isActive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoItem(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (color ?? Colors.amber).withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color ?? Colors.amber, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 14, // Reduced font size
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
            margin: const EdgeInsets.only(right: 12),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (title == 'Upcoming Maintenance')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_upcomingReminders.length}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          if (title == 'Overdue Maintenance')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_overdueReminders.length}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(
    MaintenanceReminder reminder, {
    bool isOverdue = false,
    bool isCompleted = false,
  }) {
    final Color accentColor =
        isOverdue
            ? Colors.red
            : isCompleted
            ? Colors.green
            : Colors.blue;

    final dateFormat = DateFormat('MMM d, yyyy');
    final dueDate = dateFormat.format(reminder.dueDate);
    final completedDate =
        reminder.completedDate != null
            ? dateFormat.format(reminder.completedDate!)
            : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color(0xFF222222),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with icon and title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(20),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getMaintenanceIcon(reminder.type),
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.description,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${reminder.type.name}${reminder.dueMileage != null ? ' • ${reminder.dueMileage} km' : ''}',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                isCompleted
                    ? Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, color: Colors.green, size: 20),
                    )
                    : IconButton(
                      icon: Icon(
                        isOverdue
                            ? Icons.warning_amber
                            : Icons.check_circle_outline,
                        color: accentColor,
                      ),
                      onPressed: () => _markReminderComplete(reminder),
                      tooltip: 'Mark as completed',
                    ),
              ],
            ),
          ),

          // Date information
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isCompleted ? Icons.event_available : Icons.event,
                  color: accentColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isCompleted
                      ? 'Completed on $completedDate'
                      : isOverdue
                      ? 'Overdue since $dueDate'
                      : 'Due on $dueDate',
                  style: TextStyle(
                    color: isOverdue ? accentColor : Colors.white70,
                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),

          // Notes (if any)
          if (reminder.notes.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reminder.notes,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getMaintenanceIcon(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.oilChange:
        return Icons.opacity;
      case MaintenanceType.tireRotation:
        return Icons.rotate_right;
      case MaintenanceType.brakeService:
        return Icons.warning;
      case MaintenanceType.engineTuneUp:
        return Icons.settings;
      case MaintenanceType.transmission:
        return Icons.settings_input_component;
      case MaintenanceType.airFilter:
        return Icons.air;
      case MaintenanceType.fuelFilter:
        return Icons.local_gas_station;
      case MaintenanceType.batteryReplacement:
        return Icons.battery_charging_full;
      case MaintenanceType.coolantFlush:
        return Icons.water_drop;
      case MaintenanceType.generalInspection:
        return Icons.search;
      case MaintenanceType.other:
        return Icons.build;
    }
  }
}
