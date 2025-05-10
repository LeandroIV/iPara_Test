import 'package:flutter/material.dart';
import '../../models/emergency_contact_model.dart';
import '../../services/emergency_service.dart';
import 'emergency_contacts_screen.dart';
import 'emergency_history_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final EmergencyService _emergencyService = EmergencyService();
  bool _isLoading = false;
  bool _isEmergencyActive = false;
  List<EmergencyContact> _contacts = [];
  LatLng? _currentLocation;
  bool _callPolice = false;
  bool _notifyContacts = true;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final contacts = await _emergencyService.getEmergencyContacts();
      setState(() {
        _contacts = contacts;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading emergency contacts: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _triggerEmergencyAlert() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get your location. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirm before triggering
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Emergency Alert'),
        content: const Text(
          'Are you sure you want to trigger an emergency alert? '
          'This will notify your emergency contacts and/or call emergency services.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Trigger Alert'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final alertId = await _emergencyService.createEmergencyAlert(
        location: _currentLocation!,
        notes: _notesController.text.trim(),
        notifyContacts: _notifyContacts,
        callPolice: _callPolice,
      );

      if (alertId != null) {
        setState(() {
          _isEmergencyActive = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency alert triggered successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to trigger emergency alert'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error triggering emergency alert: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToContactsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmergencyContactsScreen(),
      ),
    );
    
    // Reload contacts when returning
    _loadContacts();
  }

  void _navigateToHistoryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmergencyHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _navigateToHistoryScreen,
            tooltip: 'Alert History',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emergency button
                  Card(
                    elevation: 4,
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Emergency Alert',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tap the button below to trigger an emergency alert. '
                            'This will notify your emergency contacts and/or call emergency services.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: _isEmergencyActive ? null : _triggerEmergencyAlert,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isEmergencyActive ? Colors.grey : Colors.red,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 60,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isEmergencyActive
                                ? 'Emergency alert is active'
                                : 'Tap to trigger emergency alert',
                            style: TextStyle(
                              color: _isEmergencyActive ? Colors.grey : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Emergency options
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alert Options',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Notify Emergency Contacts'),
                            subtitle: Text(
                              _contacts.isEmpty
                                  ? 'No contacts added yet'
                                  : '${_contacts.length} contacts will be notified',
                            ),
                            value: _notifyContacts,
                            onChanged: (value) {
                              setState(() {
                                _notifyContacts = value;
                              });
                            },
                            activeColor: Colors.red,
                          ),
                          SwitchListTile(
                            title: const Text('Call Emergency Services (911)'),
                            subtitle: const Text(
                              'Automatically call police when alert is triggered',
                            ),
                            value: _callPolice,
                            onChanged: (value) {
                              setState(() {
                                _callPolice = value;
                              });
                            },
                            activeColor: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Emergency Notes (Optional)',
                              hintText: 'Add any details about your emergency',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Emergency contacts section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Emergency Contacts',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.edit),
                                label: const Text('Manage'),
                                onPressed: _navigateToContactsScreen,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_contacts.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'No emergency contacts added yet',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _contacts.length > 3 ? 3 : _contacts.length,
                              itemBuilder: (context, index) {
                                final contact = _contacts[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.red.shade100,
                                    child: const Icon(Icons.person, color: Colors.red),
                                  ),
                                  title: Text(contact.name),
                                  subtitle: Text(contact.phoneNumber),
                                  trailing: Text(contact.relationship),
                                );
                              },
                            ),
                          if (_contacts.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Center(
                                child: TextButton(
                                  onPressed: _navigateToContactsScreen,
                                  child: Text(
                                    'View all ${_contacts.length} contacts',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
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
}
