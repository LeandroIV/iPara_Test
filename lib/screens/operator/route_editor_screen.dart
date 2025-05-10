import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/route_model.dart';
import '../../services/route_service.dart';
import 'dart:math' as math;

/// Screen for creating or editing a route
class RouteEditorScreen extends StatefulWidget {
  final PUVRoute? route;

  const RouteEditorScreen({super.key, this.route});

  @override
  State<RouteEditorScreen> createState() => _RouteEditorScreenState();
}

class _RouteEditorScreenState extends State<RouteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final RouteService _routeService = RouteService();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _routeCodeController = TextEditingController();
  final _startPointController = TextEditingController();
  final _endPointController = TextEditingController();
  final _estimatedTimeController = TextEditingController();
  final _farePriceController = TextEditingController();
  
  String _selectedPuvType = 'Jeepney';
  Color _selectedColor = Colors.amber;
  List<LatLng> _waypoints = [];
  
  bool _isLoading = false;
  bool _isEditing = false;
  
  // Google Maps controller
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
  // List of available PUV types
  final List<String> _puvTypes = ['Jeepney', 'Bus', 'Multicab', 'Motorela'];
  
  // List of available colors
  final List<Color> _availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.amber,
    Colors.purple,
    Colors.teal,
    Colors.orange,
    Colors.pink,
  ];
  
  // Default map center (CDO, Philippines)
  static const LatLng _defaultCenter = LatLng(8.4542, 124.6319);

  @override
  void initState() {
    super.initState();
    _isEditing = widget.route != null;
    
    if (_isEditing) {
      // Fill form with existing route data
      _nameController.text = widget.route!.name;
      _descriptionController.text = widget.route!.description;
      _routeCodeController.text = widget.route!.routeCode;
      _startPointController.text = widget.route!.startPointName;
      _endPointController.text = widget.route!.endPointName;
      _estimatedTimeController.text = widget.route!.estimatedTravelTime.toString();
      _farePriceController.text = widget.route!.farePrice.toString();
      _selectedPuvType = widget.route!.puvType;
      _selectedColor = Color(widget.route!.colorValue);
      _waypoints = List.from(widget.route!.waypoints);
      
      // Update map markers and polyline
      _updateMapVisualization();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _routeCodeController.dispose();
    _startPointController.dispose();
    _endPointController.dispose();
    _estimatedTimeController.dispose();
    _farePriceController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // Update markers and polyline on the map
  void _updateMapVisualization() {
    setState(() {
      // Clear existing markers and polylines
      _markers.clear();
      _polylines.clear();
      
      // Add markers for each waypoint
      for (int i = 0; i < _waypoints.length; i++) {
        final waypoint = _waypoints[i];
        _markers.add(
          Marker(
            markerId: MarkerId('waypoint_$i'),
            position: waypoint,
            infoWindow: InfoWindow(
              title: i == 0 
                  ? 'Start: ${_startPointController.text}' 
                  : i == _waypoints.length - 1 
                      ? 'End: ${_endPointController.text}' 
                      : 'Waypoint ${i + 1}',
            ),
            draggable: true,
            onDragEnd: (newPosition) {
              setState(() {
                _waypoints[i] = newPosition;
                _updateMapVisualization();
              });
            },
          ),
        );
      }
      
      // Add polyline if there are at least 2 waypoints
      if (_waypoints.length >= 2) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: _waypoints,
            color: _selectedColor,
            width: 5,
          ),
        );
      }
    });
    
    // Move camera to show the route
    if (_waypoints.isNotEmpty && _mapController != null) {
      _fitMapToWaypoints();
    }
  }

  // Fit map to show all waypoints
  void _fitMapToWaypoints() {
    if (_waypoints.isEmpty || _mapController == null) return;
    
    // Find the bounds of all waypoints
    double minLat = _waypoints.first.latitude;
    double maxLat = _waypoints.first.latitude;
    double minLng = _waypoints.first.longitude;
    double maxLng = _waypoints.first.longitude;
    
    for (final point in _waypoints) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    
    // Create a LatLngBounds object
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    
    // Move camera to show all waypoints with padding
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50.0),
    );
  }

  // Add a waypoint at the tapped location
  void _addWaypoint(LatLng position) {
    setState(() {
      _waypoints.add(position);
      _updateMapVisualization();
    });
  }

  // Remove a waypoint
  void _removeWaypoint(int index) {
    setState(() {
      _waypoints.removeAt(index);
      _updateMapVisualization();
    });
  }

  // Move a waypoint up in the list
  void _moveWaypointUp(int index) {
    if (index <= 0) return;
    
    setState(() {
      final waypoint = _waypoints.removeAt(index);
      _waypoints.insert(index - 1, waypoint);
      _updateMapVisualization();
    });
  }

  // Move a waypoint down in the list
  void _moveWaypointDown(int index) {
    if (index >= _waypoints.length - 1) return;
    
    setState(() {
      final waypoint = _waypoints.removeAt(index);
      _waypoints.insert(index + 1, waypoint);
      _updateMapVisualization();
    });
  }

  // Save the route to Firestore
  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_waypoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 2 waypoints for the route'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Create route object
      final route = PUVRoute(
        id: _isEditing ? widget.route!.id : '',
        name: _nameController.text,
        description: _descriptionController.text,
        puvType: _selectedPuvType,
        routeCode: _routeCodeController.text,
        waypoints: _waypoints,
        startPointName: _startPointController.text,
        endPointName: _endPointController.text,
        estimatedTravelTime: int.parse(_estimatedTimeController.text),
        farePrice: double.parse(_farePriceController.text),
        colorValue: _selectedColor.value,
        isActive: true,
      );
      
      if (_isEditing) {
        // Update existing route
        await FirebaseFirestore.instance
            .collection('routes')
            .doc(route.id)
            .update(route.toFirestore());
      } else {
        // Create new route
        await FirebaseFirestore.instance
            .collection('routes')
            .add(route.toFirestore());
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Route updated successfully' : 'Route created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving route: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving route: $e'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Route' : 'Create Route'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveRoute,
            tooltip: 'Save Route',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Map for selecting waypoints
          Expanded(
            flex: 1,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _waypoints.isNotEmpty ? _waypoints.first : _defaultCenter,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_waypoints.isNotEmpty) {
                      _fitMapToWaypoints();
                    }
                  },
                  markers: _markers,
                  polylines: _polylines,
                  onTap: _addWaypoint,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Tap on the map to add waypoints',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Form fields
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route details section
                  const Text(
                    'Route Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Route name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Route Name',
                      hintText: 'e.g., R2 - Carmen to Divisoria',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a route name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Route code
                  TextFormField(
                    controller: _routeCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Route Code',
                      hintText: 'e.g., R2',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a route code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // PUV type dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedPuvType,
                    decoration: const InputDecoration(
                      labelText: 'PUV Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _puvTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPuvType = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a PUV type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Route color
                  Row(
                    children: [
                      const Text('Route Color:'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _availableColors.map((color) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedColor = color;
                                    _updateMapVisualization();
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _selectedColor == color
                                          ? Colors.black
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Start and end points
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _startPointController,
                          decoration: const InputDecoration(
                            labelText: 'Start Point',
                            hintText: 'e.g., Carmen',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _endPointController,
                          decoration: const InputDecoration(
                            labelText: 'End Point',
                            hintText: 'e.g., Divisoria',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Travel time and fare
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _estimatedTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Est. Travel Time (mins)',
                            hintText: 'e.g., 45',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Enter a number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _farePriceController,
                          decoration: const InputDecoration(
                            labelText: 'Fare Price (₱)',
                            hintText: 'e.g., 15.00',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Enter a number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'e.g., Route from Carmen to Divisoria via Corrales Avenue',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  
                  // Waypoints list
                  const Text(
                    'Waypoints',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  if (_waypoints.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No waypoints added yet. Tap on the map to add waypoints.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _waypoints.length,
                      itemBuilder: (context, index) {
                        final waypoint = _waypoints[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              index == 0 
                                  ? 'Start: ${_startPointController.text}' 
                                  : index == _waypoints.length - 1 
                                      ? 'End: ${_endPointController.text}' 
                                      : 'Waypoint ${index + 1}',
                            ),
                            subtitle: Text(
                              'Lat: ${waypoint.latitude.toStringAsFixed(6)}, '
                              'Lng: ${waypoint.longitude.toStringAsFixed(6)}',
                            ),
                            leading: CircleAvatar(
                              backgroundColor: _selectedColor,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_upward),
                                  onPressed: index > 0 ? () => _moveWaypointUp(index) : null,
                                  tooltip: 'Move Up',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_downward),
                                  onPressed: index < _waypoints.length - 1 
                                      ? () => _moveWaypointDown(index) 
                                      : null,
                                  tooltip: 'Move Down',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _removeWaypoint(index),
                                  color: Colors.red,
                                  tooltip: 'Remove',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
