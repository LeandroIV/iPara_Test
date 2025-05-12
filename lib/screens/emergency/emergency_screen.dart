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
  bool _isSyncingContacts = false;
  bool _isEmergencyActive = false;
  List<EmergencyContact> _contacts = [];
  List<EmergencyContact> _familyContacts = [];
  List<EmergencyContact> _otherContacts = [];
  LatLng? _currentLocation;
  bool _callPolice = false;
  bool _notifyContacts = true;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _getCurrentLocation();
    // Don't automatically sync family contacts on every screen load
    // to prevent duplicates
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

      // Separate family contacts from other contacts
      final familyContacts =
          contacts.where((c) => c.relationship == 'Family').toList();
      final otherContacts =
          contacts.where((c) => c.relationship != 'Family').toList();

      if (mounted) {
        setState(() {
          _contacts = contacts;
          _familyContacts = familyContacts;
          _otherContacts = otherContacts;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading emergency contacts: $e')),
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

  Future<void> _syncFamilyContacts() async {
    setState(() {
      _isSyncingContacts = true;
    });

    try {
      final added = await _emergencyService.syncFamilyMembersAsContacts();

      if (!mounted) return;

      // Reload contacts if new family members were added
      await _loadContacts();

      if (!mounted) return;

      if (added) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Family members added as emergency contacts'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Family members are already synced as contacts'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error syncing family contacts: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncingContacts = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
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
      builder:
          (context) => AlertDialog(
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

      if (!mounted) return;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error triggering emergency alert: $e')),
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

  void _navigateToContactsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()),
    );

    // Reload contacts when returning
    _loadContacts();
  }

  void _navigateToHistoryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmergencyHistoryScreen()),
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emergency button
                    Card(
                      elevation: 6,
                      color: Colors.red.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Emergency Alert',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Tap the button below to trigger an emergency alert. '
                              'This will notify your emergency contacts and/or call emergency services.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap:
                                  _isEmergencyActive
                                      ? null
                                      : _triggerEmergencyAlert,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      _isEmergencyActive
                                          ? Colors.grey
                                          : Colors.red,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withValues(
                                        red: 255,
                                        green: 0,
                                        blue: 0,
                                        alpha: 128,
                                      ),
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
                                color:
                                    _isEmergencyActive
                                        ? Colors.grey.shade800
                                        : Colors.red.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Alert Options',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Notify contacts option
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: SwitchListTile(
                                title: Row(
                                  children: [
                                    const Icon(
                                      Icons.notifications_active,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Flexible(
                                      child: Text(
                                        'Notify Emergency Contacts',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  _contacts.isEmpty
                                      ? 'No contacts added yet'
                                      : '${_contacts.length} contacts will be notified',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                value: _notifyContacts,
                                onChanged: (value) {
                                  setState(() {
                                    _notifyContacts = value;
                                  });
                                },
                                activeColor: Colors.red,
                                activeTrackColor: Colors.red.shade200,
                                inactiveTrackColor: Colors.grey.shade300,
                                inactiveThumbColor: Colors.grey.shade100,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Call emergency services option
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: SwitchListTile(
                                title: Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_in_talk,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Flexible(
                                      child: Text(
                                        'Call Emergency Services (911)',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: const Text(
                                  'Automatically call police when alert is triggered',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: TextStyle(color: Colors.black87),
                                ),
                                value: _callPolice,
                                onChanged: (value) {
                                  setState(() {
                                    _callPolice = value;
                                  });
                                },
                                activeColor: Colors.red,
                                activeTrackColor: Colors.red.shade200,
                                inactiveTrackColor: Colors.grey.shade300,
                                inactiveThumbColor: Colors.grey.shade100,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Emergency notes field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: TextField(
                                controller: _notesController,
                                decoration: InputDecoration(
                                  labelText: 'Emergency Notes (Optional)',
                                  labelStyle: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  hintText:
                                      'Add any details about your emergency',
                                  hintStyle: TextStyle(
                                    color: Colors.red.shade300,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(8),
                                ),
                                style: const TextStyle(color: Colors.black87),
                                maxLines: 3,
                              ),
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Family contacts section
                                  if (_familyContacts.isNotEmpty) ...[
                                    const Padding(
                                      padding: EdgeInsets.only(
                                        top: 8,
                                        bottom: 4,
                                      ),
                                      child: Text(
                                        'Family Members',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: _familyContacts.length,
                                      itemBuilder: (context, index) {
                                        final contact = _familyContacts[index];
                                        return ListTile(
                                          dense: true,
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                Colors.red.shade100,
                                            child: const Icon(
                                              Icons.family_restroom,
                                              color: Colors.red,
                                            ),
                                          ),
                                          title: Text(contact.name),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Phone: ${contact.phoneNumber}',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              if (contact.email.isNotEmpty)
                                                Text(
                                                  'Email: ${contact.email}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],

                                  // Other contacts section
                                  if (_otherContacts.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 16,
                                        bottom: 4,
                                      ),
                                      child: Text(
                                        'Other Contacts',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount:
                                          _otherContacts.length > 2
                                              ? 2
                                              : _otherContacts.length,
                                      itemBuilder: (context, index) {
                                        final contact = _otherContacts[index];
                                        return ListTile(
                                          dense: true,
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                Colors.grey.shade200,
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          title: Text(contact.name),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Phone: ${contact.phoneNumber}',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              if (contact.email.isNotEmpty)
                                                Text(
                                                  'Email: ${contact.email}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          trailing: Text(
                                            contact.relationship,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),

                            // View all contacts button
                            if (_contacts.length > 5)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Center(
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.people, size: 16),
                                    onPressed: _navigateToContactsScreen,
                                    label: Text(
                                      'View all ${_contacts.length} contacts',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ),

                            // Sync family contacts button
                            if (_familyContacts.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Center(
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.sync, size: 16),
                                    onPressed: _syncFamilyContacts,
                                    label: const Text(
                                      'Sync family members as contacts',
                                      style: TextStyle(color: Colors.red),
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
