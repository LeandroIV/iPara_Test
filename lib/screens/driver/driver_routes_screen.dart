import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/route_model.dart';
import '../../services/route_service.dart';

class DriverRoutesScreen extends StatefulWidget {
  const DriverRoutesScreen({super.key});

  @override
  State<DriverRoutesScreen> createState() => _DriverRoutesScreenState();
}

class _DriverRoutesScreenState extends State<DriverRoutesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RouteService _routeService = RouteService();
  
  bool _isLoading = true;
  List<PUVRoute> _assignedRoutes = [];
  List<PUVRoute> _availableRoutes = [];
  PUVRoute? _selectedRoute;
  String? _driverId;
  String? _vehicleId;
  String _puvType = 'Jeepney'; // Default PUV type

  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
  }

  Future<void> _loadDriverInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        _driverId = userId;
        
        // Get driver's vehicle information
        final driverDoc = await _firestore.collection('driver_locations').doc(userId).get();
        
        if (driverDoc.exists) {
          final data = driverDoc.data();
          _vehicleId = data?['vehicleId'];
          _puvType = data?['puvType'] ?? 'Jeepney';
          
          // Get assigned route if any
          final routeId = data?['routeId'];
          if (routeId != null) {
            final routeDoc = await _firestore.collection('routes').doc(routeId).get();
            if (routeDoc.exists) {
              _selectedRoute = PUVRoute.fromFirestore(routeDoc);
            }
          }
        }
        
        // Load all routes
        await _loadRoutes();
      }
    } catch (e) {
      debugPrint('Error loading driver info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRoutes() async {
    try {
      // Load all routes from Firestore
      final allRoutes = await _routeService.getAllRoutes();
      
      // Filter routes by PUV type
      final filteredRoutes = allRoutes.where((route) => 
        route.puvType.toLowerCase() == _puvType.toLowerCase()
      ).toList();
      
      // If no routes found, use mock data
      if (filteredRoutes.isEmpty) {
        final mockRoutes = _routeService.getMockRoutes().where((route) => 
          route.puvType.toLowerCase() == _puvType.toLowerCase()
        ).toList();
        
        setState(() {
          _availableRoutes = mockRoutes;
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _availableRoutes = filteredRoutes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading routes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _assignRoute(PUVRoute route) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Update driver_locations document
        await _firestore.collection('driver_locations').doc(userId).update({
          'routeId': route.id,
          'routeCode': route.routeCode,
        });
        
        // If vehicle exists, update it too
        if (_vehicleId != null) {
          await _firestore.collection('vehicles').doc(_vehicleId).update({
            'routeId': route.id,
          });
        }
        
        setState(() {
          _selectedRoute = route;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are now assigned to route ${route.routeCode}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error assigning route: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error assigning route: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _unassignRoute() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Update driver_locations document
        await _firestore.collection('driver_locations').doc(userId).update({
          'routeId': null,
          'routeCode': null,
        });
        
        // If vehicle exists, update it too
        if (_vehicleId != null) {
          await _firestore.collection('vehicles').doc(_vehicleId).update({
            'routeId': null,
          });
        }
        
        setState(() {
          _selectedRoute = null;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have been unassigned from the route'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error unassigning route: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unassigning route: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Routes'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.blue,
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : Column(
              children: [
                // Current route section
                if (_selectedRoute != null)
                  _buildCurrentRouteSection()
                else
                  _buildNoRouteSection(),
                
                // Available routes section
                Expanded(
                  child: _buildAvailableRoutesSection(),
                ),
              ],
            ),
    );
  }

  Widget _buildCurrentRouteSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Color(_selectedRoute!.colorValue),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _selectedRoute!.routeCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Current Route',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                onPressed: () => _showUnassignConfirmation(),
                tooltip: 'Unassign from route',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _selectedRoute!.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.circle, color: Colors.green, size: 12),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedRoute!.startPointName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 5),
            child: SizedBox(
              height: 20,
              child: VerticalDivider(
                color: Colors.grey,
                thickness: 1,
                width: 20,
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 12),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedRoute!.endPointName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.blue, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '~${_selectedRoute!.estimatedTravelTime} min',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                '₱${_selectedRoute!.farePrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoRouteSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.route_outlined, size: 48, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'No Route Assigned',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a route from the list below to start driving',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableRoutesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Available Routes',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _availableRoutes.isEmpty
              ? Center(
                  child: Text(
                    'No available routes for $_puvType',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _availableRoutes.length,
                  itemBuilder: (context, index) {
                    final route = _availableRoutes[index];
                    final isSelected = _selectedRoute?.id == route.id;
                    return _buildRouteCard(route, isSelected);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRouteCard(PUVRoute route, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Colors.blue, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isSelected ? null : () => _showAssignConfirmation(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(route.colorValue),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      route.routeCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    route.puvType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Current',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                route.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.circle, color: Colors.green, size: 12),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      route.startPointName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 5),
                child: SizedBox(
                  height: 20,
                  child: VerticalDivider(
                    color: Colors.grey,
                    thickness: 1,
                    width: 20,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 12),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      route.endPointName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.blue, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '~${route.estimatedTravelTime} min',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₱${route.farePrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignConfirmation(PUVRoute route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Assign Route',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Do you want to be assigned to route ${route.routeCode} (${route.name})?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _assignRoute(route);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showUnassignConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Unassign Route',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Do you want to unassign from route ${_selectedRoute!.routeCode}?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _unassignRoute();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Unassign'),
          ),
        ],
      ),
    );
  }
}
