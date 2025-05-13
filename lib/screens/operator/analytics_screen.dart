import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Using a mock implementation of fl_chart to avoid errors
import '../../mocks/fl_chart_mock.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // Removed unused fields: _firestore and _auth
  bool _isLoading = true;

  // Analytics data
  int _totalTrips = 0;
  int _totalPassengers = 0;
  double _averageRating = 0;

  // Chart data
  List<FlSpot?> _tripsSpots = [];
  List<FlSpot?> _passengersSpots = [];
  double _maxY = 100; // Default max value for chart

  // Filter
  String _selectedPeriod = 'Week';
  final List<String> _periodOptions = ['Week', 'Month'];

  // Route performance
  List<Map<String, dynamic>> _routePerformance = [];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For now, we'll use mock data
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay

      // Generate mock data
      _generateMockAnalyticsData();

      setState(() {
        _isLoading = false;
      });

      // Uncomment this code when you have a real analytics collection
      /*
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Get analytics data from Firestore
        // ...

        setState(() {
          _isLoading = false;
        });
      }
      */
    } catch (e) {
      debugPrint('Error loading analytics data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateMockAnalyticsData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Generate daily analytics data for the past 30 days
    final List<Map<String, dynamic>> dailyAnalytics = [];

    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));

      // Generate random trips between 20 and 40
      final trips = 20 + (20 * (date.day % 7) / 7).round();

      // Generate random passengers between 200 and 400
      final passengers = trips * (10 + (10 * (date.day % 5) / 5).round());

      // Generate random rating between 4.0 and 5.0
      final rating = 4.0 + (1.0 * (date.day % 10) / 10);

      dailyAnalytics.add({
        'date': date,
        'trips': trips,
        'passengers': passengers,
        'rating': rating,
      });
    }

    // Calculate totals
    _totalTrips = dailyAnalytics.fold(
      0,
      (accumulator, item) => accumulator + (item['trips'] as int),
    );
    _totalPassengers = dailyAnalytics.fold(
      0,
      (accumulator, item) => accumulator + (item['passengers'] as int),
    );

    final totalRating = dailyAnalytics.fold(
      0.0,
      (accumulator, item) => accumulator + (item['rating'] as double),
    );
    _averageRating = totalRating / dailyAnalytics.length;

    // Generate chart data based on selected period
    _generateChartData(dailyAnalytics);

    // Generate route performance data
    _generateRoutePerformanceData();
  }

  void _generateChartData(List<Map<String, dynamic>> dailyAnalytics) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_selectedPeriod == 'Week') {
      // Last 7 days
      _tripsSpots = [];
      _passengersSpots = [];

      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dayData = dailyAnalytics.firstWhere(
          (item) => (item['date'] as DateTime).day == date.day,
          orElse: () => {'trips': 0, 'passengers': 0},
        );

        _tripsSpots.add(
          FlSpot((6 - i).toDouble(), (dayData['trips'] as int).toDouble()),
        );
        _passengersSpots.add(
          FlSpot(
            (6 - i).toDouble(),
            (dayData['passengers'] as int).toDouble() / 10,
          ),
        ); // Scale down for chart
      }
    } else {
      // Last 30 days
      _tripsSpots = [];
      _passengersSpots = [];

      for (int i = 29; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dayData = dailyAnalytics.firstWhere(
          (item) => (item['date'] as DateTime).day == date.day,
          orElse: () => {'trips': 0, 'passengers': 0},
        );

        _tripsSpots.add(
          FlSpot((29 - i).toDouble(), (dayData['trips'] as int).toDouble()),
        );
        _passengersSpots.add(
          FlSpot(
            (29 - i).toDouble(),
            (dayData['passengers'] as int).toDouble() / 10,
          ),
        ); // Scale down for chart
      }
    }

    // Find max value for chart
    final allValues = [
      ..._tripsSpots.map((spot) => spot?.y ?? 0),
      ..._passengersSpots.map((spot) => spot?.y ?? 0),
    ];
    if (allValues.isNotEmpty) {
      _maxY = allValues.reduce((a, b) => a > b ? a : b) * 1.2;
    }
  }

  void _generateRoutePerformanceData() {
    // Generate mock route performance data
    _routePerformance = [
      {
        'routeCode': 'R2',
        'routeName': 'Carmen to Divisoria',
        'trips': 120,
        'passengers': 1450,
        'revenue': 17400.0,
        'rating': 4.8,
      },
      {
        'routeCode': 'R3',
        'routeName': 'Bulua to Divisoria',
        'trips': 105,
        'passengers': 1260,
        'revenue': 15120.0,
        'rating': 4.6,
      },
      {
        'routeCode': 'R4',
        'routeName': 'Bugo to Lapasan',
        'trips': 90,
        'passengers': 1080,
        'revenue': 12960.0,
        'rating': 4.7,
      },
      {
        'routeCode': 'R7',
        'routeName': 'Balulang to Divisoria',
        'trips': 75,
        'passengers': 900,
        'revenue': 10800.0,
        'rating': 4.5,
      },
      {
        'routeCode': 'R10',
        'routeName': 'Canitoan to Cogon',
        'trips': 60,
        'passengers': 720,
        'revenue': 8640.0,
        'rating': 4.9,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
      ),
      backgroundColor: Colors.black,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Analytics summary cards
                    _buildAnalyticsSummary(),

                    const SizedBox(height: 24),

                    // Performance Trends title
                    Text(
                      'Performance Trends',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Chart period selector
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 45,
                        child: SegmentedButton<String>(
                          segments:
                              _periodOptions
                                  .map(
                                    (period) => ButtonSegment<String>(
                                      value: period,
                                      label: Text(
                                        period,
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          selected: {_selectedPeriod},
                          onSelectionChanged: (Set<String> selection) {
                            setState(() {
                              _selectedPeriod = selection.first;
                              // Regenerate chart data
                              _loadAnalyticsData();
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.resolveWith<Color>((
                                  Set<WidgetState> states,
                                ) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.amber;
                                  }
                                  return Colors.grey[800]!;
                                }),
                            foregroundColor:
                                WidgetStateProperty.resolveWith<Color>((
                                  Set<WidgetState> states,
                                ) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.black;
                                  }
                                  return Colors.grey[400]!;
                                }),
                            padding: WidgetStateProperty.all<
                              EdgeInsetsGeometry
                            >(EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Performance chart
                    _buildPerformanceChart(),

                    const SizedBox(height: 24),

                    // Route performance
                    Text(
                      'Route Performance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Route performance list
                    _buildRoutePerformanceList(),
                  ],
                ),
              ),
    );
  }

  Widget _buildAnalyticsSummary() {
    return Row(
      children: [
        _buildAnalyticsCard(
          'Total Trips',
          _totalTrips.toString(),
          Icons.route,
          Colors.blue,
        ),
        const SizedBox(width: 16),
        _buildAnalyticsCard(
          'Total Passengers',
          _totalPassengers.toString(),
          Icons.people,
          Colors.green,
        ),
        const SizedBox(width: 16),
        _buildAnalyticsCard(
          'Average Rating',
          _averageRating.toStringAsFixed(1),
          Icons.star,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withAlpha(77),
          ), // 0.3 * 255 = 76.5 ≈ 77
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
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
                style: TextStyle(
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

  Widget _buildPerformanceChart() {
    final days = _selectedPeriod == 'Week' ? 7 : 30;

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Chart legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Trips', Colors.blue),
              const SizedBox(width: 24),
              _buildLegendItem('Passengers (x10)', Colors.green),
            ],
          ),

          const SizedBox(height: 16),

          // Chart
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[800], strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _selectedPeriod == 'Week' ? 1 : 5,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0) return const Text('');

                        final now = DateTime.now();
                        final date = now.subtract(
                          Duration(days: (days - 1 - value.toInt()).toInt()),
                        );

                        if (_selectedPeriod == 'Week') {
                          return Text(
                            DateFormat('E').format(date),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                            ),
                          );
                        } else {
                          return Text(
                            DateFormat('d').format(date),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: days - 1.0,
                minY: 0,
                maxY: _maxY,
                lineBarsData: [
                  // Trips line
                  LineChartBarData(
                    spots: _tripsSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
                    ),
                  ),
                  // Passengers line
                  LineChartBarData(
                    spots: _passengersSpots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withAlpha(
                        26,
                      ), // 0.1 * 255 = 25.5 ≈ 26
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }

  Widget _buildRoutePerformanceList() {
    return Column(
      children:
          _routePerformance
              .map((route) => _buildRoutePerformanceItem(route))
              .toList(),
    );
  }

  Widget _buildRoutePerformanceItem(Map<String, dynamic> route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  route['routeCode'],
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  route['routeName'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    route['rating'].toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRouteStatItem(
                Icons.route,
                'Trips',
                route['trips'].toString(),
              ),
              _buildRouteStatItem(
                Icons.people,
                'Passengers',
                route['passengers'].toString(),
              ),
              _buildRouteStatItem(
                Icons.monetization_on,
                'Revenue',
                '₱${route['revenue'].toStringAsFixed(0)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 14),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
