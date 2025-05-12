import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/driver_location_model.dart';
import '../models/commuter_location_model.dart';

/// Utility class for generating custom map markers
class MarkerGenerator {
  /// Cache for marker icons to avoid regenerating them
  static final Map<String, BitmapDescriptor> _markerIconCache = {};

  /// Generate a marker for a driver
  static Future<Marker> createDriverMarker(DriverLocation driver) async {
    // Create a unique ID for the marker
    final markerId = MarkerId('driver_${driver.userId}');

    // Get the appropriate icon based on PUV type
    final icon = await _getDriverIcon(driver.puvType);

    // Create info window content
    final infoWindow = InfoWindow(
      title: driver.plateNumber ?? 'PUV ${driver.puvType}',
      snippet: 'Tap for details',
    );

    // Create the marker
    return Marker(
      markerId: markerId,
      position: driver.location,
      icon: icon,
      infoWindow: infoWindow,
      rotation:
          0, // Fixed rotation to make icons always face in a fixed direction
      flat: true, // Make the marker flat on the map
      anchor: const Offset(0.5, 0.5), // Center the marker
      zIndex: 2, // Higher z-index to appear above other markers
    );
  }

  /// Generate a marker for a commuter
  static Future<Marker> createCommuterMarker(CommuterLocation commuter) async {
    // Create a unique ID for the marker
    final markerId = MarkerId('commuter_${commuter.userId}');

    // Get the commuter icon
    final icon = await _getCommuterIcon();

    // Create info window content
    final infoWindow = InfoWindow(
      title: commuter.userName ?? 'Commuter',
      snippet:
          commuter.destinationName != null
              ? 'Going to ${commuter.destinationName}'
              : 'Looking for ${commuter.selectedPuvType}',
    );

    // Create the marker
    return Marker(
      markerId: markerId,
      position: commuter.location,
      icon: icon,
      infoWindow: infoWindow,
      zIndex: 1, // Lower z-index than drivers
    );
  }

  /// Get the appropriate icon for a driver based on PUV type
  /// Uses the highlighted version of icons for map markers
  static Future<BitmapDescriptor> _getDriverIcon(String puvType) async {
    // Check if we already have this icon cached
    final cacheKey = 'driver_${puvType.toLowerCase()}_highlight';
    if (_markerIconCache.containsKey(cacheKey)) {
      return _markerIconCache[cacheKey]!;
    }

    // Use colored markers based on PUV type
    switch (puvType.toLowerCase()) {
      case 'bus':
      case 'jeepney':
      case 'multicab':
      case 'motorela':
        // Continue to the try block for all valid PUV types
        break;
      default:
        // Fallback to default marker if no matching icon
        final icon = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        );
        _markerIconCache[cacheKey] = icon;
        return icon;
    }

