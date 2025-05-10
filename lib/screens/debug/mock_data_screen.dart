import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../utils/mock_data_generator.dart';

/// A debug screen for generating mock location data
class MockDataScreen extends StatefulWidget {
  const MockDataScreen({Key? key}) : super(key: key);

  @override
  State<MockDataScreen> createState() => _MockDataScreenState();
}

class _MockDataScreenState extends State<MockDataScreen> {
  final MockDataGenerator _mockDataGenerator = MockDataGenerator();
  bool _isGenerating = false;
  String _statusMessage = '';
  bool _showSuccess = false;

  // Default center location (CDO City)
  final LatLng _defaultCenter = const LatLng(8.4542, 124.6319);

  // Controllers for input fields
  final TextEditingController _driverCountController = TextEditingController(
    text: '10',
  );
  final TextEditingController _commuterCountController = TextEditingController(
    text: '20',
  );
  final TextEditingController _radiusController = TextEditingController(
    text: '5.0',
  );

  // Focus nodes for input fields
  final FocusNode _driverCountFocus = FocusNode();
  final FocusNode _commuterCountFocus = FocusNode();
  final FocusNode _radiusFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Add listeners to focus nodes to validate input
    _driverCountFocus.addListener(_validateDriverCount);
    _commuterCountFocus.addListener(_validateCommuterCount);
    _radiusFocus.addListener(_validateRadius);
  }

  @override
  void dispose() {
    _driverCountController.dispose();
    _commuterCountController.dispose();
    _radiusController.dispose();
    _driverCountFocus.dispose();
    _commuterCountFocus.dispose();
    _radiusFocus.dispose();
    super.dispose();
  }

  // Validation methods
  void _validateDriverCount() {
    if (!_driverCountFocus.hasFocus) {
      final count = int.tryParse(_driverCountController.text);
      if (count == null || count <= 0) {
        _driverCountController.text = '10';
      } else if (count > 50) {
        _driverCountController.text = '50'; // Limit to 50 for performance
      }
    }
  }

  void _validateCommuterCount() {
    if (!_commuterCountFocus.hasFocus) {
      final count = int.tryParse(_commuterCountController.text);
      if (count == null || count <= 0) {
        _commuterCountController.text = '20';
      } else if (count > 100) {
        _commuterCountController.text = '100'; // Limit to 100 for performance
      }
    }
  }

  void _validateRadius() {
    if (!_radiusFocus.hasFocus) {
      final radius = double.tryParse(_radiusController.text);
      if (radius == null || radius <= 0) {
        _radiusController.text = '5.0';
      } else if (radius > 20) {
        _radiusController.text = '20.0'; // Limit to 20km for relevance
      }
    }
  }

  // Dismiss keyboard
  void _unfocus() {
    _driverCountFocus.unfocus();
    _commuterCountFocus.unfocus();
    _radiusFocus.unfocus();
  }

  /// Generate mock driver locations
  Future<void> _generateMockDrivers() async {
    if (_isGenerating) return;

    _unfocus(); // Dismiss keyboard

    setState(() {
      _isGenerating = true;
      _statusMessage = 'Generating mock drivers...';
      _showSuccess = false;
    });

    try {
      final int count = int.tryParse(_driverCountController.text) ?? 10;
      final double radius = double.tryParse(_radiusController.text) ?? 5.0;

      await _mockDataGenerator.generateMockDriverLocations(
        count: count,
        center: _defaultCenter,
        radiusKm: radius,
      );

      setState(() {
        _statusMessage = 'Successfully generated $count mock drivers';
        _showSuccess = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error generating mock drivers: $e';
        _showSuccess = false;
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  /// Generate mock commuter locations
  Future<void> _generateMockCommuters() async {
    if (_isGenerating) return;

    _unfocus(); // Dismiss keyboard

    setState(() {
      _isGenerating = true;
      _statusMessage = 'Generating mock commuters...';
      _showSuccess = false;
    });

    try {
      final int count = int.tryParse(_commuterCountController.text) ?? 20;
      final double radius = double.tryParse(_radiusController.text) ?? 5.0;

      await _mockDataGenerator.generateMockCommuterLocations(
        count: count,
        center: _defaultCenter,
        radiusKm: radius,
      );

      setState(() {
        _statusMessage = 'Successfully generated $count mock commuters';
        _showSuccess = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error generating mock commuters: $e';
        _showSuccess = false;
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  /// Generate both mock drivers and commuters
  Future<void> _generateAllMockData() async {
    if (_isGenerating) return;

    _unfocus(); // Dismiss keyboard

    setState(() {
      _isGenerating = true;
      _statusMessage = 'Generating all mock data...';
      _showSuccess = false;
    });

    try {
      final int driverCount = int.tryParse(_driverCountController.text) ?? 10;
      final int commuterCount =
          int.tryParse(_commuterCountController.text) ?? 20;
      final double radius = double.tryParse(_radiusController.text) ?? 5.0;

      await _mockDataGenerator.generateMockDriverLocations(
        count: driverCount,
        center: _defaultCenter,
        radiusKm: radius,
      );

      await _mockDataGenerator.generateMockCommuterLocations(
        count: commuterCount,
        center: _defaultCenter,
        radiusKm: radius,
      );

      setState(() {
        _statusMessage =
            'Successfully generated $driverCount drivers and $commuterCount commuters';
        _showSuccess = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error generating mock data: $e';
        _showSuccess = false;
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _unfocus, // Dismiss keyboard when tapping outside
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Generate Mock Data'),
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Input card
                  Card(
                    color: Colors.grey[900],
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Configuration',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Driver count input
                          TextField(
                            controller: _driverCountController,
                            focusNode: _driverCountFocus,
                            decoration: InputDecoration(
                              labelText: 'Number of Drivers',
                              labelStyle: TextStyle(color: Colors.blue[200]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue[700]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue[400]!,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.blue.withAlpha(25),
                              prefixIcon: const Icon(
                                Icons.drive_eta,
                                color: Colors.blue,
                              ),
                              suffixText: 'drivers',
                              helperText: 'Max: 50',
                              helperStyle: TextStyle(color: Colors.blue[200]),
                            ),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 16),

                          // Commuter count input
                          TextField(
                            controller: _commuterCountController,
                            focusNode: _commuterCountFocus,
                            decoration: InputDecoration(
                              labelText: 'Number of Commuters',
                              labelStyle: TextStyle(color: Colors.green[200]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.green[700]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.green[400]!,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.green.withAlpha(25),
                              prefixIcon: const Icon(
                                Icons.people,
                                color: Colors.green,
                              ),
                              suffixText: 'commuters',
                              helperText: 'Max: 100',
                              helperStyle: TextStyle(color: Colors.green[200]),
                            ),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 16),

                          // Radius input
                          TextField(
                            controller: _radiusController,
                            focusNode: _radiusFocus,
                            decoration: InputDecoration(
                              labelText: 'Radius (km)',
                              labelStyle: TextStyle(color: Colors.amber[200]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.amber[700]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.amber[400]!,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.amber.withAlpha(25),
                              prefixIcon: const Icon(
                                Icons.radar,
                                color: Colors.amber,
                              ),
                              suffixText: 'km',
                              helperText: 'Max: 20 km',
                              helperStyle: TextStyle(color: Colors.amber[200]),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _isGenerating ? null : _generateMockDrivers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          icon: const Icon(Icons.drive_eta),
                          label: const Text('Drivers'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _isGenerating ? null : _generateMockCommuters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          icon: const Icon(Icons.people),
                          label: const Text('Commuters'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateAllMockData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.data_array),
                    label: const Text(
                      'Generate All Data',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Status message and loading indicator
                  if (_isGenerating)
                    Column(
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.amber,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _statusMessage,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                  if (!_isGenerating && _statusMessage.isNotEmpty)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            _showSuccess
                                ? Colors.green.withAlpha(50)
                                : Colors.red.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
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
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _statusMessage,
                              style: TextStyle(
                                color: _showSuccess ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Help text
                  if (!_isGenerating)
                    Card(
                      color: Colors.grey.shade900,
                      child: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Note:',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Generated mock data will appear on the map. Drivers will follow PUV routes and commuters will be placed along these routes. Drivers use car icons and commuters use person icons.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Additional help text
                  if (!_isGenerating)
                    Card(
                      color: Colors.grey.shade900,
                      child: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data Details:',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '• Jeepneys follow specific routes (R2, C2, RA, RD)\n• Commuters are placed near their selected PUV routes\n• Data is stored in Firestore and visible to all users',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
