import 'package:flutter/material.dart';
import '../../models/user_role.dart';
import '../../services/user_service.dart';
import '../edit_profile_screen.dart';
import '../notification_settings_screen.dart';
import '../settings/settings_screen.dart';
import '../help_support_screen.dart';
import '../commuter/notifications_screen.dart';
import 'add_driver_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/route_service.dart';
import 'vehicle_management_screen.dart';
import 'route_management_screen.dart';
import 'drivers_management_screen.dart';
import 'finance_screen.dart';
import 'analytics_screen.dart';

class OperatorHomeScreen extends StatefulWidget {
  const OperatorHomeScreen({super.key});

  @override
  State<OperatorHomeScreen> createState() => _OperatorHomeScreenState();
}

class _OperatorHomeScreenState extends State<OperatorHomeScreen>
    with SingleTickerProviderStateMixin {
  bool isDrawerOpen = false;
  late AnimationController _drawerController;
  late Animation<double> _drawerAnimation;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RouteService _routeService = RouteService();

  // Fleet statistics
  Map<String, int> _fleetStatus = {
    'Total Vehicles': 0,
    'Active': 0,
    'Inactive': 0,
    'Under Maintenance': 0,
  };

  // Driver data
  List<Map<String, dynamic>> _drivers = [];
  bool _isLoading = true;

  // Mock earnings data (to be kept as mock)
  final Map<String, double> _mockEarnings = {'Active': 1250.0, 'Inactive': 0.0};

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _drawerAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _drawerController, curve: Curves.easeInOut),
    );

    // Load driver data from Firestore
    _loadDriverData();
  }

  // Load driver data from Firestore
  Future<void> _loadDriverData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all driver locations
      final snapshot =
          await _firestore
              .collection('driver_locations')
              .where('isOnline', isEqualTo: true)
              .get();

      // Convert to list of maps
      final List<Map<String, dynamic>> driversList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Get route name if routeId is available
        String routeName = '';
        if (data['routeId'] != null) {
          try {
            final routeDoc =
                await _firestore
                    .collection('routes')
                    .doc(data['routeId'])
                    .get();

            if (routeDoc.exists) {
              routeName = routeDoc.data()?['name'] ?? '';
            } else if (data['routeCode'] != null) {
              // Fallback to routeCode if route document doesn't exist
              routeName = data['routeCode'];
            }
          } catch (e) {
            debugPrint('Error fetching route: $e');
          }
        }

        // Create driver data with mock earnings
        final driver = {
          'id': doc.id,
          'name': data['driverName'] ?? 'Unknown Driver',
          'vehicleId': data['plateNumber'] ?? 'Unknown',
          'route': routeName.isNotEmpty ? routeName : 'No Route Assigned',
          'status': data['isOnline'] == true ? 'Active' : 'Inactive',
          'earnings':
              data['isOnline'] == true
                  ? _mockEarnings['Active']!
                  : _mockEarnings['Inactive']!,
          'puvType': data['puvType'] ?? 'Unknown',
        };

        driversList.add(driver);
      }

      // Update fleet statistics
      final totalDrivers = driversList.length;
      final activeDrivers =
          driversList.where((d) => d['status'] == 'Active').length;
      final inactiveDrivers = totalDrivers - activeDrivers;

      // Get maintenance count from vehicles collection
      final vehiclesSnapshot =
          await _firestore
              .collection('vehicles')
              .where('isActive', isEqualTo: false)
              .get();

      final maintenanceCount = vehiclesSnapshot.docs.length;

      setState(() {
        _drivers = driversList;
        _fleetStatus = {
          'Total Vehicles': totalDrivers,
          'Active': activeDrivers,
          'Inactive': inactiveDrivers,
          'Under Maintenance': maintenanceCount,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading driver data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() {
      isDrawerOpen = !isDrawerOpen;
      if (isDrawerOpen) {
        _drawerController.forward();
      } else {
        _drawerController.reverse();
      }
    });
  }

  Future<void> _switchUserRole() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Switch Role'),
            content: const Text('Do you want to switch your user role?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final ctx = context;
                  Navigator.pop(ctx);
                  await UserService.clearUserRole();
                  if (mounted && ctx.mounted) {
                    Navigator.pushReplacementNamed(ctx, '/role-selection');
                  }
                },
                child: const Text('Switch'),
              ),
            ],
          ),
    );
  }

  Future<void> _signOut() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
          );
        },
      );

      // Clear user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        // Close loading dialog and navigate
        Navigator.of(context).pop(); // Close loading dialog

        // Navigate to login screen with replacement to prevent going back
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      debugPrint('Error signing out: $e');

      // Show error message if context is still valid
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Color(0xFF1A1A1A)],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with role indicator
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.menu, color: Colors.white),
                          onPressed: _toggleDrawer,
                        ),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(
                                  51,
                                ), // 0.2 * 255 = 51
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    UserRole.operator.icon,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Operator Mode',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.person, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Dashboard title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Fleet Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Fleet Statistics Cards
                  SizedBox(
                    height: 110,
                    child:
                        _isLoading
                            ? Center(child: CircularProgressIndicator())
                            : ListView(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              children:
                                  _fleetStatus.entries.map((entry) {
                                    Color cardColor;
                                    IconData cardIcon;

                                    switch (entry.key) {
                                      case 'Total Vehicles':
                                        cardColor = Colors.blue;
                                        cardIcon = Icons.directions_car;
                                        break;
                                      case 'Active':
                                        cardColor = Colors.green;
                                        cardIcon = Icons.check_circle;
                                        break;
                                      case 'Inactive':
                                        cardColor = Colors.red;
                                        cardIcon = Icons.cancel;
                                        break;
                                      case 'Under Maintenance':
                                        cardColor = Colors.orange;
                                        cardIcon = Icons.build;
                                        break;
                                      default:
                                        cardColor = Colors.grey;
                                        cardIcon = Icons.info;
                                    }

                                    return Container(
                                      width: 150,
                                      margin: EdgeInsets.only(right: 12),
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            cardColor.withAlpha(
                                              179,
                                            ), // 0.7 * 255 = 178.5 ≈ 179
                                            cardColor.withAlpha(
                                              102,
                                            ), // 0.4 * 255 = 102
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            cardIcon,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            entry.value.toString(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            entry.key,
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                            ),
                  ),

                  const SizedBox(height: 24),

                  // Active Drivers section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active Drivers',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _isLoading ? null : _loadDriverData,
                              icon: Icon(Icons.refresh, size: 20),
                              tooltip: 'Refresh',
                              color: Colors.green,
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const DriversManagementScreen(),
                                  ),
                                );
                              },
                              icon: Icon(Icons.visibility, size: 16),
                              label: Text('View All'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.green,
                              ),
                            ),
                            if (true) // Always show in debug mode
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/debug/firestore',
                                  );
                                },
                                icon: Icon(Icons.bug_report, size: 16),
                                label: Text('Test DB'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.amber,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Driver List in an Expanded widget to take remaining space
                  Expanded(
                    child:
                        _isLoading
                            ? Center(child: CircularProgressIndicator())
                            : _drivers.isEmpty
                            ? Center(
                              child: Text(
                                'No active drivers found',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                            : ListView.builder(
                              padding: EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 8,
                                bottom: 80, // Extra bottom padding for FAB
                              ),
                              itemCount: _drivers.length,
                              itemBuilder: (context, index) {
                                final driver = _drivers[index];
                                final bool isActive =
                                    driver['status'] == 'Active';

                                return Card(
                                  margin: EdgeInsets.only(bottom: 12),
                                  color: Colors.white.withAlpha(
                                    26,
                                  ), // 0.1 * 255 = 25.5 ≈ 26
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          isActive ? Colors.green : Colors.red,
                                      child: Icon(
                                        isActive
                                            ? Icons.person
                                            : Icons.person_off,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      driver['name'],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(height: 4),
                                        Text(
                                          'Vehicle: ${driver['vehicleId']}',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Text(
                                          'Route: ${driver['route']}',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    trailing: SizedBox(
                                      width: 80,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isActive
                                                      ? Colors.green.withAlpha(
                                                        51,
                                                      ) // 0.2 * 255 = 51
                                                      : Colors.red.withAlpha(
                                                        51, // 0.2 * 255 = 51
                                                      ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              driver['status'],
                                              style: TextStyle(
                                                color:
                                                    isActive
                                                        ? Colors.green
                                                        : Colors.red,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            '₱ ${driver['earnings']}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    onTap: () {
                                      // Navigate to driver details
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),

          // Overlay (only when drawer is open)
          if (isDrawerOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleDrawer,
                child: Container(
                  color: Colors.black.withAlpha(77),
                ), // 0.3 * 255 = 76.5 ≈ 77
              ),
            ),

          // Side Drawer with Animation
          AnimatedBuilder(
            animation: _drawerAnimation,
            builder: (context, child) {
              return Positioned(
                left:
                    MediaQuery.of(context).size.width * _drawerAnimation.value,
                top: 0,
                bottom: 0,
                width: MediaQuery.of(context).size.width * 0.75,
                child: GestureDetector(
                  onTap:
                      () {}, // Prevent drawer from closing when tapping inside
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withAlpha(
                              77,
                            ), // 0.3 * 255 = 76.5 ≈ 77
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Column(
                          children: [
                            // User Role Section
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(
                                  51,
                                ), // 0.2 * 255 = 51
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.green,
                                    child: Icon(
                                      UserRole.operator.icon,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Operator Mode',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        FirebaseAuth
                                                .instance
                                                .currentUser
                                                ?.displayName ??
                                            'User',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      GestureDetector(
                                        onTap: _switchUserRole,
                                        child: Text(
                                          'Switch role',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            Expanded(
                              child: ListView(
                                padding: EdgeInsets.zero,
                                children: [
                                  _buildDrawerItem(
                                    icon: Icons.dashboard,
                                    title: 'Dashboard',
                                    onTap: () {
                                      _toggleDrawer();
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.people,
                                    title: 'Drivers',
                                    onTap: () {
                                      _toggleDrawer();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const DriversManagementScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.directions_car,
                                    title: 'Vehicles',
                                    onTap: () {
                                      _toggleDrawer();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const VehicleManagementScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.route,
                                    title: 'Routes',
                                    onTap: () {
                                      _toggleDrawer();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const RouteManagementScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.monetization_on,
                                    title: 'Finance',
                                    onTap: () {
                                      _toggleDrawer();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const FinanceScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.analytics,
                                    title: 'Analytics',
                                    onTap: () {
                                      _toggleDrawer();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const AnalyticsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.person,
                                    title: 'Account',
                                    onTap: () {
                                      _toggleDrawer();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const EditProfileScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.settings,
                                    title: 'Settings',
                                    onTap: () {
                                      _toggleDrawer();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const SettingsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.notifications_active,
                                    title: 'Notification Settings',
                                    onTap: () {
                                      _toggleDrawer();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const NotificationSettingsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.help,
                                    title: 'Help & Support',
                                    onTap: () {
                                      _toggleDrawer();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const HelpSupportScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.swap_horiz,
                                    title: 'Switch Role',
                                    onTap: () {
                                      _toggleDrawer();
                                      _switchUserRole();
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Logout Button
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: ElevatedButton.icon(
                                onPressed: _signOut,
                                icon: const Icon(Icons.logout),
                                label: const Text('Logout'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show options to add driver or vehicle
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.black87,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder:
                (context) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.person_add,
                          color: Colors.green,
                        ),
                        title: const Text(
                          'Add Driver',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddDriverScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.directions_car,
                          color: Colors.green,
                        ),
                        title: const Text(
                          'Add Vehicle',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const VehicleManagementScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.build, color: Colors.green),
                        title: const Text(
                          'Vehicle Maintenance',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const VehicleManagementScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.route, color: Colors.green),
                        title: const Text(
                          'Route Management',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const RouteManagementScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
          );
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}
