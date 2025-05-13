import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DriverTripHistoryScreen extends StatefulWidget {
  const DriverTripHistoryScreen({super.key});

  @override
  State<DriverTripHistoryScreen> createState() =>
      _DriverTripHistoryScreenState();
}

class _DriverTripHistoryScreenState extends State<DriverTripHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _trips = [];

  // For filtering
  String _selectedFilter = 'All';
  final List<String> _filterOptions = [
    'All',
    'Today',
    'This Week',
    'This Month',
  ];

  // For summary stats
  double _totalEarnings = 0;
  int _totalTrips = 0;
  double _averageRating = 0;

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
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay

      final mockTrips = _getMockTripHistory();

      // Calculate summary statistics
      _calculateSummaryStats(mockTrips);

      setState(() {
        _trips = _filterTrips(mockTrips);
        _isLoading = false;
      });

      // Uncomment this code when you have a real driver_trips collection
      /*
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final querySnapshot = await _firestore
            .collection('driver_trips')
            .where('driverId', isEqualTo: userId)
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
            'earnings': data['earnings'] ?? 0.0,
            'passengerCount': data['passengerCount'] ?? 0,
            'rating': data['rating'] ?? 0.0,
            'puvType': data['puvType'] ?? 'Unknown',
            'distance': data['distance'] ?? 0.0,
          };
        }).toList();

        // Calculate summary statistics
        _calculateSummaryStats(trips);

        setState(() {
          _trips = _filterTrips(trips);
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

  void _calculateSummaryStats(List<Map<String, dynamic>> trips) {
    if (trips.isEmpty) {
      _totalEarnings = 0;
      _totalTrips = 0;
      _averageRating = 0;
      return;
    }

    _totalTrips = trips.length;
    _totalEarnings = trips.fold(
      0,
      (sum, trip) => sum + (trip['earnings'] as double),
    );

    final totalRating = trips.fold(
      0.0,
      (sum, trip) => sum + (trip['rating'] as double),
    );
    _averageRating = totalRating / _totalTrips;
  }

  List<Map<String, dynamic>> _filterTrips(List<Map<String, dynamic>> trips) {
    if (_selectedFilter == 'All') {
      return trips;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    return trips.where((trip) {
      final tripDate = (trip['timestamp'] as Timestamp).toDate();

      switch (_selectedFilter) {
        case 'Today':
          return tripDate.isAfter(today.subtract(const Duration(seconds: 1)));
        case 'This Week':
          return tripDate.isAfter(
            startOfWeek.subtract(const Duration(seconds: 1)),
          );
        case 'This Month':
          return tripDate.isAfter(
            startOfMonth.subtract(const Duration(seconds: 1)),
          );
        default:
          return true;
      }
    }).toList();
  }

  List<Map<String, dynamic>> _getMockTripHistory() {
    // Create some mock trip history data for a driver
    return [
      {
        'id': '1',
        'routeCode': 'R2',
        'startPoint': 'Carmen',
        'endPoint': 'Divisoria',
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 2)),
        ),
        'earnings': 450.0,
        'passengerCount': 15,
        'rating': 4.8,
        'puvType': 'Jeepney',
        'distance': 8.5,
      },
      {
        'id': '2',
        'routeCode': 'R2',
        'startPoint': 'Divisoria',
        'endPoint': 'Carmen',
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 5)),
        ),
        'earnings': 380.0,
        'passengerCount': 12,
        'rating': 4.5,
        'puvType': 'Jeepney',
        'distance': 8.5,
      },
      {
        'id': '3',
        'routeCode': 'R2',
        'startPoint': 'Carmen',
        'endPoint': 'Divisoria',
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
        'earnings': 520.0,
        'passengerCount': 18,
        'rating': 4.9,
        'puvType': 'Jeepney',
        'distance': 8.5,
      },
      {
        'id': '4',
        'routeCode': 'R2',
        'startPoint': 'Divisoria',
        'endPoint': 'Carmen',
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        ),
        'earnings': 410.0,
        'passengerCount': 14,
        'rating': 4.7,
        'puvType': 'Jeepney',
        'distance': 8.5,
      },
      {
        'id': '5',
        'routeCode': 'R2',
        'startPoint': 'Carmen',
        'endPoint': 'Divisoria',
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 2)),
        ),
        'earnings': 480.0,
        'passengerCount': 16,
        'rating': 4.6,
        'puvType': 'Jeepney',
        'distance': 8.5,
      },
    ];
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MMM d, yyyy - h:mm a').format(date);
  }

  String _formatShortDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MMM d - h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.blue,
      ),
      backgroundColor: Colors.black,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              )
              : Column(
                children: [
                  // Summary cards
                  _buildSummaryCards(),

                  // Filter options
                  _buildFilterOptions(),

                  // Trip list
                  Expanded(
                    child:
                        _trips.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 64,
                                    color: Colors.grey[700],
                                  ),
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
                  ),
                ],
              ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          _buildSummaryCard(
            title: 'Total Earnings',
            value: '₱${_totalEarnings.toStringAsFixed(0)}',
            icon: Icons.monetization_on,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            title: 'Total Trips',
            value: _totalTrips.toString(),
            icon: Icons.route,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            title: 'Avg. Rating',
            value: _averageRating.toStringAsFixed(1),
            icon: Icons.star,
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              _filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.grey[300],
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.blue,
                    backgroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                          _trips = _filterTrips(_getMockTripHistory());
                        });
                      }
                    },
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trip['routeCode'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${trip['passengerCount']} passengers',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '₱${trip['earnings'].toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.circle, color: Colors.green, size: 10),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trip['startPoint'],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: SizedBox(
                height: 16,
                child: VerticalDivider(
                  color: Colors.grey,
                  thickness: 1,
                  width: 18,
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 10),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trip['endPoint'],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _formatShortDate(trip['timestamp']),
                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      trip['rating'].toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
