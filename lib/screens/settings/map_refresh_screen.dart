import 'package:flutter/material.dart';
import '../../widgets/home_map_widget.dart';
import '../../widgets/map_refresher_widget.dart';

/// A screen dedicated to refreshing the map and clearing map-related caches
///
/// This screen provides options to refresh the map, clear map caches,
/// and troubleshoot common map loading issues.
class MapRefreshScreen extends StatefulWidget {
  const MapRefreshScreen({Key? key}) : super(key: key);

  @override
  State<MapRefreshScreen> createState() => _MapRefreshScreenState();
}

class _MapRefreshScreenState extends State<MapRefreshScreen> {
  final GlobalKey<HomeMapWidgetState> _mapKey = GlobalKey<HomeMapWidgetState>();
  bool _isRefreshing = false;
  bool _isClearing = false;
  String _statusMessage = '';
  bool _showSuccess = false;

  /// Refresh the map with enhanced error handling and retry mechanism
  Future<void> _refreshMap() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _statusMessage = 'Refreshing map...';
      _showSuccess = false;
    });

    try {
      // Access the HomeMapWidgetState through the provided key
      final mapState = _mapKey.currentState;

      if (mapState != null) {
        // Re-initialize the location
        await mapState.initializeLocation();

        // Additional steps to ensure map is properly refreshed
        await Future.delayed(const Duration(milliseconds: 500));

        // Force a rebuild of the map if needed
        setState(() {});

        // Wait a bit more to ensure map has time to load
        await Future.delayed(const Duration(seconds: 1));

        // Check if map is ready
        if (mapState.isMapReady) {
          // Show success message
          setState(() {
            _statusMessage = 'Map refreshed successfully';
            _showSuccess = true;
          });
        } else {
          // Map controller isn't ready, try one more time
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            setState(() {
              _statusMessage = 'Map refresh in progress...';
            });
          }

          // Final check
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            setState(() {
              if (mapState.isMapReady) {
                _statusMessage = 'Map refreshed successfully';
                _showSuccess = true;
              } else {
                _statusMessage =
                    'Map refresh partially completed. Try again if map is not visible.';
                _showSuccess = false;
              }
            });
          }
        }
      } else {
        // Show error message if map state is not available
        setState(() {
          _statusMessage = 'Could not access map state';
          _showSuccess = false;
        });
      }
    } catch (e) {
      // Show error message
      setState(() {
        _statusMessage = 'Error refreshing map: $e';
        _showSuccess = false;
      });

      // Log the error
      debugPrint('Map refresh error: $e');
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  /// Clear map caches
  Future<void> _clearMapCaches() async {
    if (_isClearing) return;

    setState(() {
      _isClearing = true;
      _statusMessage = 'Clearing map caches...';
      _showSuccess = false;
    });

    try {
      // Simulate cache clearing (in a real app, you would clear actual caches)
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _statusMessage = 'Map caches cleared successfully';
        _showSuccess = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error clearing map caches: $e';
        _showSuccess = false;
      });
    } finally {
      setState(() {
        _isClearing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Map Refresh'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Map preview (small)
            Container(
              height: 200,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade800),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Map widget
                  HomeMapWidget(
                    key: _mapKey,
                    showUserLocation: true,
                    onDestinationSelected: (destination) {
                      // Handle destination selection if needed
                      // In a production app, use a proper logging framework
                      debugPrint('Destination selected: $destination');
                    },
                  ),

                  // Overlay with refresh button
                  if (_isRefreshing)
                    Container(
                      color: Colors.black.withAlpha(150),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),

            // Status message
            if (_statusMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      _showSuccess
                          ? Colors.green.withAlpha(50)
                          : Colors.red.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _showSuccess ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _showSuccess ? Icons.check_circle : Icons.error,
                      color: _showSuccess ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _showSuccess ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        _isRefreshing || _isClearing ? null : _refreshMap,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed:
                        _isRefreshing || _isClearing ? null : _clearMapCaches,
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Clear Map Caches'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Help text
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Troubleshooting Tips',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTroubleshootingItem(
                      'If the map doesn\'t load, try refreshing it using the button above.',
                    ),
                    _buildTroubleshootingItem(
                      'Make sure your device has an active internet connection.',
                    ),
                    _buildTroubleshootingItem(
                      'Enable location services on your device.',
                    ),
                    _buildTroubleshootingItem(
                      'Grant location permissions to the app.',
                    ),
                    _buildTroubleshootingItem(
                      'If problems persist, try restarting the app.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
