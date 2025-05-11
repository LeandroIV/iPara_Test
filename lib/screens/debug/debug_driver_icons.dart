import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/driver_location_model.dart';

class DebugDriverIconsScreen extends StatefulWidget {
  const DebugDriverIconsScreen({Key? key}) : super(key: key);

  @override
  State<DebugDriverIconsScreen> createState() => _DebugDriverIconsScreenState();
}

class _DebugDriverIconsScreenState extends State<DebugDriverIconsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _drivers = [];
  bool _isLoading = true;
  String _selectedPuvType = 'All';
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  // Default center at Cagayan de Oro
  final LatLng _center = const LatLng(8.4806, 124.6497);

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
      _markers.clear();
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

      // Convert to list of maps
      final drivers =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {...data, 'id': doc.id};
          }).toList();

      // Print raw data for debugging
      for (var driver in drivers) {
        debugPrint('Document ID: ${driver['id']}');
        debugPrint('  PUV Type: ${driver['puvType']}');
        debugPrint('  Icon Type: ${driver['iconType']}');
        debugPrint('  Is Online: ${driver['isOnline']}');
        debugPrint('  Is Location Visible: ${driver['isLocationVisible']}');

        // Create marker for each driver
        if (driver['location'] != null) {
          final GeoPoint geoPoint = driver['location'] as GeoPoint;
          final LatLng position = LatLng(geoPoint.latitude, geoPoint.longitude);

          // Create marker with custom icon
          final puvType = driver['puvType'] as String? ?? 'unknown';
          final iconType = driver['iconType'] as String? ?? puvType;

          // Get the appropriate icon
          _getDriverIcon(iconType).then((icon) {
            final marker = Marker(
              markerId: MarkerId('driver_${driver['id']}'),
              position: position,
              icon: icon,
              infoWindow: InfoWindow(
                title:
                    '${driver['puvType']} - ${driver['plateNumber'] ?? 'Unknown'}',
                snippet: 'Icon Type: ${driver['iconType'] ?? 'Unknown'}',
              ),
              flat: true, // Make the marker flat on the map
              anchor: const Offset(0.5, 0.5), // Center the marker
            );

            setState(() {
              _markers.add(marker);
            });
          });
        }
      }

      setState(() {
        _drivers = drivers;
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
        _drivers.where((d) => d['puvType']?.toLowerCase() == 'bus').length;
    final jeepneyCount =
        _drivers.where((d) => d['puvType']?.toLowerCase() == 'jeepney').length;
    final multicabCount =
        _drivers.where((d) => d['puvType']?.toLowerCase() == 'multicab').length;
    final motorelaCount =
        _drivers.where((d) => d['puvType']?.toLowerCase() == 'motorela').length;

    debugPrint('Bus: $busCount');
    debugPrint('Jeepney: $jeepneyCount');
    debugPrint('Multicab: $multicabCount');
    debugPrint('Motorela: $motorelaCount');

    // Count by icon type
    final personIcons = _drivers.where((d) => d['iconType'] == 'person').length;
    final carIcons = _drivers.where((d) => d['iconType'] == 'car').length;
    final busIcons = _drivers.where((d) => d['iconType'] == 'bus').length;
    final jeepneyIcons =
        _drivers.where((d) => d['iconType'] == 'jeepney').length;
    final multicabIcons =
        _drivers.where((d) => d['iconType'] == 'multicab').length;
    final motorelaIcons =
        _drivers.where((d) => d['iconType'] == 'motorela').length;

    debugPrint('Icon Types:');
    debugPrint('  person: $personIcons');
    debugPrint('  car: $carIcons');
    debugPrint('  bus: $busIcons');
    debugPrint('  jeepney: $jeepneyIcons');
    debugPrint('  multicab: $multicabIcons');
    debugPrint('  motorela: $motorelaIcons');
  }

  /// Get the appropriate icon for a driver based on PUV type
  Future<BitmapDescriptor> _getDriverIcon(String puvType) async {
    // Use custom PUV icons with highlight for map markers
    String iconPath;
    switch (puvType.toLowerCase()) {
      case 'bus':
        iconPath = 'assets/icons/bus_highlight.png';
        break;
      case 'jeepney':
        iconPath = 'assets/icons/jeepney_highlight.png';
        break;
      case 'multicab':
        iconPath = 'assets/icons/multicab_highlight.png';
        break;
      case 'motorela':
        iconPath = 'assets/icons/motorela_highlight.png';
        break;
      default:
        // Fallback to default marker if no matching icon
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        );
    }

    try {
      // Load the custom icon using the non-deprecated method
      return BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(64, 64)),
        iconPath,
      );
    } catch (e) {
      // Fallback to colored markers if custom icon fails to load
      debugPrint('Error loading PUV icon: $e, using default marker instead');

      // Select the appropriate fallback icon based on PUV type
      switch (puvType.toLowerCase()) {
        case 'bus':
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          );
        case 'jeepney':
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow,
          );
        case 'multicab':
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          );
        case 'motorela':
          return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        default:
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Driver Icons'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDrivers),
        ],
      ),
      body: Column(
        children: [
          // PUV type filter
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedPuvType,
              isExpanded: true,
              hint: const Text('Filter by PUV Type'),
              onChanged: (value) {
                setState(() {
                  _selectedPuvType = value!;
                });
                _loadDrivers();
              },
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All PUV Types')),
                DropdownMenuItem(value: 'Bus', child: Text('Bus')),
                DropdownMenuItem(value: 'Jeepney', child: Text('Jeepney')),
                DropdownMenuItem(value: 'Multicab', child: Text('Multicab')),
                DropdownMenuItem(value: 'Motorela', child: Text('Motorela')),
              ],
            ),
          ),

          // Driver count summary
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Drivers: ${_drivers.length}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bus: ${_drivers.where((d) => d['puvType']?.toLowerCase() == 'bus').length}',
                ),
                Text(
                  'Jeepney: ${_drivers.where((d) => d['puvType']?.toLowerCase() == 'jeepney').length}',
                ),
                Text(
                  'Multicab: ${_drivers.where((d) => d['puvType']?.toLowerCase() == 'multicab').length}',
                ),
                Text(
                  'Motorela: ${_drivers.where((d) => d['puvType']?.toLowerCase() == 'motorela').length}',
                ),
              ],
            ),
          ),

          // Map view
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _center,
                        zoom: 14,
                      ),
                      markers: _markers,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
