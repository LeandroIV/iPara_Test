import 'package:flutter/material.dart';
import 'home_map_widget.dart';

/// A widget that provides a refresh button for Google Maps
///
/// This widget adds a floating action button that can be used to refresh
/// the Google Maps widget when it fails to load properly.
class MapRefresherWidget extends StatefulWidget {
  /// The key of the HomeMapWidget to refresh
  final GlobalKey<HomeMapWidgetState> mapKey;

  /// The position of the refresh button (default is bottom right)
  final MapRefresherPosition position;

  /// Optional callback to execute after refreshing
  final Function? onRefresh;

  /// Create a new MapRefresherWidget
  const MapRefresherWidget({
    super.key,
    required this.mapKey,
    this.position = MapRefresherPosition.bottomRight,
    this.onRefresh,
  });

  @override
  State<MapRefresherWidget> createState() => _MapRefresherWidgetState();
}

class _MapRefresherWidgetState extends State<MapRefresherWidget> {
  bool _isRefreshing = false;

  /// Refresh the map with enhanced error handling and retry mechanism
  Future<void> _refreshMap() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Access the HomeMapWidgetState through the provided key
      final mapState = widget.mapKey.currentState;

      if (mapState != null) {
        // Re-initialize the location
        await mapState.initializeLocation();

        // Wait a moment to ensure map has time to initialize
        await Future.delayed(const Duration(milliseconds: 500));

        // Check if the map is ready after initialization
        if (mapState.isMapReady) {
          // Map is ready, we can proceed with additional operations if needed
          // Force a rebuild of the map by calling setState on the parent widget
          if (widget.onRefresh != null) {
            widget.onRefresh!();
          }

          // Wait a bit to ensure changes take effect
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          // Map is still not ready, wait a bit longer
          await Future.delayed(const Duration(seconds: 1));
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Map refreshed successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Show error message if map state is not available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not access map state'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      // Call the onRefresh callback if provided
      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing map: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Log the error
      debugPrint('Map refresher error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Position is determined directly in the Positioned widget

    return Positioned(
      right:
          widget.position == MapRefresherPosition.topRight ||
                  widget.position == MapRefresherPosition.bottomRight
              ? 16
              : null,
      left:
          widget.position == MapRefresherPosition.topLeft ||
                  widget.position == MapRefresherPosition.bottomLeft
              ? 16
              : null,
      top:
          widget.position == MapRefresherPosition.topRight ||
                  widget.position == MapRefresherPosition.topLeft
              ? 70
              : null,
      bottom:
          widget.position == MapRefresherPosition.bottomRight ||
                  widget.position == MapRefresherPosition.bottomLeft
              ? 30
              : null,
      child: FloatingActionButton(
        heroTag: 'mapRefresher',
        onPressed: _refreshMap,
        backgroundColor: Colors.white,
        mini: true,
        child:
            _isRefreshing
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                )
                : const Icon(Icons.refresh, color: Colors.blue),
      ),
    );
  }
}

/// Enum defining the possible positions for the refresh button
enum MapRefresherPosition { topRight, topLeft, bottomRight, bottomLeft }
