// This is a simple script to test if the icons for buses, multicabs, and motorelas are loading correctly
// To use this script, add it to your project and run it with:
// flutter run -t test_icons.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TestIconsApp());
}

class TestIconsApp extends StatelessWidget {
  const TestIconsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test PUV Icons',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TestIconsScreen(),
    );
  }
}

class TestIconsScreen extends StatefulWidget {
  const TestIconsScreen({super.key});

  @override
  State<TestIconsScreen> createState() => _TestIconsScreenState();
}

class _TestIconsScreenState extends State<TestIconsScreen> {
  Set<Marker> _markers = {};
  bool _isLoading = true;
  GoogleMapController? _mapController;

  // Center on CDO, Philippines
  final LatLng _initialPosition = const LatLng(8.4542, 124.6319);

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create test markers for each PUV type
      final Set<Marker> markers = {};

      // Create test locations around the center
      final locations = {
        'Bus': const LatLng(8.4542, 124.6319),
        'Jeepney': const LatLng(8.4542 + 0.005, 124.6319),
        'Multicab': const LatLng(8.4542, 124.6319 + 0.005),
        'Motorela': const LatLng(8.4542 - 0.005, 124.6319),
      };

      // Create markers for each PUV type
      for (final entry in locations.entries) {
        final puvType = entry.key;
        final location = entry.value;

        // Get the appropriate icon
        final icon = await _getDriverIcon(puvType);

        // Create the marker
        final marker = Marker(
          markerId: MarkerId('test_$puvType'),
          position: location,
          icon: icon,
          infoWindow: InfoWindow(title: puvType),
          rotation: 0, // Fixed rotation (no rotation)
          flat: true, // Make the marker flat on the map
          anchor: const Offset(0.5, 0.5), // Center the marker
        );

        markers.add(marker);
        debugPrint('Created marker for $puvType');
      }

      setState(() {
        _markers = markers;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading icons: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

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
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        );
    }

    try {
      // Debug print to check which icon is being loaded
      debugPrint('Loading icon for PUV type: $puvType from path: $iconPath');

      // Load the custom icon with larger size (86x86)
      return await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(86, 86)),
        iconPath,
      );
    } catch (e) {
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
            BitmapDescriptor.hueAzure,
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test PUV Icons'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadIcons),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition,
                    zoom: 14,
                  ),
                  markers: _markers,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  compassEnabled: true,
                  mapToolbarEnabled: false,
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Test Icons',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text('Bus: Blue marker at center'),
                Text('Jeepney: Yellow marker north of center'),
                Text('Multicab: Green marker east of center'),
                Text('Motorela: Red marker south of center'),
                const SizedBox(height: 8),
                Text('All icons should be 86x86 pixels with no rotation'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
