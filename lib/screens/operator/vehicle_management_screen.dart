import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vehicle_model.dart';
import '../../services/vehicle_service.dart';
import '../driver/vehicle_maintenance_screen.dart';
import 'add_edit_maintenance_screen.dart';
import 'add_edit_vehicle_screen.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() =>
      _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  final VehicleService _vehicleService = VehicleService();
  bool _isLoading = true;
  List<Vehicle> _vehicles = [];

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

  Future<void> _addVehicle() async {
    try {
      // Navigate to add vehicle screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddEditVehicleScreen()),
      );

      // If a vehicle was added, save it to Firestore
      if (result != null && result is Vehicle) {
        setState(() {
          _isLoading = true;
        });

        final vehicleId = await _vehicleService.addVehicle(result);

        if (vehicleId != null) {
          // Refresh the vehicle list
          await _loadVehicles();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Vehicle ${result.plateNumber} added successfully',
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to add vehicle'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error adding vehicle: $e');
      setState(() {
        _isLoading = false;
      });

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

  Future<void> _editVehicle(Vehicle vehicle) async {
    try {
      // Navigate to edit vehicle screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditVehicleScreen(vehicle: vehicle),
        ),
      );

      // If a vehicle was edited, update it in Firestore
      if (result != null && result is Vehicle) {
        setState(() {
          _isLoading = true;
        });

        final success = await _vehicleService.updateVehicle(result);

        if (success) {
          // Refresh the vehicle list
          await _loadVehicles();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Vehicle ${result.plateNumber} updated successfully',
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update vehicle'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating vehicle: $e');
      setState(() {
        _isLoading = false;
      });

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

  Future<void> _deleteVehicle(Vehicle vehicle) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Color(0xFF222222),
            title: const Text(
              'Delete Vehicle',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to delete ${vehicle.plateNumber}?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Delete from Firestore
        final success = await _vehicleService.deleteVehicle(vehicle.id);

        if (success) {
          // Update local state
          setState(() {
            _vehicles.removeWhere((v) => v.id == vehicle.id);
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Deleted ${vehicle.plateNumber}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete vehicle'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error deleting vehicle: $e');
        setState(() {
          _isLoading = false;
        });

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

  void _navigateToMaintenanceScreen(Vehicle vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleMaintenanceScreen(vehicleId: vehicle.id),
      ),
    ).then((_) {
      // Refresh the vehicle list when returning from maintenance screen
      _loadVehicles();
    });
  }

  Future<void> _addMaintenanceReminder(Vehicle vehicle) async {
    try {
      // Navigate to add maintenance screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditMaintenanceScreen(vehicle: vehicle),
        ),
      );

      // If a reminder was added, save it to Firestore
      if (result != null && result is MaintenanceReminder) {
        setState(() {
          _isLoading = true;
        });

        final success = await _vehicleService.addMaintenanceReminder(
          vehicle.id,
          result,
        );

        // Refresh the vehicle list
        await _loadVehicles();

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Maintenance reminder added'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to add maintenance reminder'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error adding maintenance reminder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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
        title: const Text('Vehicle Management'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVehicles,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF1A1A1A)],
          ),
        ),
        child:
            _isLoading
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.amber),
                      const SizedBox(height: 16),
                      Text(
                        'Loading vehicles...',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                )
                : _vehicles.isEmpty
                ? _buildNoVehiclesMessage()
                : _buildVehicleList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addVehicle,
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        tooltip: 'Add Vehicle',
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoVehiclesMessage() {
    return Center(
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
            'No vehicles found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tap the + button to add a vehicle',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _addVehicle,
            icon: const Icon(Icons.add),
            label: const Text('Add Vehicle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        return _buildVehicleCard(vehicle);
      },
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    final overdueReminders = _vehicleService.getOverdueReminders(vehicle);
    final upcomingReminders = _vehicleService.getUpcomingReminders(vehicle);
    final completedReminders =
        vehicle.maintenanceReminders
            .where((reminder) => reminder.isCompleted)
            .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        childrenPadding: const EdgeInsets.all(16),
        collapsedBackgroundColor: Colors.transparent,
        backgroundColor: Colors.black.withAlpha(50),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color:
                vehicle.isActive
                    ? Colors.amber.withAlpha(30)
                    : Colors.grey.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getVehicleTypeIcon(vehicle.vehicleType),
            color: vehicle.isActive ? Colors.amber : Colors.grey,
            size: 30,
          ),
        ),
        title: Text(
          vehicle.plateNumber,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${vehicle.model} (${vehicle.year})',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speed, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '${vehicle.odometerReading} km',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (overdueReminders.isNotEmpty)
                  _buildReminderBadge(
                    overdueReminders.length,
                    Colors.red,
                    'Overdue',
                  ),
                if (upcomingReminders.isNotEmpty)
                  _buildReminderBadge(
                    upcomingReminders.length,
                    Colors.amber,
                    'Upcoming',
                  ),
              ],
            ),
          ],
        ),
        trailing: SizedBox(
          width: 96, // Fixed width to prevent overflow
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.amber),
                onPressed: () => _editVehicle(vehicle),
                tooltip: 'Edit Vehicle',
                constraints: BoxConstraints(maxWidth: 40),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteVehicle(vehicle),
                tooltip: 'Delete Vehicle',
                constraints: BoxConstraints(maxWidth: 40),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(50),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Maintenance Reminders',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _addMaintenanceReminder(vehicle),
                      icon: Icon(Icons.add),
                      label: Text('Add Reminder'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.amber,
                        backgroundColor: Colors.amber.withAlpha(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Overdue reminders
                if (overdueReminders.isNotEmpty) ...[
                  _buildReminderSection(
                    'Overdue',
                    overdueReminders,
                    Colors.red,
                  ),
                  const SizedBox(height: 16),
                ],

                // Upcoming reminders
                if (upcomingReminders.isNotEmpty) ...[
                  _buildReminderSection(
                    'Upcoming',
                    upcomingReminders,
                    Colors.amber,
                  ),
                  const SizedBox(height: 16),
                ],

                // Completed reminders
                if (completedReminders.isNotEmpty) ...[
                  _buildReminderSection(
                    'Completed',
                    completedReminders
                        .take(3)
                        .toList(), // Show only the latest 3
                    Colors.green,
                  ),
                  if (completedReminders.length > 3)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _navigateToMaintenanceScreen(vehicle),
                        child: Text(
                          'View all ${completedReminders.length} completed items',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],

                // No reminders message
                if (overdueReminders.isEmpty &&
                    upcomingReminders.isEmpty &&
                    completedReminders.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 48,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No maintenance reminders',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // View maintenance button
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToMaintenanceScreen(vehicle),
                      icon: Icon(Icons.build),
                      label: Text('Manage Maintenance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderBadge(int count, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection(
    String title,
    List<MaintenanceReminder> reminders,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                title == 'Overdue'
                    ? Icons.warning
                    : title == 'Completed'
                    ? Icons.check_circle
                    : Icons.schedule,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${reminders.length})',
                style: TextStyle(color: color.withAlpha(200), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...reminders.map((reminder) => _buildReminderItem(reminder, color)),
      ],
    );
  }

  Widget _buildReminderItem(MaintenanceReminder reminder, Color color) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final dueDate = dateFormat.format(reminder.dueDate);
    final bool isCompleted = reminder.isCompleted;
    final completedDate =
        reminder.completedDate != null
            ? dateFormat.format(reminder.completedDate!)
            : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getMaintenanceIcon(reminder.type),
              color: color,
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
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCompleted
                      ? '${reminder.type.name} • Completed: $completedDate'
                      : '${reminder.type.name} • Due: $dueDate',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (reminder.notes.isNotEmpty && isCompleted) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Notes: ${reminder.notes}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isCompleted) ...[
            IconButton(
              icon: Icon(Icons.check_circle_outline, color: Colors.green),
              onPressed: () => _markReminderComplete(reminder),
              tooltip: 'Mark as completed',
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: Icon(Icons.navigate_next, color: Colors.amber),
            onPressed:
                () => _navigateToMaintenanceScreen(
                  _vehicles.firstWhere(
                    (v) =>
                        v.maintenanceReminders.any((r) => r.id == reminder.id),
                  ),
                ),
            tooltip: 'View details',
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _markReminderComplete(MaintenanceReminder reminder) async {
    // Find the vehicle that has this reminder
    final vehicle = _vehicles.firstWhere(
      (v) => v.maintenanceReminders.any((r) => r.id == reminder.id),
      orElse: () => throw Exception('Vehicle not found for reminder'),
    );

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
          vehicle.id,
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
        setState(() {
          _isLoading = false;
        });

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
