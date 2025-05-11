// This is a simple script to check if the mock drivers are being properly loaded from Firestore
// To use this script, add it to your project and run it with:
// flutter run -t check_mock_drivers.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CheckMockDriversApp());
}

class CheckMockDriversApp extends StatelessWidget {
  const CheckMockDriversApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Check Mock Drivers',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const CheckMockDriversScreen(),
    );
  }
}

class CheckMockDriversScreen extends StatefulWidget {
  const CheckMockDriversScreen({super.key});

  @override
  State<CheckMockDriversScreen> createState() => _CheckMockDriversScreenState();
}

class _CheckMockDriversScreenState extends State<CheckMockDriversScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMockDrivers();
  }

  Future<void> _loadMockDrivers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all mock drivers
      final snapshot = await _firestore
          .collection('driver_locations')
          .where('isMockData', isEqualTo: true)
          .get();
      
      setState(() {
        _drivers = snapshot.docs.map((doc) => doc.data()).toList();
        _isLoading = false;
      });
      
      // Print driver information
      _printDriverInfo();
    } catch (e) {
      debugPrint('Error loading mock drivers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _printDriverInfo() {
    debugPrint('Found ${_drivers.length} mock drivers:');
    
    // Count by PUV type
    final busCount = _drivers.where((d) => d['puvType']?.toLowerCase() == 'bus').length;
    final jeepneyCount = _drivers.where((d) => d['puvType']?.toLowerCase() == 'jeepney').length;
    final multicabCount = _drivers.where((d) => d['puvType']?.toLowerCase() == 'multicab').length;
    final motorelaCount = _drivers.where((d) => d['puvType']?.toLowerCase() == 'motorela').length;
    
    debugPrint('Bus: $busCount');
    debugPrint('Jeepney: $jeepneyCount');
    debugPrint('Multicab: $multicabCount');
    debugPrint('Motorela: $motorelaCount');
    
    // Print details of each driver
    for (final driver in _drivers) {
      debugPrint('-----------------------------------');
      debugPrint('Driver ID: ${driver['userId']}');
      debugPrint('PUV Type: ${driver['puvType']}');
      debugPrint('Plate Number: ${driver['plateNumber']}');
      debugPrint('Driver Name: ${driver['driverName']}');
      
      // Check if location exists
      final location = driver['location'];
      if (location != null && location is GeoPoint) {
        debugPrint('Location: ${location.latitude}, ${location.longitude}');
      } else {
        debugPrint('Location: Not available');
      }
      
      // Check if route information exists
      debugPrint('Route ID: ${driver['routeId']}');
      debugPrint('Route Code: ${driver['routeCode']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Mock Drivers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMockDrivers,
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
                  Text(
                    'Total Drivers: ${_drivers.length}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _buildDriverTypeCount('Bus', _drivers.where((d) => d['puvType']?.toLowerCase() == 'bus').length),
                  _buildDriverTypeCount('Jeepney', _drivers.where((d) => d['puvType']?.toLowerCase() == 'jeepney').length),
                  _buildDriverTypeCount('Multicab', _drivers.where((d) => d['puvType']?.toLowerCase() == 'multicab').length),
                  _buildDriverTypeCount('Motorela', _drivers.where((d) => d['puvType']?.toLowerCase() == 'motorela').length),
                  
                  const SizedBox(height: 16),
                  const Text('Driver Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  ..._drivers.map((driver) => _buildDriverCard(driver)).toList(),
                ],
              ),
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
  
  Widget _buildDriverCard(Map<String, dynamic> driver) {
    final puvType = driver['puvType'] as String? ?? 'Unknown';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForPuvType(puvType),
                  color: _getColorForPuvType(puvType),
                ),
                const SizedBox(width: 8),
                Text(
                  '${driver['puvType'] ?? 'Unknown'}: ${driver['plateNumber'] ?? 'Unknown'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Driver: ${driver['driverName'] ?? 'Unknown'}'),
            Text('Route: ${driver['routeCode'] ?? driver['routeId'] ?? 'Unknown'}'),
            
            // Show location if available
            if (driver['location'] != null && driver['location'] is GeoPoint)
              Text(
                'Location: ${(driver['location'] as GeoPoint).latitude}, ${(driver['location'] as GeoPoint).longitude}',
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