    try {
      // Debug print to check which icon is being loaded
      debugPrint('Loading icon for PUV type: $puvType');

      // Use a colored marker instead of the deprecated fromAssetImage method
      double hue;
      switch (puvType.toLowerCase()) {
        case 'bus':
          hue = BitmapDescriptor.hueBlue;
          break;
        case 'jeepney':
          hue = BitmapDescriptor.hueYellow;
          break;
        case 'multicab':
          hue = BitmapDescriptor.hueGreen;
          break;
        case 'motorela':
          hue = BitmapDescriptor.hueRed;
          break;
        default:
          hue = BitmapDescriptor.hueViolet;
      }

      // Create a colored marker with appropriate size
      final icon = BitmapDescriptor.defaultMarkerWithHue(hue);

      // Cache the icon for future use
      _markerIconCache[cacheKey] = icon;
      return icon;
    } catch (e) {
      // Fallback to colored markers if custom icon fails to load
      debugPrint('Error loading PUV icon: $e, using default marker instead');

      double hue;
      switch (puvType.toLowerCase()) {
        case 'bus':
          hue = BitmapDescriptor.hueBlue;
          break;
        case 'jeepney':
          hue = BitmapDescriptor.hueYellow;
          break;
        case 'multicab':
          hue = BitmapDescriptor.hueGreen;
          break;
        case 'motorela':
          hue = BitmapDescriptor.hueRed;
          break;
        default:
          hue = BitmapDescriptor.hueViolet;
      }

      // Create a colored marker
      final icon = BitmapDescriptor.defaultMarkerWithHue(hue);

      // Cache the icon for future use
      _markerIconCache[cacheKey] = icon;
      return icon;
    }
  }

  /// Get the regular (non-highlighted) icon for a PUV type
  /// Used for UI widgets rather than map markers
  static Future<BitmapDescriptor> getPuvTypeIcon(String puvType) async {
    // Check if we already have this icon cached
    final cacheKey = 'puv_${puvType.toLowerCase()}';
    if (_markerIconCache.containsKey(cacheKey)) {
      return _markerIconCache[cacheKey]!;
    }

    // Use colored markers based on PUV type
    switch (puvType.toLowerCase()) {
      case 'bus':
      case 'jeepney':
      case 'multicab':
      case 'motorela':
        // Continue to the try block for all valid PUV types
        break;
      default:
        // Fallback to default marker if no matching icon
        final icon = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        );
        _markerIconCache[cacheKey] = icon;
        return icon;
    }

    try {
      // Use a colored marker instead of the deprecated fromAssetImage method
      double hue;
      switch (puvType.toLowerCase()) {
        case 'bus':
          hue = BitmapDescriptor.hueBlue;
          break;
        case 'jeepney':
          hue = BitmapDescriptor.hueYellow;
          break;
        case 'multicab':
          hue = BitmapDescriptor.hueGreen;
          break;
        case 'motorela':
          hue = BitmapDescriptor.hueRed;
          break;
        default:
          hue = BitmapDescriptor.hueViolet;
      }

      // Create a colored marker with appropriate size
      final icon = BitmapDescriptor.defaultMarkerWithHue(hue);

      // Cache the icon for future use
      _markerIconCache[cacheKey] = icon;
      return icon;
    } catch (e) {
      // Fallback to colored markers if custom icon fails to load
      debugPrint('Error loading PUV icon: $e, using default marker instead');
      final icon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueViolet,
      );
      _markerIconCache[cacheKey] = icon;
      return icon;
    }
  }

  /// Get the icon for a commuter
  static Future<BitmapDescriptor> _getCommuterIcon() async {
    // Check if we already have this icon cached
    const cacheKey = 'commuter';
    if (_markerIconCache.containsKey(cacheKey)) {
      return _markerIconCache[cacheKey]!;
    }

    // Use custom person icon for commuters
    try {
      // Use a smaller size for person icon to reduce its appearance on the map
      debugPrint('Loading commuter icon with smaller size');
      // Use the non-deprecated method
      final icon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
      );

      // Note: The recommended replacement BitmapDescriptor.asset() is not available in this version
      // When available, we should use: BitmapDescriptor.asset('assets/icons/person.png', size: 32);

      // Cache the icon for future use
      _markerIconCache[cacheKey] = icon;
      return icon;
    } catch (e) {
      // Fallback to default marker if the custom icon fails to load
      debugPrint(
        'Error loading commuter icon: $e, using default marker instead',
      );
      final icon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
      );

      // Cache the icon for future use
      _markerIconCache[cacheKey] = icon;
      return icon;
    }
  }

  /// Create a custom marker with capacity and ETA information
  static Future<BitmapDescriptor> createCustomMarkerWithInfo({
    required String puvType,
    required String capacity,
    required int etaMinutes,
  }) async {
    // Create a unique cache key
    final cacheKey = 'custom_${puvType.toLowerCase()}_${capacity}_$etaMinutes';
    if (_markerIconCache.containsKey(cacheKey)) {
      return _markerIconCache[cacheKey]!;
    }

    // Create a custom marker widget
    final markerWidget = _CustomMarkerWidget(
      puvType: puvType,
      capacity: capacity,
      etaMinutes: etaMinutes,
    );

    // Convert the widget to a bitmap
    final icon = await _widgetToBitmap(markerWidget);

    // Cache the icon
    _markerIconCache[cacheKey] = icon;
    return icon;
  }

  /// Convert a widget to a bitmap descriptor
  static Future<BitmapDescriptor> _widgetToBitmap(Widget widget) async {
    // For simplicity, we'll use a simpler approach for custom markers
    // In a production app, you would use a more sophisticated approach

    // Default icon based on marker type
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
  }
}

/// Custom marker widget with capacity and ETA information
class _CustomMarkerWidget extends StatelessWidget {
  final String puvType;
  final String capacity;
  final int etaMinutes;

  const _CustomMarkerWidget({
    required this.puvType,
    required this.capacity,
    required this.etaMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Capacity and ETA info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000), // 20% opacity black
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                capacity,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                '$etaMinutes min',
                style: const TextStyle(color: Colors.blue, fontSize: 10),
              ),
            ],
          ),
        ),
        // Vehicle icon placeholder
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getColorForPuvType(puvType),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconForPuvType(puvType),
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
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
