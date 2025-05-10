import 'package:flutter/material.dart';
import '../../testing/auth_performance_test.dart';
import '../../models/user_role.dart';

class AuthTestScreen extends StatefulWidget {
  const AuthTestScreen({Key? key}) : super(key: key);

  @override
  State<AuthTestScreen> createState() => _AuthTestScreenState();
}

class _AuthTestScreenState extends State<AuthTestScreen> {
  bool _isRunningTests = false;
  String _progressMessage = '';
  AuthTestResults? _testResults;

  // Test configuration
  int _testIterations = 5;
  bool _includeSignup = false;
  bool _includeRoleSelection = true;
  NetworkCondition _networkCondition = NetworkCondition.normal;

  // Test accounts - IMPORTANT: Replace with real test accounts from your Firebase project
  final List<TestAccount> _testAccounts = [
    // These are placeholder accounts - you must replace them with real accounts
    // that exist in your Firebase Authentication system
    TestAccount(
      email: 'huhu@email.com',
      password: '123456',
      role: UserRole.commuter,
    ),
    TestAccount(
      email: 'yarra.erwindane@gmail.com',
      password: '20dane03',
      role: UserRole.driver,
    ),
    TestAccount(
      email: 'operator1@ipara.test',
      password: 'Test123!',
      role: UserRole.operator,
    ),
    TestAccount(
      email: 'rider@gmail.com',
      password: 'initauy',
      role: UserRole.commuter,
    ),
    TestAccount(
      email: 'driver2@ipara.test',
      password: 'Test123!',
      role: UserRole.driver,
    ),
    // Add more test accounts if needed for larger test iterations
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Authentication Performance Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning message
            Card(
              color: Colors.amber.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.amber),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Important: Before running tests, update the test accounts in the code with real accounts from your Firebase project.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Number of iterations
                    Row(
                      children: [
                        const Text('Test Iterations:'),
                        const SizedBox(width: 16),
                        DropdownButton<int>(
                          value: _testIterations,
                          items:
                              [1, 3, 5, 10].map((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(value.toString()),
                                );
                              }).toList(),
                          onChanged:
                              _isRunningTests
                                  ? null
                                  : (int? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _testIterations = newValue;
                                      });
                                    }
                                  },
                        ),
                      ],
                    ),

                    // Include signup test
                    CheckboxListTile(
                      title: const Text('Include Signup Test'),
                      value: _includeSignup,
                      onChanged:
                          _isRunningTests
                              ? null
                              : (bool? value) {
                                if (value != null) {
                                  setState(() {
                                    _includeSignup = value;
                                  });
                                }
                              },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Include role selection test
                    CheckboxListTile(
                      title: const Text('Include Role Selection Test'),
                      value: _includeRoleSelection,
                      onChanged:
                          _isRunningTests
                              ? null
                              : (bool? value) {
                                if (value != null) {
                                  setState(() {
                                    _includeRoleSelection = value;
                                  });
                                }
                              },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Network condition
                    Row(
                      children: [
                        const Text('Network Condition:'),
                        const SizedBox(width: 16),
                        DropdownButton<NetworkCondition>(
                          value: _networkCondition,
                          items:
                              NetworkCondition.values.map((
                                NetworkCondition value,
                              ) {
                                return DropdownMenuItem<NetworkCondition>(
                                  value: value,
                                  child: Text(value.toString().split('.').last),
                                );
                              }).toList(),
                          onChanged:
                              _isRunningTests
                                  ? null
                                  : (NetworkCondition? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _networkCondition = newValue;
                                      });
                                    }
                                  },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Run test button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRunningTests ? null : _runTests,
                child:
                    _isRunningTests
                        ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Running Tests...'),
                          ],
                        )
                        : const Text('Run Tests'),
              ),
            ),

            // Progress message
            if (_progressMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(_progressMessage),
              ),

            const SizedBox(height: 16),

            // Test results
            if (_testResults != null)
              Expanded(
                child: Card(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Test Results',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Login results
                        _buildResultSection(
                          title: 'Login',
                          averageTime: _testResults!.averageLoginTimeMs,
                          successRate: _testResults!.loginSuccessRate,
                        ),

                        // Signup results
                        if (_includeSignup)
                          _buildResultSection(
                            title: 'Signup',
                            averageTime: _testResults!.averageSignupTimeMs,
                            successRate: _testResults!.signupSuccessRate,
                          ),

                        // Role selection results
                        if (_includeRoleSelection)
                          _buildResultSection(
                            title: 'Role Selection',
                            averageTime:
                                _testResults!.averageRoleSelectionTimeMs,
                            successRate: _testResults!.roleSelectionSuccessRate,
                          ),

                        const SizedBox(height: 16),

                        // Raw data
                        ExpansionTile(
                          title: const Text('Raw Test Data'),
                          children: [Text(_testResults.toString())],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection({
    required String title,
    required double averageTime,
    required double successRate,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Average Time: ${averageTime.toStringAsFixed(2)} ms'),
          Text('Success Rate: ${(successRate * 100).toStringAsFixed(2)}%'),
        ],
      ),
    );
  }

  Future<void> _runTests() async {
    // Make sure we have enough test accounts
    if (_testAccounts.length < _testIterations) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough test accounts. Need at least $_testIterations accounts.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isRunningTests = true;
      _progressMessage = 'Initializing tests...';
      _testResults = null;
    });

    try {
      // Create and run the test
      final tester = AuthPerformanceTest(
        testIterations: _testIterations,
        includeSignup: _includeSignup,
        includeRoleSelection: _includeRoleSelection,
        networkCondition: _networkCondition,
      );

      final results = await tester.runTests(
        accounts: _testAccounts.sublist(0, _testIterations),
        progressCallback: (message) {
          setState(() {
            _progressMessage = message;
          });
        },
      );

      setState(() {
        _testResults = results;
        _progressMessage = 'Tests completed successfully.';
      });
    } catch (e) {
      setState(() {
        _progressMessage = 'Error running tests: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }
}
