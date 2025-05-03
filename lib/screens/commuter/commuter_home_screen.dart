import 'package:flutter/material.dart';
import '../../models/user_role.dart';
import '../../services/user_service.dart';
import '../../widgets/home_map_widget.dart';
import '../../services/route_service.dart';
import '../../models/route_model.dart';
import '../edit_profile_screen.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  final GlobalKey _searchBarKey = GlobalKey();

  // Make location visibility true by default
  bool _isLocationVisibleToDrivers = true;

  // Add these variables for search functionality
  bool _isSearching = false;
  List<dynamic> _googlePlacesResults = [];
  bool _isLoadingPlaces = false;
  Timer? _debounceTimer;

  // Add RouteService
  final RouteService _routeService = RouteService();
  List<PUVRoute> _availableRoutes = [];
  bool _isLoadingRoutes = false;
  PUVRoute? _selectedRoute;

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

    // Load mock routes on startup
    _loadRoutes();
  }

  // Load routes from service
  Future<void> _loadRoutes() async {
    setState(() {
      _isLoadingRoutes = true;
    });

    try {
      // For demo purposes, use mock data
      // In production, this would be: await _routeService.getAllRoutes();
      _availableRoutes = _routeService.getMockRoutes();
    } catch (e) {
      print('Error loading routes: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoutes = false;
        });
      }
    }
  }

  // Filter routes based on selected PUV type
  List<PUVRoute> get filteredRoutes {
    return _availableRoutes
        .where(
          (route) =>
              route.puvType.toLowerCase() == selectedPUVType.toLowerCase(),
        )
        .toList();
  }

  // Display route on map
  Future<void> _displayRoute(PUVRoute route) async {
    setState(() {
      _selectedRoute = route;
    });

    // Use the map widget to display the route
    if (_mapKey.currentState != null) {
      await _mapKey.currentState!.showPredefinedRoute(
        route.waypoints,
        route.colorValue,
        routeName: route.routeCode,
      );
    }
  }

  // Clear route from map
  void _clearRoute() {
    setState(() {
      _selectedRoute = null;
    });

    if (_mapKey.currentState != null) {
      _mapKey.currentState!.clearRoutes();
    }
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

  // Helper method to build a route card
  Widget _buildRouteCard(PUVRoute route, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: InkWell(
        onTap: () {
          _displayRoute(route);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 170,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Color(route.colorValue).withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border:
                isSelected
                    ? Border.all(color: Color(route.colorValue), width: 2)
                    : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Color(route.colorValue),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      route.routeCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '₱${route.farePrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  '${route.startPointName} to ${route.endPointName}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.white70,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '~${route.estimatedTravelTime} min',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Toggle location visibility to drivers
  void _toggleLocationVisibility() {
    setState(() {
      _isLocationVisibleToDrivers = !_isLocationVisibleToDrivers;
    });

    // Explicitly refresh the map to show/hide the user location pin immediately
    if (_mapKey.currentState != null) {
      _mapKey.currentState!.updateUserLocationVisibility(
        _isLocationVisibleToDrivers,
      );
    }

    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isLocationVisibleToDrivers
              ? 'Your location is now visible to drivers'
              : 'Your location is now hidden from drivers',
        ),
        backgroundColor:
            _isLocationVisibleToDrivers ? Colors.green : Colors.red,
        duration: Duration(seconds: 2),
      ),
    );

    // TODO: Implement actual location sharing logic with backend
  }

  // Handle location permission granted callback
  void _handleLocationPermissionGranted() {
    if (!_isLocationVisibleToDrivers) {
      setState(() {
        _isLocationVisibleToDrivers = true;
      });

      // Show a snackbar informing the user they are now visible
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your location is now visible to drivers for improved route matching',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'HIDE',
            onPressed: _toggleLocationVisibility,
            textColor: Colors.white,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get filtered routes based on selected PUV type
    final routes = filteredRoutes;

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
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        UserRole.commuter.icon,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Commuter Mode',
                                          style: TextStyle(
                                            color: Colors.amber,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
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

                  // Destination Search
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      key: _searchBarKey,
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

                                    // Clear the user route polyline when search is cleared
                                    if (_mapKey.currentState != null) {
                                      _mapKey.currentState!.clearRoutes(
                                        clearUserRoute: true,
                                        clearPUVRoute: false,
                                      );
                                      _mapKey.currentState!
                                          .clearDestinationMarker();
                                    }
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
                          // Loading indicator when searching (in column to avoid affecting layout)
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PUV Type Selection
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                        Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:
                                  puvCounts.entries.map((entry) {
                                    bool isSelected =
                                        selectedPUVType == entry.key;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 12.0,
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            selectedPUVType = entry.key;

                                            // Clear any selected route when changing PUV type
                                            _selectedRoute = null;
                                            if (_mapKey.currentState != null) {
                                              _mapKey.currentState!.clearRoutes(
                                                clearUserRoute: false,
                                                clearPUVRoute: true,
                                              );
                                            }
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              isSelected
                                                  ? Colors.amber
                                                  : Colors.white.withOpacity(
                                                    0.1,
                                                  ),
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
                                          mainAxisSize: MainAxisSize.min,
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
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Available Routes Section (new)
                  if (routes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Available Routes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_selectedRoute != null)
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Clear Route',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  onPressed: _clearRoute,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 120,
                            width: double.infinity,
                            child:
                                _isLoadingRoutes
                                    ? const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.amber,
                                      ),
                                    )
                                    : Center(
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        shrinkWrap: true,
                                        itemCount: routes.length,
                                        itemBuilder: (context, index) {
                                          final route = routes[index];
                                          final isSelected =
                                              _selectedRoute?.id == route.id;
                                          return _buildRouteCard(
                                            route,
                                            isSelected,
                                          );
                                        },
                                      ),
                                    ),
                          ),
                        ],
                      ),
                    ),

                  // Map Widget
                  Expanded(
                    child: Stack(
                      children: [
                        // Map with rounded corners
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: HomeMapWidget(
                            key: _mapKey,
                            showUserLocation: _isLocationVisibleToDrivers,
                            onDestinationSelected: (destination) {
                              setState(() {
                                _destinationController.text = destination;
                              });
                            },
                          ),
                        ),

                        // Privacy toggle button (positioned at the bottom right of the map)
                        Positioned(
                          left: 16,
                          top: 16,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    _isLocationVisibleToDrivers
                                        ? Colors.green.withOpacity(0.9)
                                        : Colors.red.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Tooltip(
                                message:
                                    _isLocationVisibleToDrivers
                                        ? 'Your location is visible to drivers'
                                        : 'Your location is hidden from drivers',
                                child: InkWell(
                                  onTap: _toggleLocationVisibility,
                                  borderRadius: BorderRadius.circular(24),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isLocationVisibleToDrivers
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

          // Suggestions Overlay
          if (_isSearching && _googlePlacesResults.isNotEmpty)
            Positioned(
              top: 130, // Adjust this value based on your UI
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: const Color.fromARGB(255, 51, 51, 51).withOpacity(1),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _googlePlacesResults.length,
                    itemBuilder: (context, index) {
                      final place = _googlePlacesResults[index];
                      return ListTile(
                        leading: Icon(Icons.location_on, color: Colors.amber),
                        title: Text(
                          place['structured_formatting']?['main_text'] ??
                              place['description'] ??
                              '',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          place['structured_formatting']?['secondary_text'] ??
                              '',
                          style: TextStyle(color: Colors.white70),
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
              ),
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
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}
