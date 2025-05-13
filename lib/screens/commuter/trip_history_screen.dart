import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _trips = [];

  @override
  void initState() {
    super.initState();
    _loadTripHistory();
  }

  Future<void> _loadTripHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For now, we'll use mock data since the actual trip history collection might not exist yet
      // In a real implementation, you would fetch from Firestore
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      setState(() {
        _trips = _getMockTripHistory();
        _isLoading = false;
      });
      
      // Uncomment this code when you have a real trip_history collection
      /*
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final querySnapshot = await _firestore
            .collection('trip_history')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .get();
            
        final trips = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'routeCode': data['routeCode'] ?? 'Unknown',
            'startPoint': data['startPoint'] ?? 'Unknown',
            'endPoint': data['endPoint'] ?? 'Unknown',
            'timestamp': data['timestamp'] as Timestamp,
            'fare': data['fare'] ?? 0.0,
            'puvType': data['puvType'] ?? 'Unknown',
          };
        }).toList();
        
        setState(() {
          _trips = trips;
          _isLoading = false;
        });
      }
      */
    } catch (e) {
      debugPrint('Error loading trip history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getMockTripHistory() {
    // Create some mock trip history data
    return [
      {
        'id': '1',
        'routeCode': 'R2',
        'startPoint': 'Carmen',
        'endPoint': 'Divisoria',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
        'fare': 12.0,
        'puvType': 'Jeepney',
      },
      {
        'id': '2',
        'routeCode': 'R3',
        'startPoint': 'Bulua',
        'endPoint': 'Divisoria',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'fare': 15.0,
        'puvType': 'Bus',
      },
      {
        'id': '3',
        'routeCode': 'BLUE',
        'startPoint': 'Agora',
        'endPoint': 'Cogon',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
        'fare': 10.0,
        'puvType': 'Motorela',
      },
      {
        'id': '4',
        'routeCode': 'RB',
        'startPoint': 'Bugo',
        'endPoint': 'Divisoria',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
        'fare': 14.0,
        'puvType': 'Multicab',
      },
      {
        'id': '5',
        'routeCode': 'R2',
        'startPoint': 'Divisoria',
        'endPoint': 'Carmen',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 4))),
        'fare': 12.0,
        'puvType': 'Jeepney',
      },
    ];
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MMM d, yyyy - h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _trips.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      const Text(
                        'No trip history found',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your completed trips will appear here',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trips.length,
                  itemBuilder: (context, index) {
                    final trip = _trips[index];
                    return _buildTripCard(trip);
                  },
                ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    // Get icon based on PUV type
    IconData puvIcon;
    switch (trip['puvType']) {
      case 'Bus':
        puvIcon = Icons.directions_bus;
        break;
      case 'Jeepney':
        puvIcon = Icons.airport_shuttle;
        break;
      case 'Multicab':
        puvIcon = Icons.local_taxi;
        break;
      case 'Motorela':
        puvIcon = Icons.electric_rickshaw;
        break;
      default:
        puvIcon = Icons.directions_car;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trip['routeCode'],
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(puvIcon, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  trip['puvType'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '₱${trip['fare'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.circle, color: Colors.green, size: 12),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trip['startPoint'],
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
                    trip['endPoint'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _formatDate(trip['timestamp']),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
