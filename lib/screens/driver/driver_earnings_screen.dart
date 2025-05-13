import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Using a mock implementation of fl_chart to avoid errors
import '../../mocks/fl_chart_mock.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  // Removed unused fields: _firestore and _auth
  bool _isLoading = true;

  // Earnings data
  double _totalEarnings = 0;
  double _todayEarnings = 0;
  double _weekEarnings = 0;
  double _monthEarnings = 0;

  // Chart data
  List<FlSpot> _weeklySpots = [];
  List<FlSpot> _monthlySpots = [];
  double _maxY = 1000; // Default max value for chart

  // Filter
  String _selectedPeriod = 'Week';
  final List<String> _periodOptions = ['Week', 'Month'];

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  Future<void> _loadEarningsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For now, we'll use mock data
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay

      // Generate mock data
      _generateMockEarningsData();

      setState(() {
        _isLoading = false;
      });

      // Uncomment this code when you have a real earnings collection
      /*
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Get all driver trips
        final querySnapshot = await _firestore
            .collection('driver_trips')
            .where('driverId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .get();

        final trips = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'earnings': data['earnings'] ?? 0.0,
            'timestamp': data['timestamp'] as Timestamp,
          };
        }).toList();

        // Calculate earnings
        _calculateEarnings(trips);

        setState(() {
          _isLoading = false;
        });
      }
      */
    } catch (e) {
      debugPrint('Error loading earnings data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateMockEarningsData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Generate daily earnings for the past 30 days
    final List<Map<String, dynamic>> dailyEarnings = [];

    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));

      // Generate random earnings between 300 and 800
      final earnings = 300.0 + (500.0 * (date.day % 7) / 7);

      dailyEarnings.add({'date': date, 'earnings': earnings});
    }

    // Calculate total earnings
    _totalEarnings = dailyEarnings.fold(
      0,
      (accumulator, item) => accumulator + (item['earnings'] as double),
    );

    // Calculate today's earnings
    final todayData = dailyEarnings.firstWhere(
      (item) => (item['date'] as DateTime).day == today.day,
      orElse: () => {'earnings': 0.0},
    );
    _todayEarnings = todayData['earnings'] as double;

    // Calculate this week's earnings
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    _weekEarnings = dailyEarnings
        .where(
          (item) => (item['date'] as DateTime).isAfter(
            startOfWeek.subtract(const Duration(days: 1)),
          ),
        )
        .fold(
          0,
          (accumulator, item) => accumulator + (item['earnings'] as double),
        );

    // Calculate this month's earnings
    final startOfMonth = DateTime(today.year, today.month, 1);
    _monthEarnings = dailyEarnings
        .where(
          (item) => (item['date'] as DateTime).isAfter(
            startOfMonth.subtract(const Duration(days: 1)),
          ),
        )
        .fold(
          0,
          (accumulator, item) => accumulator + (item['earnings'] as double),
        );

    // Generate weekly chart data (last 7 days)
    _weeklySpots = [];
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dayData = dailyEarnings.firstWhere(
        (item) => (item['date'] as DateTime).day == date.day,
        orElse: () => {'earnings': 0.0},
      );
      _weeklySpots.add(
        FlSpot((6 - i).toDouble(), dayData['earnings'] as double),
      );
    }

    // Generate monthly chart data (last 30 days)
    _monthlySpots = [];
    for (int i = 29; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dayData = dailyEarnings.firstWhere(
        (item) => (item['date'] as DateTime).day == date.day,
        orElse: () => {'earnings': 0.0},
      );
      _monthlySpots.add(
        FlSpot((29 - i).toDouble(), dayData['earnings'] as double),
      );
    }

    // Find max value for chart
    final allSpots = [..._weeklySpots, ..._monthlySpots];
    if (allSpots.isNotEmpty) {
      _maxY =
          allSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) * 1.2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.blue,
      ),
      backgroundColor: Colors.black,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Earnings summary cards
                    _buildEarningsSummary(),

                    const SizedBox(height: 24),

                    // Chart period selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Earnings Chart',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SegmentedButton<String>(
                          segments:
                              _periodOptions
                                  .map(
                                    (period) => ButtonSegment<String>(
                                      value: period,
                                      label: Text(period),
                                    ),
                                  )
                                  .toList(),
                          selected: {_selectedPeriod},
                          onSelectionChanged: (Set<String> selection) {
                            setState(() {
                              _selectedPeriod = selection.first;
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.resolveWith<Color>((
                                  Set<WidgetState> states,
                                ) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.blue;
                                  }
                                  return Colors.grey[800]!;
                                }),
                            foregroundColor:
                                WidgetStateProperty.resolveWith<Color>((
                                  Set<WidgetState> states,
                                ) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.white;
                                  }
                                  return Colors.grey[400]!;
                                }),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Earnings chart
                    _buildEarningsChart(),

                    const SizedBox(height: 24),

                    // Recent transactions
                    Text(
                      'Recent Transactions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Transaction list
                    _buildTransactionList(),
                  ],
                ),
              ),
    );
  }

  Widget _buildEarningsSummary() {
    return Column(
      children: [
        // Total earnings card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withAlpha(77),
            ), // 0.3 * 255 = 76.5 ≈ 77
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Earnings',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '₱${_totalEarnings.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Period earnings cards
        Row(
          children: [
            _buildPeriodCard('Today', _todayEarnings),
            const SizedBox(width: 12),
            _buildPeriodCard('This Week', _weekEarnings),
            const SizedBox(width: 12),
            _buildPeriodCard('This Month', _monthEarnings),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodCard(String title, double amount) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              '₱${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsChart() {
    final spots = _selectedPeriod == 'Week' ? _weeklySpots : _monthlySpots;
    final days = _selectedPeriod == 'Week' ? 7 : 30;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 200,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey[800], strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _selectedPeriod == 'Week' ? 1 : 5,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) return const Text('');

                  final now = DateTime.now();
                  final date = now.subtract(
                    Duration(days: days - 1 - value.toInt()),
                  );

                  if (_selectedPeriod == 'Week') {
                    return Text(
                      DateFormat('E').format(date),
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    );
                  } else {
                    return Text(
                      DateFormat('d').format(date),
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    );
                  }
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 200,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '₱${value.toInt()}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: days - 1.0,
          minY: 0,
          maxY: _maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withAlpha(51), // 0.2 * 255 = 51
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    // Generate mock transactions
    final now = DateTime.now();
    final transactions = [
      {
        'date': now.subtract(const Duration(hours: 2)),
        'amount': 450.0,
        'description': 'Trip earnings - R2 route',
      },
      {
        'date': now.subtract(const Duration(hours: 5)),
        'amount': 380.0,
        'description': 'Trip earnings - R2 route',
      },
      {
        'date': now.subtract(const Duration(days: 1)),
        'amount': 520.0,
        'description': 'Trip earnings - R2 route',
      },
      {
        'date': now.subtract(const Duration(days: 1, hours: 4)),
        'amount': 410.0,
        'description': 'Trip earnings - R2 route',
      },
      {
        'date': now.subtract(const Duration(days: 2)),
        'amount': 480.0,
        'description': 'Trip earnings - R2 route',
      },
    ];

    return Column(
      children:
          transactions
              .map((transaction) => _buildTransactionItem(transaction))
              .toList(),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final date = transaction['date'] as DateTime;
    final amount = transaction['amount'] as double;
    final description = transaction['description'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monetization_on,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(date),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '+₱${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.isAfter(today.subtract(const Duration(seconds: 1)))) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (date.isAfter(yesterday.subtract(const Duration(seconds: 1)))) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, yyyy - h:mm a').format(date);
    }
  }
}
