import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/user_role.dart';
import '../../services/user_service.dart';
import '../../widgets/home_map_widget.dart';
import '../../services/route_service.dart';
import '../../models/route_model.dart';
import '../../services/ride_request_service.dart';
import '../../models/ride_request_model.dart';
import '../../services/location_service.dart';
import '../edit_profile_screen.dart';
import '../notification_settings_screen.dart';
import '../settings/settings_screen.dart';
import '../family/family_group_screen.dart';
import '../emergency/emergency_screen.dart';
import '../help_support_screen.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vehicle_maintenance_screen.dart';
import 'driver_trip_history_screen.dart';
import 'driver_routes_screen.dart';
import 'driver_earnings_screen.dart';
import 'driver_ride_requests_screen.dart';
import 'active_ride_screen.dart';
import '../commuter/notifications_screen.dart';
import '../../widgets/ride_request_floating_window.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with SingleTickerProviderStateMixin {
  bool isDrawerOpen = false;
  late AnimationController _drawerController;
  late Animation<double> _drawerAnimation;
  final GlobalKey<HomeMapWidgetState> _mapKey = GlobalKey<HomeMapWidgetState>();
  bool _isOnline = true;

  // Add location visibility toggle
  bool _isLocationVisibleToCommuters = true;

  // Add route service
  final RouteService _routeService = RouteService();
  List<PUVRoute> _availableRoutes = [];
  bool _isLoadingRoutes = false;
  PUVRoute? _selectedRoute;
  String selectedPUVType = 'Jeepney';

  // Add ride request service
  final RideRequestService _rideRequestService = RideRequestService();
  List<RideRequest> _pendingRideRequests = [];
  StreamSubscription<List<RideRequest>>? _rideRequestsSubscription;

  // Add route panel minimized state
  bool _isRoutePanelMinimized = false;

  // Add text controller for destination search
  final TextEditingController _destinationController = TextEditingController();
  bool _isSearching = false;
  List<dynamic> _googlePlacesResults = [];
  bool _isLoadingPlaces = false;
  Timer? _debounceTimer;

  // Placeholder data for PUV counts
  final Map<String, int> puvCounts = {
    'Bus': 9, // Updated to include R3 route
    'Jeepney': 44,
    'Multicab': 16, // Updated to include RB route
    'Motorela': 11, // Updated to include BLUE route
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

    // Listen for ride requests
    _listenForRideRequests();

    // Initialize location service
    _initializeLocationService();
  }

  // Initialize the location service
  Future<void> _initializeLocationService() async {
    try {
      final locationService = LocationService();
      final firestore = FirebaseFirestore.instance;
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        debugPrint(
          'Cannot initialize location service: User not authenticated',
        );
        return;
      }

      // Get the user role from Firestore directly
      try {
        final userDoc = await firestore.collection('users').doc(userId).get();
        if (userDoc.exists && userDoc.data()?['role'] != null) {
          final roleIndex = userDoc.data()?['role'] as int;
          String roleFromFirestore = '';

          // Convert role index to string
          switch (roleIndex) {
            case 0:
              roleFromFirestore = 'commuter';
              break;
            case 1:
              roleFromFirestore = 'driver';
              break;
            case 2:
              roleFromFirestore = 'operator';
              break;
            default:
              roleFromFirestore = 'commuter';
          }

          if (roleFromFirestore != 'driver') {
            debugPrint(
              'Warning: User role in Firestore is not driver: $roleFromFirestore',
            );
            debugPrint('Updating user role in Firestore to driver');

            // Update the user role in Firestore to driver
            await firestore.collection('users').doc(userId).update({
              'role': UserRole.driver.index,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            debugPrint('User role updated to driver in Firestore');
          } else {
            debugPrint('User role in Firestore is already driver');
          }
        } else {
          debugPrint('User document not found or role not set, creating it');

          // Create the user document with driver role
          await firestore.collection('users').doc(userId).set({
            'role': UserRole.driver.index,
            'displayName':
                FirebaseAuth.instance.currentUser?.displayName ?? 'Driver',
            'email': FirebaseAuth.instance.currentUser?.email,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          debugPrint('User document created with driver role');
        }
      } catch (e) {
        debugPrint('Error checking/updating user role in Firestore: $e');
      }

      // Initialize with driver role
      await locationService.initialize('driver');

      // If online by default, start location tracking
      if (_isOnline) {
        await locationService.startLocationTracking(
          isVisible: _isLocationVisibleToCommuters,
        );
        await locationService.updateSelectedPuvType(selectedPUVType);
        debugPrint('Started location tracking with PUV type: $selectedPUVType');
      }
    } catch (e) {
      debugPrint('Error initializing location service: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing location service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Load routes from service (using Firestore data)
  Future<void> _loadRoutes() async {
    setState(() {
      _isLoadingRoutes = true;
    });

    try {
      // Use Firestore data instead of mock data
      _availableRoutes = await _routeService.getAllRoutes();
      debugPrint(
        'Loaded routes from Firestore: ${_availableRoutes.map((r) => r.routeCode).join(', ')}',
      );

      // Fallback to mock data if no routes found in Firestore
      if (_availableRoutes.isEmpty) {
        debugPrint('No routes found in Firestore, using mock data as fallback');
        _availableRoutes = _routeService.getMockRoutes();
      }
    } catch (e) {
      debugPrint('Error loading routes: $e');
      // Fallback to mock data on error
      _availableRoutes = _routeService.getMockRoutes();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoutes = false;
        });
      }
    }
  }

  // Filter routes based on selected PUV type with custom sorting
  List<PUVRoute> get filteredRoutes {
    // Filter routes by PUV type
    final routes =
        _availableRoutes
            .where(
              (route) =>
                  route.puvType.toLowerCase() == selectedPUVType.toLowerCase(),
            )
            .toList();

    // Custom sorting logic to ensure specific route order
    routes.sort((a, b) {
      // Special case: If one is RD and the other is LA, RD comes first
      if (a.routeCode == 'RD' && b.routeCode == 'LA') return -1;
      if (a.routeCode == 'LA' && b.routeCode == 'RD') return 1;

      // For all other routes, sort alphabetically by routeCode
      return a.routeCode.compareTo(b.routeCode);
    });

    return routes;
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
    _rideRequestsSubscription?.cancel();
    super.dispose();
  }

  // Listen for ride requests
  void _listenForRideRequests() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _rideRequestsSubscription = _rideRequestService.driverRequests.listen((
      requests,
    ) {
      // Filter for pending requests only
      final pendingRequests =
          requests
              .where((req) => req.status == RideRequestStatus.pending)
              .toList();

      setState(() {
        _pendingRideRequests = pendingRequests;
      });

      // Show notification for new requests
      if (pendingRequests.isNotEmpty) {
        _showRideRequestNotification(pendingRequests.first);
      }
    });
  }

  // Current active ride request
  RideRequest? _activeRideRequest;

  // Show notification for a new ride request
  void _showRideRequestNotification(RideRequest request) {
    if (!mounted) return;

    // Play notification sound or vibration here if needed

    // Show a snackbar notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'New ride request from ${request.commuterName ?? 'Commuter'}',
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );

    // Set the active ride request to show the floating window
    setState(() {
      _activeRideRequest = request;
    });
  }

  // Hide the ride request floating window
  void _hideRideRequestWindow() {
    setState(() {
      _activeRideRequest = null;
    });
  }

  // Respond to a ride request
  Future<void> _respondToRideRequest(
    RideRequest request,
    RideRequestStatus status,
  ) async {
    try {
      await _rideRequestService.updateRequestStatus(request.id, status);

      if (status == RideRequestStatus.accepted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You accepted the ride request from ${request.commuterName ?? 'Commuter'}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Navigate to the active ride screen
          final updatedRequest = await _rideRequestService.getRideRequest(
            request.id,
          );
          if (updatedRequest != null && mounted) {
            final ctx = context;
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder:
                    (context) =>
                        DriverActiveRideScreen(rideRequest: updatedRequest),
              ),
            ).then((_) {
              // Clear the route when returning from the active ride screen
              _clearRoute();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error responding to ride request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to respond to ride request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add search places method
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
      debugPrint('Error searching places: $e');
      setState(() {
        _googlePlacesResults = [];
        _isLoadingPlaces = false;
      });
    }
  }

  // Add select place method
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

  // This method has been replaced with inline code in the ListView.builder

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

  // Add sign out method
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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

  // Toggle location visibility to commuters
  void _toggleLocationVisibility() {
    setState(() {
      _isLocationVisibleToCommuters = !_isLocationVisibleToCommuters;
    });

    // Explicitly refresh the map to show/hide the user location pin immediately
    if (_mapKey.currentState != null) {
      _mapKey.currentState!.updateUserLocationVisibility(
        _isLocationVisibleToCommuters,
      );
    }

    // Show confirmation message
    _showStatusSnackBar();
  }

  // Show status snackbar based on online status
  void _showStatusSnackBar() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isOnline
              ? 'You are now online and visible to commuters'
              : 'You are now offline and hidden from commuters',
        ),
        backgroundColor: _isOnline ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
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
                  // Compact header with role indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.menu, color: Colors.white),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          onPressed: _toggleDrawer,
                        ),
                        // Debug button (only visible in debug mode) - moved to drawer
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(50),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                UserRole.driver.icon,
                                color: Colors.blue,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Driver Mode',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.person, color: Colors.white),
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

                  // Compact Online Status Switch
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _isOnline
                                ? Colors.green.withAlpha(50)
                                : Colors.red.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isOnline
                                ? Icons.online_prediction
                                : Icons.offline_bolt,
                            color: _isOnline ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: _isOnline ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: _isOnline,
                              onChanged: (value) async {
                                setState(() {
                                  _isOnline = value;
                                  // Set location visibility based on online status
                                  _isLocationVisibleToCommuters = value;
                                });

                                // Import the location service
                                final locationService = LocationService();

                                // Start or stop location tracking based on online status
                                if (_isOnline) {
                                  // Start location tracking and update driver_locations in Firestore
                                  await locationService.startLocationTracking(
                                    isVisible: _isLocationVisibleToCommuters,
                                  );

                                  // Update the selected PUV type
                                  await locationService.updateSelectedPuvType(
                                    selectedPUVType,
                                  );

                                  // Debug print to verify the PUV type being passed
                                  debugPrint(
                                    'Starting to track commuters with PUV type: $selectedPUVType',
                                  );
                                } else {
                                  // Stop location tracking
                                  await locationService.stopLocationTracking();
                                  debugPrint(
                                    'Stopping location tracking (offline)',
                                  );
                                }

                                // Update map visibility
                                if (_mapKey.currentState != null) {
                                  _mapKey.currentState!
                                      .updateUserLocationVisibility(
                                        _isLocationVisibleToCommuters,
                                      );

                                  // Start or stop tracking commuters based on online status
                                  if (_isOnline) {
                                    _mapKey.currentState!
                                        .startTrackingCommuters(
                                          selectedPUVType,
                                        );
                                  } else {
                                    _mapKey.currentState!
                                        .startTrackingCommuters(null);
                                  }
                                }

                                // Show confirmation about location visibility
                                _showStatusSnackBar();
                              },
                              activeColor: Colors.green,
                              activeTrackColor: Colors.green.withAlpha(128),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // PUV Type Selection (Updated to match commuter mode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select PUV Type',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 62, // Further reduced height to fix overflow
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
                                      child: InkWell(
                                        onTap: () async {
                                          setState(() {
                                            selectedPUVType = entry.key;

                                            // Clear any selected route when changing PUV type
                                            _selectedRoute = null;
                                          });

                                          // Update the location service with the new PUV type
                                          if (_isOnline) {
                                            final locationService =
                                                LocationService();
                                            await locationService
                                                .updateSelectedPuvType(
                                                  selectedPUVType,
                                                );
                                            debugPrint(
                                              'Updated location service with PUV type: $selectedPUVType',
                                            );
                                          }

                                          if (_mapKey.currentState != null) {
                                            _mapKey.currentState!.clearRoutes();

                                            // Start tracking commuters with the selected PUV type
                                            if (_isOnline &&
                                                _isLocationVisibleToCommuters) {
                                              debugPrint(
                                                'PUV type changed, tracking commuters with: $selectedPUVType',
                                              );
                                              _mapKey.currentState!
                                                  .startTrackingCommuters(
                                                    selectedPUVType,
                                                  );
                                            }
                                          }
                                        },
                                        child: Container(
                                          width: 75, // Reduced width
                                          height: 60, // Further reduced height
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? Colors
                                                        .blue // Blue for selected item (driver mode)
                                                    : Colors
                                                        .grey[900], // Dark for unselected
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(
                                            4,
                                          ), // Reduced padding
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize:
                                                MainAxisSize
                                                    .min, // Ensure minimum size
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
                                                      ConnectionState.waiting) {
                                                    return SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                isSelected
                                                                    ? Colors
                                                                        .white
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
                                                                : Colors.white,
                                                        size: 18,
                                                      );
                                                },
                                              ),
                                              const SizedBox(
                                                height: 2,
                                              ), // Reduced spacing
                                              // PUV Type Name
                                              Text(
                                                entry.key,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      9, // Smaller font size
                                                ),
                                                textAlign: TextAlign.center,
                                                overflow:
                                                    TextOverflow
                                                        .ellipsis, // Prevent text overflow
                                              ),
                                              // Count
                                              Text(
                                                '${entry.value}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize:
                                                      9, // Smaller font size
                                                ),
                                                textAlign: TextAlign.center,
                                                overflow:
                                                    TextOverflow
                                                        .ellipsis, // Prevent text overflow
                                              ),
                                            ],
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
                  const SizedBox(height: 4),

                  // Available Routes Section (Updated to match commuter mode)
                  if (routes.isNotEmpty)
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
                                Row(
                                  children: [
                                    // Minimize/Expand button
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isRoutePanelMinimized =
                                              !_isRoutePanelMinimized;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Icon(
                                          _isRoutePanelMinimized
                                              ? Icons.chevron_right
                                              : Icons.chevron_left,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Available Routes',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                // Clear route button - only visible when a route is selected
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
                          const SizedBox(height: 8),
                          // Only show the routes list if not minimized
                          if (!_isRoutePanelMinimized)
                            SizedBox(
                              width: double.infinity,
                              height: 100, // Increased height to fix overflow
                              child:
                                  _isLoadingRoutes
                                      ? const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.blue,
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
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8.0,
                                            ),
                                            child: InkWell(
                                              onTap: () {
                                                _displayRoute(route);
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Container(
                                                width: 140,
                                                height:
                                                    95, // Fixed height to prevent overflow
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isSelected
                                                          ? Color(
                                                            route.colorValue,
                                                          ).withAlpha(75)
                                                          : Colors.grey[900],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border:
                                                      isSelected
                                                          ? Border.all(
                                                            color: Color(
                                                              route.colorValue,
                                                            ),
                                                            width: 1.5,
                                                          )
                                                          : null,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 4,
                                                                vertical: 2,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Color(
                                                              route.colorValue,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            route.routeCode,
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          '₱${route.farePrice.toStringAsFixed(0)}',
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${route.startPointName} to ${route.endPointName}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.access_time,
                                                          color: Colors.white70,
                                                          size: 10,
                                                        ),
                                                        const SizedBox(
                                                          width: 2,
                                                        ),
                                                        Text(
                                                          '${route.estimatedTravelTime}m',
                                                          style: const TextStyle(
                                                            color:
                                                                Colors.white70,
                                                            fontSize: 10,
                                                          ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ],
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

                  // Map Widget
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: HomeMapWidget(
                            key: _mapKey,
                            showUserLocation: _isLocationVisibleToCommuters,
                            onDestinationSelected: (destination) {
                              setState(() {
                                _destinationController.text = destination;
                              });
                            },
                          ),
                        ),

                        // Visibility button positioned to the left of the locator button
                        Positioned(
                          right:
                              70, // Positioned to the left of the locator button
                          top: 16,
                          child: FloatingActionButton.small(
                            heroTag: 'visibilityButton',
                            onPressed: _toggleLocationVisibility,
                            backgroundColor:
                                _isLocationVisibleToCommuters
                                    ? Colors.green.withAlpha(230)
                                    : Colors.red.withAlpha(230),
                            elevation: 4,
                            tooltip:
                                _isLocationVisibleToCommuters
                                    ? 'Your location is visible to commuters'
                                    : 'Your location is hidden from commuters',
                            child: Icon(
                              _isLocationVisibleToCommuters
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),

                        // Refresh button positioned below the locator button
                        Positioned(
                          right: 16,
                          top: 70, // Positioned below the locator button
                          child: FloatingActionButton.small(
                            heroTag: 'refreshButton',
                            onPressed: () {
                              if (_mapKey.currentState != null) {
                                _mapKey.currentState!.initializeLocation();
                              }
                            },
                            backgroundColor: Colors.white,
                            elevation: 4,
                            tooltip: 'Refresh map',
                            child: Icon(
                              Icons.refresh,
                              color: Colors.blue,
                              size: 16,
                            ),
                          ),
                        ),

                        // Ride request floating window
                        if (_activeRideRequest != null)
                          RideRequestFloatingWindow(
                            request: _activeRideRequest!,
                            onRespond: (request, status) {
                              _respondToRideRequest(request, status);

                              // If accepted, show directions to the commuter
                              if (status == RideRequestStatus.accepted &&
                                  _mapKey.currentState != null) {
                                _mapKey.currentState!.showDirectionsToLocation(
                                  request.commuterLocation,
                                  markerTitle:
                                      '${request.commuterName ?? 'Commuter'} (${request.distanceKm.toStringAsFixed(1)} km)',
                                );
                              }

                              // Hide the floating window
                              _hideRideRequestWindow();
                            },
                            onClose: _hideRideRequestWindow,
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
                child: Container(color: Colors.black.withAlpha(76)),
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
                            color: Colors.blue.withAlpha(76),
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
                                color: Colors.blue.withAlpha(51),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    child: Icon(
                                      UserRole.driver.icon,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Driver Mode',
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
                                            color: Colors.blue,
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
                                    icon: Icons.route,
                                    title: 'My Routes',
                                    onTap: () {
                                      _toggleDrawer();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const DriverRoutesScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.history,
                                    title: 'Trip History',
                                    onTap: () {
                                      _toggleDrawer();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const DriverTripHistoryScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.monetization_on,
                                    title: 'Earnings',
                                    onTap: () {
                                      _toggleDrawer();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const DriverEarningsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.directions_car,
                                    title: 'Ride Requests',
                                    onTap: () {
                                      _toggleDrawer();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const DriverRideRequestsScreen(),
                                        ),
                                      ).then((result) {
                                        // Clear any existing routes first
                                        _clearRoute();

                                        // If a ride request is returned, show directions to the commuter
                                        if (result != null &&
                                            result is RideRequest) {
                                          if (_mapKey.currentState != null) {
                                            _mapKey.currentState!
                                                .showDirectionsToLocation(
                                                  result.commuterLocation,
                                                  markerTitle:
                                                      '${result.commuterName ?? 'Commuter'} (${result.distanceKm.toStringAsFixed(1)} km)',
                                                );
                                          }
                                        }
                                      });
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.notifications,
                                    title: 'Notifications',
                                    onTap: () {
                                      _toggleDrawer();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const NotificationsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.build,
                                    title: 'Vehicle Maintenance',
                                    onTap: () {
                                      _toggleDrawer();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const VehicleMaintenanceScreen(),
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
                                  backgroundColor: Colors.blue,
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
      leading: Icon(icon, color: Color(0xFF2196F3), size: 24.0),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}
