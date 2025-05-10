import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../debug/mock_data_screen.dart';
import 'map_refresh_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;

  // App settings
  bool _enableDarkMode = true;
  bool _enableLocationSharing = true;
  bool _enableNotifications = true;
  String _mapType = 'Normal';
  bool _showTraffic = false;
  bool _isDebugModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _enableDarkMode = prefs.getBool('enable_dark_mode') ?? true;
        _enableLocationSharing =
            prefs.getBool('enable_location_sharing') ?? true;
        _enableNotifications = prefs.getBool('enable_notifications') ?? true;
        _mapType = prefs.getString('map_type') ?? 'Normal';
        _showTraffic = prefs.getBool('show_traffic') ?? false;
        _isDebugModeEnabled = prefs.getBool('debug_mode_enabled') ?? false;

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('enable_dark_mode', _enableDarkMode);
      await prefs.setBool('enable_location_sharing', _enableLocationSharing);
      await prefs.setBool('enable_notifications', _enableNotifications);
      await prefs.setString('map_type', _mapType);
      await prefs.setBool('show_traffic', _showTraffic);
      await prefs.setBool('debug_mode_enabled', _isDebugModeEnabled);

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving settings: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Appearance Section
                    _buildSectionHeader('Appearance'),

                    SwitchListTile(
                      title: const Text(
                        'Dark Mode',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Use dark theme throughout the app',
                        style: TextStyle(color: Colors.white70),
                      ),
                      value: _enableDarkMode,
                      onChanged: (value) {
                        setState(() {
                          _enableDarkMode = value;
                        });
                      },
                      activeColor: Colors.amber,
                    ),

                    const Divider(color: Colors.white24),

                    // Map Settings Section
                    _buildSectionHeader('Map Settings'),

                    ListTile(
                      title: const Text(
                        'Map Type',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Current: $_mapType',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: DropdownButton<String>(
                        value: _mapType,
                        dropdownColor: Colors.grey[900],
                        style: const TextStyle(color: Colors.white),
                        underline: Container(height: 2, color: Colors.amber),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _mapType = newValue;
                            });
                          }
                        },
                        items:
                            <String>[
                              'Normal',
                              'Satellite',
                              'Terrain',
                              'Hybrid',
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                      ),
                    ),

                    SwitchListTile(
                      title: const Text(
                        'Show Traffic',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Display traffic information on the map',
                        style: TextStyle(color: Colors.white70),
                      ),
                      value: _showTraffic,
                      onChanged: (value) {
                        setState(() {
                          _showTraffic = value;
                        });
                      },
                      activeColor: Colors.amber,
                    ),

                    ListTile(
                      title: const Text(
                        'Map Refresh',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Refresh map when it fails to load properly',
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(Icons.refresh, color: Colors.amber),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapRefreshScreen(),
                          ),
                        );
                      },
                    ),

                    const Divider(color: Colors.white24),

                    // Privacy Section
                    _buildSectionHeader('Privacy'),

                    SwitchListTile(
                      title: const Text(
                        'Location Sharing',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Share your location with drivers/commuters',
                        style: TextStyle(color: Colors.white70),
                      ),
                      value: _enableLocationSharing,
                      onChanged: (value) {
                        setState(() {
                          _enableLocationSharing = value;
                        });
                      },
                      activeColor: Colors.amber,
                    ),

                    SwitchListTile(
                      title: const Text(
                        'Notifications',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Enable push notifications',
                        style: TextStyle(color: Colors.white70),
                      ),
                      value: _enableNotifications,
                      onChanged: (value) {
                        setState(() {
                          _enableNotifications = value;
                        });
                      },
                      activeColor: Colors.amber,
                    ),

                    const Divider(color: Colors.white24),

                    // Developer Options Section
                    _buildSectionHeader('Developer Options'),

                    SwitchListTile(
                      title: const Text(
                        'Debug Mode',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Enable developer debugging features',
                        style: TextStyle(color: Colors.white70),
                      ),
                      value: _isDebugModeEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isDebugModeEnabled = value;
                        });
                      },
                      activeColor: Colors.amber,
                    ),

                    if (_isDebugModeEnabled)
                      ListTile(
                        title: const Text(
                          'Mock Data Generator',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'Generate mock driver and commuter data',
                          style: TextStyle(color: Colors.white70),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.amber,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MockDataScreen(),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 32),

                    // App Information
                    const Center(
                      child: Text(
                        'iPara v1.0.0',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const Center(
                      child: Text(
                        '© 2023 iPara Team',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
