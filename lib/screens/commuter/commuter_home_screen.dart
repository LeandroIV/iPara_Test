import 'package:flutter/material.dart';
import '../../models/user_role.dart';
import '../../services/user_service.dart';
import '../../widgets/home_map_widget.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommuterHomeScreen extends StatefulWidget {
  const CommuterHomeScreen({super.key});

  @override
  State<CommuterHomeScreen> createState() => _CommuterHomeScreenState();
}

class _CommuterHomeScreenState extends State<CommuterHomeScreen>
    with SingleTickerProviderStateMixin {
  String selectedPUVType = 'Bus';
  bool isDrawerOpen = false;
  late AnimationController _drawerController;
  late Animation<double> _drawerAnimation;
  final TextEditingController _destinationController = TextEditingController();
  final GlobalKey<HomeMapWidgetState> _mapKey = GlobalKey<HomeMapWidgetState>();

  // Add these variables for search functionality
  bool _isSearching = false;
  List<dynamic> _googlePlacesResults = [];
  bool _isLoadingPlaces = false;
  Timer? _debounceTimer;

  // Placeholder data for PUV counts
  final Map<String, int> puvCounts = {
    'Bus': 12,
    'Jeepney': 45,
    'Multicab': 23,
    'Motorela': 15,
  };

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
    _destinationController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Add this method for search functionality
  void _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _googlePlacesResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isLoadingPlaces = true;
      _isSearching = true;
    });

    try {
      // Use the map widget's search functionality
      if (_mapKey.currentState != null) {
        final results = await _mapKey.currentState!.searchPlaces(query);
        setState(() {
          _googlePlacesResults = results;
          _isLoadingPlaces = false;
        });
      }
    } catch (e) {
      print('Error searching places: $e');
      setState(() {
        _googlePlacesResults = [];
        _isLoadingPlaces = false;
      });
    }
  }

  // Add this method to handle place selection
  void _selectPlace(dynamic place) async {
    if (_mapKey.currentState != null) {
      final placeId = place['place_id'];
      await _mapKey.currentState!.getPlaceDetails(placeId);
      setState(() {
        _isSearching = false;
      });
    }
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

  // Add the sign out method
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
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
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    UserRole.commuter.icon,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Commuter Mode',
                                    style: TextStyle(
                                      color: Colors.amber,
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

                  // Destination Search
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_searching,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Select your Destination',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    TextField(
                                      controller: _destinationController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Where to?',
                                        hintStyle: TextStyle(
                                          color: Colors.white54,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (value) {
                                        if (_debounceTimer?.isActive ?? false) {
                                          _debounceTimer!.cancel();
                                        }
                                        _debounceTimer = Timer(
                                          const Duration(milliseconds: 500),
                                          () => _searchPlaces(value),
                                        );
                                      },
                                      onTap: () {
                                        setState(() {
                                          _isSearching = true;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              if (_isSearching)
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isSearching = false;
                                      _destinationController.clear();
                                      _googlePlacesResults = [];
                                    });
                                  },
                                ),
                              if (!_isSearching)
                                IconButton(
                                  icon: const Icon(
                                    Icons.search,
                                    color: Colors.amber,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isSearching = true;
                                    });
                                  },
                                ),
                            ],
                          ),
                          // Loading indicator when searching
                          if (_isSearching && _isLoadingPlaces)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.amber,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          // Search results
                          if (_isSearching && _googlePlacesResults.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Suggested Locations',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight:
                                          MediaQuery.of(context).size.height *
                                          0.3,
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _googlePlacesResults.length,
                                      itemBuilder: (context, index) {
                                        final place =
                                            _googlePlacesResults[index];
                                        return ListTile(
                                          leading: const Icon(
                                            Icons.location_on,
                                            color: Colors.amber,
                                          ),
                                          title: Text(
                                            place['structured_formatting']?['main_text'] ??
                                                place['description'] ??
                                                '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            place['structured_formatting']?['secondary_text'] ??
                                                '',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          onTap: () {
                                            _selectPlace(place);
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PUV Type Selection
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select PUV Type',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                puvCounts.entries.map((entry) {
                                  bool isSelected =
                                      selectedPUVType == entry.key;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          selectedPUVType = entry.key;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            isSelected
                                                ? Colors.amber
                                                : Colors.white.withOpacity(0.1),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            entry.key,
                                            style: TextStyle(
                                              color:
                                                  isSelected
                                                      ? Colors.white
                                                      : Colors.white70,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${entry.value} available',
                                            style: TextStyle(
                                              color:
                                                  isSelected
                                                      ? Colors.white70
                                                      : Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Map Widget
                  Expanded(
                    child: HomeMapWidget(
                      key: _mapKey,
                      onDestinationSelected: (destination) {
                        setState(() {
                          _destinationController.text = destination;
                        });
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
                            color: Colors.amber.withOpacity(0.3),
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
                                color: Colors.amber.withOpacity(0.2),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.amber,
                                    child: Icon(
                                      UserRole.commuter.icon,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Commuter Mode',
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
                                            color: Colors.amber,
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
                                    icon: Icons.home,
                                    title: 'Home',
                                    onTap: () {
                                      _toggleDrawer();
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.history,
                                    title: 'Trip History',
                                    onTap: () {
                                      _toggleDrawer();
                                      // TODO: Navigate to trip history
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.favorite,
                                    title: 'Favorite Routes',
                                    onTap: () {
                                      _toggleDrawer();
                                      // TODO: Navigate to favorite routes
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.notifications,
                                    title: 'Notifications',
                                    onTap: () {
                                      _toggleDrawer();
                                      // TODO: Navigate to notifications
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.person,
                                    title: 'Profile',
                                    onTap: () {
                                      _toggleDrawer();
                                      // TODO: Navigate to profile
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
                                  // Add Switch Role option to drawer menu
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
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
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
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.amber),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}
