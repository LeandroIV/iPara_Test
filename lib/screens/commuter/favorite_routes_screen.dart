import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/route_model.dart';
import '../../services/route_service.dart';

class FavoriteRoutesScreen extends StatefulWidget {
  const FavoriteRoutesScreen({super.key});

  @override
  State<FavoriteRoutesScreen> createState() => _FavoriteRoutesScreenState();
}

class _FavoriteRoutesScreenState extends State<FavoriteRoutesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RouteService _routeService = RouteService();
  
  bool _isLoading = true;
  List<PUVRoute> _favoriteRoutes = [];
  List<String> _favoriteRouteIds = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteRoutes();
  }

  Future<void> _loadFavoriteRoutes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      
      if (userId != null) {
        // First, try to get the user's favorite route IDs from Firestore
        final userDoc = await _firestore.collection('users').doc(userId).get();
        
        if (userDoc.exists && userDoc.data()!.containsKey('favoriteRoutes')) {
          _favoriteRouteIds = List<String>.from(userDoc.data()!['favoriteRoutes']);
        } else {
          // If no favorites exist yet, use mock data
          _favoriteRouteIds = ['r2', 'r3', 'BLUE'];
          
          // Save mock favorites to Firestore for future use
          await _firestore.collection('users').doc(userId).set({
            'favoriteRoutes': _favoriteRouteIds
          }, SetOptions(merge: true));
        }
        
        // Now get the actual route details for each favorite route ID
        final allRoutes = await _routeService.getAllRoutes();
        
        _favoriteRoutes = allRoutes
            .where((route) => _favoriteRouteIds.contains(route.id))
            .toList();
            
        // If we couldn't find any routes, use mock data
        if (_favoriteRoutes.isEmpty) {
          _favoriteRoutes = _routeService.getMockRoutes()
              .where((route) => _favoriteRouteIds.contains(route.id))
              .toList();
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading favorite routes: $e');
      setState(() {
        _isLoading = false;
        // Use mock data as fallback
        _favoriteRoutes = _routeService.getMockRoutes().take(3).toList();
      });
    }
  }

  Future<void> _removeFromFavorites(PUVRoute route) async {
    setState(() {
      _favoriteRoutes.removeWhere((r) => r.id == route.id);
      _favoriteRouteIds.remove(route.id);
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'favoriteRoutes': _favoriteRouteIds
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${route.routeCode} removed from favorites'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () => _addToFavorites(route),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
    }
  }

  Future<void> _addToFavorites(PUVRoute route) async {
    setState(() {
      if (!_favoriteRoutes.any((r) => r.id == route.id)) {
        _favoriteRoutes.add(route);
        _favoriteRouteIds.add(route.id);
      }
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'favoriteRoutes': _favoriteRouteIds
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${route.routeCode} added to favorites'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Routes'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _favoriteRoutes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      const Text(
                        'No favorite routes yet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add routes to your favorites for quick access',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favoriteRoutes.length,
                  itemBuilder: (context, index) {
                    final route = _favoriteRoutes[index];
                    return _buildRouteCard(route);
                  },
                ),
    );
  }

  Widget _buildRouteCard(PUVRoute route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to route details or show on map
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
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
                  const SizedBox(width: 8),
                  Text(
                    route.puvType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () => _removeFromFavorites(route),
                    tooltip: 'Remove from favorites',
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                route.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.circle, color: Colors.green, size: 12),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      route.startPointName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 5),
                child: SizedBox(
                  height: 20,
                  child: VerticalDivider(
                    color: Colors.grey,
                    thickness: 1,
                    width: 20,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 12),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      route.endPointName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '~${route.estimatedTravelTime} min',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₱${route.farePrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
