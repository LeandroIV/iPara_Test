import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_driver_screen.dart';

class DriversManagementScreen extends StatefulWidget {
  const DriversManagementScreen({super.key});

  @override
  State<DriversManagementScreen> createState() =>
      _DriversManagementScreenState();
}

class _DriversManagementScreenState extends State<DriversManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _drivers = [];
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Active', 'Inactive'];

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Get all drivers from Firestore
        final querySnapshot =
            await _firestore.collection('driver_locations').get();

        final drivers = await Future.wait(
          querySnapshot.docs.map((doc) async {
            final data = doc.data();

            // Get route name if routeId is available
            String routeName = '';
            if (data['routeId'] != null) {
              try {
                final routeDoc =
                    await _firestore
                        .collection('routes')
                        .doc(data['routeId'])
                        .get();

                if (routeDoc.exists) {
                  routeName = routeDoc.data()?['name'] ?? '';
                } else if (data['routeCode'] != null) {
                  // Fallback to routeCode if route document doesn't exist
                  routeName = data['routeCode'];
                }
              } catch (e) {
                debugPrint('Error fetching route: $e');
              }
            }

            return {
              'id': doc.id,
              'name': data['driverName'] ?? 'Unknown Driver',
              'vehicleId': data['plateNumber'] ?? 'Unknown',
              'route': routeName.isNotEmpty ? routeName : 'No Route Assigned',
              'routeCode': data['routeCode'] ?? '',
              'status': data['isOnline'] == true ? 'Active' : 'Inactive',
              'lastActive': data['lastUpdated'] ?? Timestamp.now(),
              'puvType': data['puvType'] ?? 'Unknown',
              'phoneNumber': data['phoneNumber'] ?? '',
              'email': data['email'] ?? '',
            };
          }).toList(),
        );

        setState(() {
          _drivers = drivers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading drivers: $e');
      setState(() {
        // Use mock data as fallback
        _drivers = _getMockDrivers();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getMockDrivers() {
    // Create some mock driver data
    return [
      {
        'id': '1',
        'name': 'John Doe',
        'vehicleId': 'JPN-123',
        'route': 'R2 - Carmen to Divisoria',
        'routeCode': 'R2',
        'status': 'Active',
        'lastActive': Timestamp.now(),
        'puvType': 'Jeepney',
        'phoneNumber': '+63 912 345 6789',
        'email': 'john.doe@example.com',
      },
      {
        'id': '2',
        'name': 'Jane Smith',
        'vehicleId': 'JPN-456',
        'route': 'R3 - Bulua to Divisoria',
        'routeCode': 'R3',
        'status': 'Active',
        'lastActive': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        'puvType': 'Jeepney',
        'phoneNumber': '+63 923 456 7890',
        'email': 'jane.smith@example.com',
      },
      {
        'id': '3',
        'name': 'Mark Johnson',
        'vehicleId': 'JPN-789',
        'route': 'R4 - Bugo to Lapasan',
        'routeCode': 'R4',
        'status': 'Inactive',
        'lastActive': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
        'puvType': 'Jeepney',
        'phoneNumber': '+63 934 567 8901',
        'email': 'mark.johnson@example.com',
      },
      {
        'id': '4',
        'name': 'Robert Garcia',
        'vehicleId': 'JPN-234',
        'route': 'R7 - Balulang to Divisoria',
        'routeCode': 'R7',
        'status': 'Active',
        'lastActive': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 2)),
        ),
        'puvType': 'Jeepney',
        'phoneNumber': '+63 945 678 9012',
        'email': 'robert.garcia@example.com',
      },
      {
        'id': '5',
        'name': 'Maria Santos',
        'vehicleId': 'JPN-567',
        'route': 'R10 - Canitoan to Cogon',
        'routeCode': 'R10',
        'status': 'Active',
        'lastActive': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        'puvType': 'Jeepney',
        'phoneNumber': '+63 956 789 0123',
        'email': 'maria.santos@example.com',
      },
    ];
  }

  List<Map<String, dynamic>> _getFilteredDrivers() {
    if (_selectedFilter == 'All') {
      return _drivers;
    } else {
      return _drivers
          .where((driver) => driver['status'] == _selectedFilter)
          .toList();
    }
  }

  String _formatLastActive(Timestamp timestamp) {
    final now = DateTime.now();
    final lastActive = timestamp.toDate();
    final difference = now.difference(lastActive);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredDrivers = _getFilteredDrivers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drivers Management'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Driver',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddDriverScreen(),
                ),
              );

              // If a driver was added successfully, refresh the list
              if (result == true) {
                _loadDrivers();
              }
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              )
              : Column(
                children: [
                  // Filter options
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Drivers (${filteredDrivers.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SegmentedButton<String>(
                          segments:
                              _filterOptions
                                  .map(
                                    (filter) => ButtonSegment<String>(
                                      value: filter,
                                      label: Text(filter),
                                    ),
                                  )
                                  .toList(),
                          selected: {_selectedFilter},
                          onSelectionChanged: (Set<String> selection) {
                            setState(() {
                              _selectedFilter = selection.first;
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.resolveWith<Color>((
                                  Set<WidgetState> states,
                                ) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.amber;
                                  }
                                  return Colors.grey[800]!;
                                }),
                            foregroundColor:
                                WidgetStateProperty.resolveWith<Color>((
                                  Set<WidgetState> states,
                                ) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.black;
                                  }
                                  return Colors.grey[400]!;
                                }),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Driver list
                  Expanded(
                    child:
                        filteredDrivers.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_off,
                                    size: 64,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No ${_selectedFilter.toLowerCase()} drivers found',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredDrivers.length,
                              itemBuilder: (context, index) {
                                final driver = filteredDrivers[index];
                                return _buildDriverCard(driver);
                              },
                            ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddDriverScreen()),
          );

          // If a driver was added successfully, refresh the list
          if (result == true) {
            _loadDrivers();
          }
        },
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    final isActive = driver['status'] == 'Active';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDriverDetails(driver),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        isActive
                            ? Colors.green.withAlpha(51) // 0.2 * 255 = 51
                            : Colors.red.withAlpha(51), // 0.2 * 255 = 51
                    radius: 24,
                    child: Icon(
                      Icons.person,
                      color: isActive ? Colors.green : Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          driver['vehicleId'],
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      driver['status'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.route, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      driver['route'],
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey[400], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Last active: ${_formatLastActive(driver['lastActive'])}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDriverDetails(Map<String, dynamic> driver) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          driver['status'] == 'Active'
                              ? Colors.green.withAlpha(51) // 0.2 * 255 = 51
                              : Colors.red.withAlpha(51), // 0.2 * 255 = 51
                      radius: 24,
                      child: Icon(
                        Icons.person,
                        color:
                            driver['status'] == 'Active'
                                ? Colors.green
                                : Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            driver['vehicleId'],
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            driver['status'] == 'Active'
                                ? Colors.green
                                : Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        driver['status'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailItem(Icons.route, 'Route', driver['route']),
                _buildDetailItem(
                  Icons.directions_car,
                  'Vehicle Type',
                  driver['puvType'],
                ),
                _buildDetailItem(Icons.phone, 'Phone', driver['phoneNumber']),
                _buildDetailItem(Icons.email, 'Email', driver['email']),
                _buildDetailItem(
                  Icons.access_time,
                  'Last Active',
                  _formatLastActive(driver['lastActive']),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement call functionality
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement message functionality
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement track functionality
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.location_on),
                      label: const Text('Track'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
