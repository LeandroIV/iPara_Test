import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/driver_location_model.dart';

class DebugPUVScreen extends StatefulWidget {
  const DebugPUVScreen({Key? key}) : super(key: key);

  @override
  State<DebugPUVScreen> createState() => _DebugPUVScreenState();
}

class _DebugPUVScreenState extends State<DebugPUVScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DriverLocation> _drivers = [];
  bool _isLoading = true;
  String _selectedPuvType = 'All';

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
      // Create query based on selected PUV type
      Query query = _firestore.collection('driver_locations');

      // Filter for mock data
      query = query.where('isMockData', isEqualTo: true);

      if (_selectedPuvType != 'All') {
        query = query.where('puvType', isEqualTo: _selectedPuvType);
      }

      // Get drivers
      final snapshot = await query.get();

      debugPrint('Query returned ${snapshot.docs.length} documents');

      // Print raw data for debugging
      for (var doc in snapshot.docs) {
        debugPrint('Document ID: ${doc.id}');
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('  PUV Type: ${data['puvType']}');
        debugPrint('  isMockData: ${data['isMockData']}');
        debugPrint('  Route ID: ${data['routeId']}');
      }

      setState(() {
        _drivers =
            snapshot.docs
                .map((doc) => DriverLocation.fromFirestore(doc))
                .toList();
        _isLoading = false;
      });

      // Print driver information
      _printDriverInfo();
    } catch (e) {
      debugPrint('Error loading drivers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _printDriverInfo() {
    debugPrint('Found ${_drivers.length} drivers:');

    // Count by PUV type
    final busCount =
        _drivers.where((d) => d.puvType.toLowerCase() == 'bus').length;
    final jeepneyCount =
        _drivers.where((d) => d.puvType.toLowerCase() == 'jeepney').length;
    final multicabCount =
        _drivers.where((d) => d.puvType.toLowerCase() == 'multicab').length;
    final motorelaCount =
        _drivers.where((d) => d.puvType.toLowerCase() == 'motorela').length;

    debugPrint('Bus: $busCount');
    debugPrint('Jeepney: $jeepneyCount');
    debugPrint('Multicab: $multicabCount');
    debugPrint('Motorela: $motorelaCount');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug PUV Types'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDrivers),
        ],
      ),
      body: Column(
        children: [
          // PUV type selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('PUV Type:'),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedPuvType,
                  onChanged: (value) {
                    setState(() {
                      _selectedPuvType = value!;
                    });
                    _loadDrivers();
                  },
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Bus', child: Text('Bus')),
                    DropdownMenuItem(value: 'Jeepney', child: Text('Jeepney')),
                    DropdownMenuItem(
                      value: 'Multicab',
                      child: Text('Multicab'),
                    ),
                    DropdownMenuItem(
                      value: 'Motorela',
                      child: Text('Motorela'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Driver count summary
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Drivers: ${_drivers.length}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _buildDriverTypeCount(
                  'Bus',
                  _drivers
                      .where((d) => d.puvType.toLowerCase() == 'bus')
                      .length,
                ),
                _buildDriverTypeCount(
                  'Jeepney',
                  _drivers
                      .where((d) => d.puvType.toLowerCase() == 'jeepney')
                      .length,
                ),
                _buildDriverTypeCount(
                  'Multicab',
                  _drivers
                      .where((d) => d.puvType.toLowerCase() == 'multicab')
                      .length,
                ),
                _buildDriverTypeCount(
                  'Motorela',
                  _drivers
                      .where((d) => d.puvType.toLowerCase() == 'motorela')
                      .length,
                ),
              ],
            ),
          ),

          // Driver list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _drivers.isEmpty
                    ? const Center(child: Text('No drivers found'))
                    : ListView.builder(
                      itemCount: _drivers.length,
                      itemBuilder: (context, index) {
                        final driver = _drivers[index];
                        return _buildDriverCard(driver);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverTypeCount(String type, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '$type: $count',
        style: TextStyle(
          color: _getColorForPuvType(type),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDriverCard(DriverLocation driver) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForPuvType(driver.puvType),
                  color: _getColorForPuvType(driver.puvType),
                ),
                const SizedBox(width: 8),
                Text(
                  '${driver.puvType}: ${driver.plateNumber ?? 'Unknown'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Driver: ${driver.driverName ?? 'Unknown'}'),
            Text('Route: ${driver.routeId ?? 'Unknown'}'),
            Text(
              'Location: ${driver.location.latitude}, ${driver.location.longitude}',
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForPuvType(String type) {
    switch (type.toLowerCase()) {
      case 'bus':
        return Colors.blue;
      case 'jeepney':
        return Colors.amber;
      case 'multicab':
        return Colors.green;
      case 'motorela':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForPuvType(String type) {
    switch (type.toLowerCase()) {
      case 'bus':
        return Icons.directions_bus;
      case 'jeepney':
      case 'multicab':
        return Icons.airport_shuttle;
      case 'motorela':
        return Icons.motorcycle;
      default:
        return Icons.directions_car;
    }
  }
}
