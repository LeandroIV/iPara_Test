import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp class
import 'package:intl/intl.dart';
// Using a mock implementation of fl_chart to avoid errors
import '../../mocks/fl_chart_mock.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  // Removed unused fields: _firestore and _auth
  bool _isLoading = true;

  // Finance data
  double _totalRevenue = 0;
  double _totalExpenses = 0;
  double _netProfit = 0;

  // Chart data
  List<FlSpot> _revenueSpots = [];
  List<FlSpot> _expenseSpots = [];
  double _maxY = 10000; // Default max value for chart

  // Filter
  String _selectedPeriod = 'Month';
  final List<String> _periodOptions = ['Week', 'Month', 'Year'];

  // Transactions
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  Future<void> _loadFinanceData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For now, we'll use mock data
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay

      // Generate mock data
      _generateMockFinanceData();

      setState(() {
        _isLoading = false;
      });

      // Uncomment this code when you have a real finance collection
      /*
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Get finance data from Firestore
        final querySnapshot = await _firestore
            .collection('operator_finances')
            .where('operatorId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .get();

        // Process data
        // ...

        setState(() {
          _isLoading = false;
        });
      }
      */
    } catch (e) {
      debugPrint('Error loading finance data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateMockFinanceData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Generate daily finance data for the past 30 days
    final List<Map<String, dynamic>> dailyFinances = [];

    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));

      // Generate random revenue between 5000 and 8000
      final revenue = 5000.0 + (3000.0 * (date.day % 7) / 7);

      // Generate random expenses between 2000 and 4000
      final expenses = 2000.0 + (2000.0 * (date.day % 5) / 5);

      dailyFinances.add({
        'date': date,
        'revenue': revenue,
        'expenses': expenses,
        'profit': revenue - expenses,
      });
    }

    // Calculate totals
    _totalRevenue = dailyFinances.fold(
      0,
      (accumulator, item) => accumulator + (item['revenue'] as double),
    );
    _totalExpenses = dailyFinances.fold(
      0,
      (accumulator, item) => accumulator + (item['expenses'] as double),
    );
    _netProfit = _totalRevenue - _totalExpenses;

    // Generate chart data based on selected period
    _generateChartData(dailyFinances);

    // Generate transaction list
    _generateTransactionList();
  }

  void _generateChartData(List<Map<String, dynamic>> dailyFinances) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_selectedPeriod == 'Week') {
      // Last 7 days
      _revenueSpots = [];
      _expenseSpots = [];

      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dayData = dailyFinances.firstWhere(
          (item) => (item['date'] as DateTime).day == date.day,
          orElse: () => {'revenue': 0.0, 'expenses': 0.0},
        );

        _revenueSpots.add(
          FlSpot((6 - i).toDouble(), dayData['revenue'] as double),
        );
        _expenseSpots.add(
          FlSpot((6 - i).toDouble(), dayData['expenses'] as double),
        );
      }
    } else if (_selectedPeriod == 'Month') {
      // Last 30 days
      _revenueSpots = [];
      _expenseSpots = [];

      for (int i = 29; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dayData = dailyFinances.firstWhere(
          (item) => (item['date'] as DateTime).day == date.day,
          orElse: () => {'revenue': 0.0, 'expenses': 0.0},
        );

        _revenueSpots.add(
          FlSpot((29 - i).toDouble(), dayData['revenue'] as double),
        );
        _expenseSpots.add(
          FlSpot((29 - i).toDouble(), dayData['expenses'] as double),
        );
      }
    } else {
      // Year (simplified to last 12 months using the first day of each month)
      _revenueSpots = [];
      _expenseSpots = [];

      for (int i = 11; i >= 0; i--) {
        final monthData = {
          'revenue': 5000.0 + (3000.0 * i / 11),
          'expenses': 2000.0 + (2000.0 * i / 11),
        };

        _revenueSpots.add(
          FlSpot((11 - i).toDouble(), monthData['revenue'] as double),
        );
        _expenseSpots.add(
          FlSpot((11 - i).toDouble(), monthData['expenses'] as double),
        );
      }
    }

    // Find max value for chart
    final allValues = [
      ..._revenueSpots.map((spot) => spot.y),
      ..._expenseSpots.map((spot) => spot.y),
    ];
    if (allValues.isNotEmpty) {
      _maxY = allValues.reduce((a, b) => a > b ? a : b) * 1.2;
    }
  }

  void _generateTransactionList() {
    final now = DateTime.now();

    // Generate mock transactions
    _transactions = [
      {
        'id': '1',
        'type': 'revenue',
        'amount': 5800.0,
        'description': 'Daily revenue from 5 vehicles',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'category': 'Operations',
      },
      {
        'id': '2',
        'type': 'expense',
        'amount': 2500.0,
        'description': 'Fuel expenses',
        'timestamp': Timestamp.fromDate(
          now.subtract(const Duration(days: 1, hours: 2)),
        ),
        'category': 'Fuel',
      },
      {
        'id': '3',
        'type': 'expense',
        'amount': 1200.0,
        'description': 'Vehicle maintenance - JPN-123',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'category': 'Maintenance',
      },
      {
        'id': '4',
        'type': 'revenue',
        'amount': 6200.0,
        'description': 'Daily revenue from 5 vehicles',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'category': 'Operations',
      },
      {
        'id': '5',
        'type': 'expense',
        'amount': 2800.0,
        'description': 'Fuel expenses',
        'timestamp': Timestamp.fromDate(
          now.subtract(const Duration(days: 2, hours: 3)),
        ),
        'category': 'Fuel',
      },
      {
        'id': '6',
        'type': 'expense',
        'amount': 500.0,
        'description': 'Driver salary advance - John Doe',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        'category': 'Salary',
      },
      {
        'id': '7',
        'type': 'revenue',
        'amount': 5500.0,
        'description': 'Daily revenue from 5 vehicles',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        'category': 'Operations',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance'),
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
                    // Finance summary cards
                    _buildFinanceSummary(),

                    const SizedBox(height: 24),

                    // Financial Overview title
                    Text(
                      'Financial Overview',
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
                              _generateMockFinanceData();
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

                    // Finance chart
                    _buildFinanceChart(),

                    const SizedBox(height: 24),

                    // Recent transactions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to all transactions
                          },
                          child: Text(
                            'View All',
                            style: TextStyle(color: Colors.amber),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Transaction list
                    _buildTransactionList(),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add transaction screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add transaction functionality coming soon'),
            ),
          );
        },
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFinanceSummary() {
    return Column(
      children: [
        // Net profit card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.amber.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.amber.withAlpha(77),
            ), // 0.3 * 255 = 76.5 ≈ 77
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Net Profit',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '₱${_netProfit.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Revenue and expenses cards
        Row(
          children: [
            _buildFinanceCard('Revenue', _totalRevenue, Colors.green),
            const SizedBox(width: 16),
            _buildFinanceCard('Expenses', _totalExpenses, Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildFinanceCard(String title, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                Icon(
                  title == 'Revenue'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: color,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '₱${amount.toStringAsFixed(2)}',
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

  Widget _buildFinanceChart() {
    final days =
        _selectedPeriod == 'Week'
            ? 7
            : _selectedPeriod == 'Month'
            ? 30
            : 12;

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
              _buildLegendItem('Revenue', Colors.green),
              const SizedBox(width: 24),
              _buildLegendItem('Expenses', Colors.red),
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
                  horizontalInterval: 2000,
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
                      interval:
                          _selectedPeriod == 'Week'
                              ? 1
                              : _selectedPeriod == 'Month'
                              ? 5
                              : 1,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0) return const Text('');

                        final now = DateTime.now();

                        if (_selectedPeriod == 'Week') {
                          final date = now.subtract(
                            Duration(days: days - 1 - value.toInt()),
                          );
                          return Text(
                            DateFormat('E').format(date),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                            ),
                          );
                        } else if (_selectedPeriod == 'Month') {
                          final date = now.subtract(
                            Duration(days: days - 1 - value.toInt()),
                          );
                          return Text(
                            DateFormat('d').format(date),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                            ),
                          );
                        } else {
                          // Year
                          final month = (now.month - 11 + value.toInt()) % 12;
                          return Text(
                            DateFormat('MMM').format(
                              DateTime(now.year, month == 0 ? 12 : month),
                            ),
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
                      interval: 2000,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₱${value.toInt()}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                          ),
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
                  // Revenue line
                  LineChartBarData(
                    spots: _revenueSpots,
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
                  // Expense line
                  LineChartBarData(
                    spots: _expenseSpots,
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.red.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
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

  Widget _buildTransactionList() {
    return Column(
      children:
          _transactions
              .take(5)
              .map((transaction) => _buildTransactionItem(transaction))
              .toList(),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isRevenue = transaction['type'] == 'revenue';
    final timestamp = transaction['timestamp'] as Timestamp;
    final amount = transaction['amount'] as double;
    final description = transaction['description'] as String;
    final category = transaction['category'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  isRevenue
                      ? Colors.green.withAlpha(26) // 0.1 * 255 = 25.5 ≈ 26
                      : Colors.red.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRevenue ? Icons.arrow_upward : Icons.arrow_downward,
              color: isRevenue ? Colors.green : Colors.red,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        category,
                        style: TextStyle(color: Colors.amber, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _formatDate(timestamp.toDate()),
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${isRevenue ? '+' : '-'}₱${amount.toStringAsFixed(0)}',
              style: TextStyle(
                color: isRevenue ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
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
      return 'Today ${DateFormat('h:mm').format(date)}';
    } else if (date.isAfter(yesterday.subtract(const Duration(seconds: 1)))) {
      return 'Yest ${DateFormat('h:mm').format(date)}';
    } else {
      return DateFormat('MM/dd/yy').format(date);
    }
  }
}
