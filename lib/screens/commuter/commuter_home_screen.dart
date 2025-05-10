import 'package:flutter/material.dart';
import '../../models/user_role.dart';
import '../../services/user_service.dart';
import '../../widgets/home_map_widget.dart';
import '../../widgets/map_refresher_widget.dart';
import '../../services/route_service.dart';
import '../../models/route_model.dart';
import '../edit_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../family/family_group_screen.dart';
import '../emergency/emergency_screen.dart';
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
  String? selectedPUVType = 'Bus';
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
    if (selectedPUVType == null) {
      return [];
    }
    return _availableRoutes
        .where(
          (route) =>
              route.puvType.toLowerCase() == selectedPUVType!.toLowerCase(),
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

        // Debug: Print search results information
        if (results.isNotEmpty) {
          print('Search results found: ${results.length}');
          print('First result: ${results[0]}');

          // Check if the results have the expected structure
          final mainText =
              results[0]['structured_formatting']?['main_text'] ??
              results[0]['description'] ??
              'Unknown location';
          final secondaryText =
              results[0]['structured_formatting']?['secondary_text'] ?? '';

          print('Main text: $mainText');
          print('Secondary text: $secondaryText');
        } else {
          print('No search results found for query: $query');
        }

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
        _googlePlacesResults = []; // Clear results after selection
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

  // Helper method to build a route card (more compact)
  Widget _buildRouteCard(PUVRoute route, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          _displayRoute(route);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 140, // Reduced width
          padding: const EdgeInsets.all(8), // Reduced padding
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Color(route.colorValue).withAlpha(75)
                    : Colors.white.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border:
                isSelected
                    ? Border.all(color: Color(route.colorValue), width: 1.5)
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
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Color(route.colorValue),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      route.routeCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '₱${route.farePrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  '${route.startPointName} to ${route.endPointName}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.white70,
                    size: 10,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '~${route.estimatedTravelTime} min',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
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

  // Get PUV type icon as a widget
  Future<Widget> _getPuvTypeIcon(String puvType, bool isSelected) async {
    try {
      // Since we can't directly convert BitmapDescriptor to Image widget,
      // we'll use the asset path directly
      String iconPath;
      switch (puvType.toLowerCase()) {
        case 'bus':
          iconPath = 'assets/icons/bus.png';
          break;
        case 'jeepney':
          iconPath = 'assets/icons/jeepney.png';
          break;
        case 'multicab':
          iconPath = 'assets/icons/multicab.png';
          break;
        case 'motorela':
          iconPath = 'assets/icons/motorela.png';
          break;
        default:
          // Fallback to icon if no matching asset
          return Icon(
            _getFallbackIconForPuvType(puvType),
            color: isSelected ? Colors.white : Colors.white70,
            size: 24,
          );
      }

      // Use Image.asset directly
      return Image.asset(
        iconPath,
        width: 24,
        height: 24,
        color: isSelected ? Colors.white : Colors.white70,
      );
    } catch (e) {
      // Fallback to icon if there's an error
      return Icon(
        _getFallbackIconForPuvType(puvType),
        color: isSelected ? Colors.white : Colors.white70,
        size: 24,
      );
    }
  }

  // Get fallback icon for PUV type
  IconData _getFallbackIconForPuvType(String type) {
    switch (type.toLowerCase()) {
      case 'bus':
        return Icons.directions_bus;
      case 'jeepney':
        return Icons.airport_shuttle;
      case 'multicab':
        return Icons.local_shipping;
      case 'motorela':
        return Icons.motorcycle;
      default:
        return Icons.directions_car;
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
                  // Header with role indicator (more compact)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.menu, color: Colors.white, size: 22),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          onPressed: _toggleDrawer,
                        ),
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withAlpha(50),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  UserRole.commuter.icon,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Commuter Mode',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 22,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
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

                  // Destination Search (more compact)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Container(
                      key: _searchBarKey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withAlpha(100),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_searching,
                                color: Colors.amber,
                                size: 20,
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
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
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
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
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
                              margin: const EdgeInsets.only(top: 4),
                              height: 2,
                              child: const LinearProgressIndicator(
                                color: Colors.amber,
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // PUV Type Selection (more compact)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0),
                          child: Text(
                            'Select PUV Type',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          height: 80, // Increased height
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                                  puvCounts.entries.map((entry) {
                                    bool isSelected =
                                        selectedPUVType == entry.key;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: SizedBox(
                                        width:
                                            80, // Fixed width for consistent sizing
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              // Toggle selection if the same type is clicked again
                                              if (selectedPUVType ==
                                                  entry.key) {
                                                selectedPUVType = null;
                                              } else {
                                                selectedPUVType = entry.key;
                                              }

                                              // Clear any selected route when changing PUV type
                                              _selectedRoute = null;
                                              if (_mapKey.currentState !=
                                                  null) {
                                                _mapKey.currentState!
                                                    .clearRoutes(
                                                      clearUserRoute: false,
                                                      clearPUVRoute: true,
                                                    );

                                                // Start tracking drivers with the selected PUV type
                                                _mapKey.currentState!
                                                    .startTrackingDrivers(
                                                      selectedPUVType,
                                                    );
                                              }
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                isSelected
                                                    ? Colors.amber
                                                    : Colors.white.withAlpha(
                                                      25,
                                                    ),
                                            padding:
                                                EdgeInsets
                                                    .zero, // Remove padding
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                // Icon
                                                FutureBuilder<Widget>(
                                                  future: _getPuvTypeIcon(
                                                    entry.key,
                                                    isSelected,
                                                  ),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color:
                                                              isSelected
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .white70,
                                                        ),
                                                      );
                                                    }
                                                    return snapshot.data ??
                                                        Icon(
                                                          _getFallbackIconForPuvType(
                                                            entry.key,
                                                          ),
                                                          color:
                                                              isSelected
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .white70,
                                                          size: 24,
                                                        );
                                                  },
                                                ),
                                                const SizedBox(height: 4),
                                                // PUV Type Name
                                                Text(
                                                  entry.key,
                                                  style: TextStyle(
                                                    color:
                                                        isSelected
                                                            ? Colors.white
                                                            : Colors.white70,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                // Available count - smaller and more subtle
                                                Text(
                                                  '${entry.value}',
                                                  style: TextStyle(
                                                    color:
                                                        isSelected
                                                            ? Colors.white70
                                                            : Colors.white54,
                                                    fontSize: 10,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
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
                  const SizedBox(height: 8),

                  // Available Routes Section (more compact)
                  if (selectedPUVType != null && routes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 4.0,
                              right: 4.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Available Routes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_selectedRoute != null)
                                  GestureDetector(
                                    onTap: _clearRoute,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.clear,
                                          color: Colors.white70,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 2),
                                        const Text(
                                          'Clear',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 90, // Reduced height
                            width: double.infinity,
                            child:
                                _isLoadingRoutes
                                    ? const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.amber,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : ListView.builder(
                                      scrollDirection: Axis.horizontal,
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
                        ],
                      ),
                    ),

                  // Map Widget (expanded to take more space)
                  Expanded(
                    child: Stack(
                      children: [
                        // Map with rounded corners
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
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

                        // Map refresher button
                        MapRefresherWidget(
                          mapKey: _mapKey,
                          position: MapRefresherPosition.topRight,
                        ),

                        // Privacy toggle button (positioned at the top left of the map)
                        Positioned(
                          left: 12,
                          top: 12,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    _isLocationVisibleToDrivers
                                        ? Colors.green.withAlpha(230)
                                        : Colors.red.withAlpha(230),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Tooltip(
                                message:
                                    _isLocationVisibleToDrivers
                                        ? 'Your location is visible to drivers'
                                        : 'Your location is hidden from drivers',
                                child: InkWell(
                                  onTap: _toggleLocationVisibility,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isLocationVisibleToDrivers
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: Colors.white,
                                          size: 16,
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
                child: Container(color: Colors.black.withAlpha(75)),
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
                            color: Colors.amber.withAlpha(75),
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
                                color: Colors.amber.withAlpha(50),
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
                                  // Family Group option
                                  _buildDrawerItem(
                                    icon: Icons.family_restroom,
                                    title: 'Family Group',
                                    onTap: () {
                                      _toggleDrawer();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const FamilyGroupScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  // Emergency option
                                  _buildDrawerItem(
                                    icon: Icons.emergency,
                                    title: 'Emergency',
                                    onTap: () {
                                      _toggleDrawer();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const EmergencyScreen(),
                                        ),
                                      );
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

          // Enhanced Suggestions Overlay with improved visibility and contrast
          if (_isSearching && _googlePlacesResults.isNotEmpty)
            Positioned(
              top: 190, // Increased to avoid overlapping search bar
              left: 16,
              right: 16,
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(12),
                color: Color.fromARGB(
                  255,
                  43,
                  42,
                  42,
                ), // Dark gray to match search bar
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber, width: 2),
                    // Add a subtle shadow for depth
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 5.0,
                        spreadRadius: 1.0,
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with title
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.black),
                            SizedBox(width: 8),
                            Text(
                              'Suggested Locations',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // List of search results
                      Flexible(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _googlePlacesResults.length,
                          separatorBuilder:
                              (context, index) => Divider(
                                height: 1,
                                color:
                                    Colors
                                        .grey
                                        .shade800, // Darker divider for dark theme
                                indent: 56,
                              ),
                          itemBuilder: (context, index) {
                            final place = _googlePlacesResults[index];
                            final mainText =
                                place['structured_formatting']?['main_text'] ??
                                place['description'] ??
                                'Unknown location';
                            final secondaryText =
                                place['structured_formatting']?['secondary_text'] ??
                                '';

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _selectPlace(place);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 12.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withAlpha(50),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.location_on,
                                            color: Colors.amber.shade700,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              mainText,
                                              style: TextStyle(
                                                color:
                                                    Colors
                                                        .white, // Changed to white for dark theme
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (secondaryText.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4.0,
                                                ),
                                                child: Text(
                                                  secondaryText,
                                                  style: TextStyle(
                                                    color:
                                                        Colors
                                                            .grey
                                                            .shade300, // Lighter gray for dark theme
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
