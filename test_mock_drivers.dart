import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ipara/models/driver_location_model.dart';

void main() {
  runApp(const TestMockDriversApp());
}

class TestMockDriversApp extends StatelessWidget {
  const TestMockDriversApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Mock Drivers',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const TestMockDriversScreen(),
    );
  }
}

class TestMockDriversScreen extends StatefulWidget {
  const TestMockDriversScreen({Key? key}) : super(key: key);

  @override
  State<TestMockDriversScreen> createState() => _TestMockDriversScreenState();
}

class _TestMockDriversScreenState extends State<TestMockDriversScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DriverLocation> _busDrivers = [];
  List<DriverLocation> _multicabDrivers = [];
  List<DriverLocation> _motorelaDrivers = [];
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
      // Load Bus drivers
      final busSnapshot = await _firestore
          .collection('driver_locations')
          .where('puvType', isEqualTo: 'Bus')
          .where('isMockData', isEqualTo: true)
          .get();
      
      // Load Multicab drivers
      final multicabSnapshot = await _firestore
          .collection('driver_locations')
          .where('puvType', isEqualTo: 'Multicab')
          .where('isMockData', isEqualTo: true)
          .get();
      
      // Load Motorela drivers
      final motorelaSnapshot = await _firestore
          .collection('driver_locations')
          .where('puvType', isEqualTo: 'Motorela')
          .where('isMockData', isEqualTo: true)
          .get();

      setState(() {
        _busDrivers = busSnapshot.docs
            .map((doc) => DriverLocation.fromFirestore(doc))
            .toList();
        
        _multicabDrivers = multicabSnapshot.docs
            .map((doc) => DriverLocation.fromFirestore(doc))
            .toList();
        
        _motorelaDrivers = motorelaSnapshot.docs
            .map((doc) => DriverLocation.fromFirestore(doc))
            .toList();
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading mock drivers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Mock Drivers'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDriverTypeSection('Bus Drivers', _busDrivers),
                  const Divider(height: 32),
                  _buildDriverTypeSection('Multicab Drivers', _multicabDrivers),
                  const Divider(height: 32),
                  _buildDriverTypeSection('Motorela Drivers', _motorelaDrivers),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadMockDrivers,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildDriverTypeSection(String title, List<DriverLocation> drivers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${drivers.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (drivers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No drivers found'),
          )
        else
          ...drivers.map((driver) => _buildDriverCard(driver)).toList(),
      ],
    );
  }

  Widget _buildDriverCard(DriverLocation driver) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver: ${driver.driverName ?? 'Unknown'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Plate: ${driver.plateNumber ?? 'Unknown'}'),
            Text('Route: ${driver.routeCode ?? driver.routeId ?? 'Unknown'}'),
            Text('Location: ${driver.location.latitude}, ${driver.location.longitude}'),
            Text('Heading: ${driver.heading}°'),
          ],
        ),
      ),
    );
  }
}
