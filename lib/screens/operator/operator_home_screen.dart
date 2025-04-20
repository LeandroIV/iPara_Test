import 'package:flutter/material.dart';
import '../../models/user_role.dart';
import '../../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Placeholder data for fleet statistics
  final Map<String, int> _fleetStatus = {
    'Total Vehicles': 24,
    'Active': 18,
    'Inactive': 6,
    'Under Maintenance': 3,
  };

  // Placeholder data for drivers
  final List<Map<String, dynamic>> _drivers = [
    {
      'name': 'John Doe',
      'vehicleId': 'JPN-123',
      'route': 'R2 - Carmen to Divisoria',
      'status': 'Active',
      'earnings': 1250.0,
    },
    {
      'name': 'Jane Smith',
      'vehicleId': 'JPN-456',
      'route': 'R3 - Bulua to Divisoria',
      'status': 'Active',
      'earnings': 950.0,
    },
    {
      'name': 'Mark Johnson',
      'vehicleId': 'JPN-789',
      'route': 'R4 - Bugo to Lapasan',
      'status': 'Inactive',
      'earnings': 0.0,
    },
    {
      'name': 'Robert Garcia',
      'vehicleId': 'JPN-234',
      'route': 'R7 - Balulang to Divisoria',
      'status': 'Active',
      'earnings': 1100.0,
    },
    {
      'name': 'Maria Santos',
      'vehicleId': 'JPN-567',
      'route': 'R10 - Canitoan to Cogon',
      'status': 'Active',
      'earnings': 1320.0,
    },
  ];

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
                  Navigator.pop(context);
                  await UserService.clearUserRole();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/role-selection');
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

      print('Error signing out: $e');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign out failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
                                color: Colors.green.withOpacity(0.2),
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
                            // Navigate to profile
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
                    child: ListView(
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
                                    cardColor.withOpacity(0.7),
                                    cardColor.withOpacity(0.4),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(cardIcon, color: Colors.white, size: 24),
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
                        TextButton.icon(
                          onPressed: () {
                            // Navigate to all drivers
                          },
                          icon: Icon(Icons.visibility, size: 16),
                          label: Text('View All'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Driver List in an Expanded widget to take remaining space
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 8,
                        bottom: 80, // Extra bottom padding for FAB
                      ),
                      itemCount: _drivers.length,
                      itemBuilder: (context, index) {
                        final driver = _drivers[index];
                        final bool isActive = driver['status'] == 'Active';

                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          color: Colors.white.withOpacity(0.1),
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
                                isActive ? Icons.person : Icons.person_off,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  'Vehicle: ${driver['vehicleId']}',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  'Route: ${driver['route']}',
                                  style: TextStyle(color: Colors.white70),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            trailing: SizedBox(
                              width: 80,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
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
                                              ? Colors.green.withOpacity(0.2)
                                              : Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
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
                child: Container(color: Colors.black.withOpacity(0.3)),
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
                            color: Colors.green.withOpacity(0.3),
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
                                color: Colors.green.withOpacity(0.2),
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
                                      // TODO: Navigate to drivers
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.directions_car,
                                    title: 'Vehicles',
                                    onTap: () {
                                      _toggleDrawer();
                                      // TODO: Navigate to vehicles
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.route,
                                    title: 'Routes',
                                    onTap: () {
                                      _toggleDrawer();
                                      // TODO: Navigate to routes
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.monetization_on,
                                    title: 'Finance',
                                    onTap: () {
                                      _toggleDrawer();
                                      // TODO: Navigate to finance
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.analytics,
                                    title: 'Analytics',
                                    onTap: () {
                                      _toggleDrawer();
                                      // TODO: Navigate to analytics
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.settings,
                                    title: 'Settings',
                                    onTap: () {
                                      _toggleDrawer();
                                      // TODO: Navigate to settings
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.help,
                                    title: 'Help & Support',
                                    onTap: () {
                                      _toggleDrawer();
                                      // TODO: Navigate to help & support
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new driver or vehicle
        },
        backgroundColor: Colors.green,
        child: Icon(Icons.add),
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
