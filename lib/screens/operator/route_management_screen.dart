import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/route_model.dart';
import '../../services/route_service.dart';
import 'route_editor_screen.dart';

/// Screen for operators to manage routes
class RouteManagementScreen extends StatefulWidget {
  const RouteManagementScreen({super.key});

  @override
  State<RouteManagementScreen> createState() => _RouteManagementScreenState();
}

class _RouteManagementScreenState extends State<RouteManagementScreen> {
  final RouteService _routeService = RouteService();
  List<PUVRoute> _routes = [];
  bool _isLoading = true;
  String? _filterPuvType;

  // List of available PUV types
  final List<String> _puvTypes = ['Jeepney', 'Bus', 'Multicab', 'Motorela'];

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  // Load routes from Firestore
  Future<void> _loadRoutes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final routes = await _routeService.getAllRoutes();
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading routes: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading routes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Filter routes based on selected PUV type
  List<PUVRoute> get filteredRoutes {
    if (_filterPuvType == null) {
      return _routes;
    }
    return _routes
        .where((route) => route.puvType == _filterPuvType)
        .toList();
  }

  // Navigate to route editor screen to create a new route
  void _createNewRoute() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RouteEditorScreen(),
      ),
    ).then((_) => _loadRoutes()); // Reload routes when returning
  }

  // Navigate to route editor screen to edit an existing route
  void _editRoute(PUVRoute route) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteEditorScreen(route: route),
      ),
    ).then((_) => _loadRoutes()); // Reload routes when returning
  }

  // Delete a route after confirmation
  Future<void> _deleteRoute(PUVRoute route) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: Text(
          'Are you sure you want to delete the route "${route.name}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // In a real implementation, you would call a method to delete the route
      // For now, we'll just update the isActive flag to false
      await FirebaseFirestore.instance
          .collection('routes')
          .doc(route.id)
          .update({'isActive': false});
      
      // Reload routes
      await _loadRoutes();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting route: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting route: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Management'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
        actions: [
          // Filter dropdown
          DropdownButton<String?>(
            value: _filterPuvType,
            hint: const Text('Filter by type', style: TextStyle(color: Colors.white)),
            dropdownColor: Colors.black87,
            underline: Container(),
            icon: const Icon(Icons.filter_list, color: Colors.amber),
            onChanged: (value) {
              setState(() {
                _filterPuvType = value;
              });
            },
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Types', style: TextStyle(color: Colors.white)),
              ),
              ..._puvTypes.map((type) => DropdownMenuItem<String>(
                    value: type,
                    child: Text(type, style: const TextStyle(color: Colors.white)),
                  )),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredRoutes.isEmpty
              ? _buildEmptyState()
              : _buildRouteList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewRoute,
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.route,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _filterPuvType == null
                ? 'No routes found'
                : 'No $_filterPuvType routes found',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a new route by tapping the + button',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewRoute,
            icon: const Icon(Icons.add),
            label: const Text('Create New Route'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRoutes.length,
      itemBuilder: (context, index) {
        final route = filteredRoutes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              route.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Route Code: ${route.routeCode}'),
                Text('PUV Type: ${route.puvType}'),
                Text('${route.startPointName} → ${route.endPointName}'),
                Text('Fare: ₱${route.farePrice.toStringAsFixed(2)}'),
                Text('Est. Travel Time: ${route.estimatedTravelTime} mins'),
              ],
            ),
            leading: CircleAvatar(
              backgroundColor: Color(route.colorValue),
              child: Text(
                route.routeCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editRoute(route),
                  color: Colors.blue,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteRoute(route),
                  color: Colors.red,
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
