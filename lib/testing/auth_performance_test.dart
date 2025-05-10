import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
import '../models/user_role.dart';

/// A utility class for testing authentication performance
class AuthPerformanceTest {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Test results storage
  final List<Map<String, dynamic>> _loginResults = [];
  final List<Map<String, dynamic>> _signupResults = [];
  final List<Map<String, dynamic>> _roleSelectionResults = [];

  // Test configuration
  final int _testIterations;
  final bool _includeSignup;
  final bool _includeRoleSelection;
  final NetworkCondition _networkCondition;

  AuthPerformanceTest({
    int testIterations = 5,
    bool includeSignup = false,
    bool includeRoleSelection = false,
    NetworkCondition networkCondition = NetworkCondition.normal,
  }) : _testIterations = testIterations,
       _includeSignup = includeSignup,
       _includeRoleSelection = includeRoleSelection,
       _networkCondition = networkCondition;

  /// Run the authentication performance tests
  Future<AuthTestResults> runTests({
    required List<TestAccount> accounts,
    Function(String)? progressCallback,
  }) async {
    // Ensure we have enough test accounts
    if (accounts.length < _testIterations) {
      throw Exception(
        'Not enough test accounts provided. Need at least $_testIterations accounts.',
      );
    }

    // Clear previous results
    _loginResults.clear();
    _signupResults.clear();
    _roleSelectionResults.clear();

    // Make sure we're signed out before starting
    await _signOut();

    // Run login tests
    for (int i = 0; i < _testIterations; i++) {
      final account = accounts[i];

      if (progressCallback != null) {
        progressCallback(
          'Testing login for account ${i + 1} of $_testIterations',
        );
      }

      // Apply network condition if needed
      await _applyNetworkCondition();

      // Test login
      final loginResult = await _testLogin(account.email, account.password);
      _loginResults.add(loginResult);

      // Test role selection if enabled
      if (_includeRoleSelection && loginResult['success']) {
        final roleResult = await _testRoleSelection(account.role);
        _roleSelectionResults.add(roleResult);
      }

      // Sign out after each test
      await _signOut();
    }

    // Run signup tests if enabled
    if (_includeSignup) {
      for (int i = 0; i < _testIterations; i++) {
        // Generate a unique email for signup
        final email =
            'test_${DateTime.now().millisecondsSinceEpoch}_$i@example.com';
        final password = 'Test123!';

        if (progressCallback != null) {
          progressCallback(
            'Testing signup for account ${i + 1} of $_testIterations',
          );
        }

        // Apply network condition if needed
        await _applyNetworkCondition();

        // Test signup
        final signupResult = await _testSignup(email, password);
        _signupResults.add(signupResult);

        // Sign out after each test
        await _signOut();
      }
    }

    // Calculate and return results
    return _calculateResults();
  }

  /// Test login performance
  Future<Map<String, dynamic>> _testLogin(String email, String password) async {
    final result = <String, dynamic>{
      'email': email,
      'success': false,
      'timeMs': 0,
      'error': null,
    };

    try {
      final stopwatch = Stopwatch()..start();

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      stopwatch.stop();
      result['timeMs'] = stopwatch.elapsedMilliseconds;
      result['success'] = true;
    } on FirebaseAuthException catch (e) {
      result['error'] = e.code;
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  /// Test signup performance
  Future<Map<String, dynamic>> _testSignup(
    String email,
    String password,
  ) async {
    final result = <String, dynamic>{
      'email': email,
      'success': false,
      'timeMs': 0,
      'error': null,
    };

    try {
      final stopwatch = Stopwatch()..start();

      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      stopwatch.stop();
      result['timeMs'] = stopwatch.elapsedMilliseconds;
      result['success'] = true;
    } on FirebaseAuthException catch (e) {
      result['error'] = e.code;
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  /// Test role selection performance
  Future<Map<String, dynamic>> _testRoleSelection(UserRole role) async {
    final result = <String, dynamic>{
      'role': role.toString(),
      'success': false,
      'timeMs': 0,
      'error': null,
    };

    try {
      final stopwatch = Stopwatch()..start();

      await UserService.saveUserRole(role);

      stopwatch.stop();
      result['timeMs'] = stopwatch.elapsedMilliseconds;
      result['success'] = true;
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  /// Sign out the current user
  Future<void> _signOut() async {
    try {
      await _auth.signOut();

      // Also clear role from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role');
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  /// Apply simulated network condition
  Future<void> _applyNetworkCondition() async {
    // In a real implementation, you would use a network conditioning tool
    // For now, we'll just add artificial delay based on the condition
    switch (_networkCondition) {
      case NetworkCondition.poor:
        await Future.delayed(const Duration(milliseconds: 500));
        break;
      case NetworkCondition.limited:
        await Future.delayed(const Duration(milliseconds: 200));
        break;
      case NetworkCondition.normal:
        // No artificial delay
        break;
    }
  }

  /// Calculate final test results
  AuthTestResults _calculateResults() {
    // Login metrics
    final loginTimes =
        _loginResults
            .where((r) => r['success'])
            .map((r) => r['timeMs'] as int)
            .toList();

    final double avgLoginTime =
        loginTimes.isNotEmpty
            ? (loginTimes.reduce((a, b) => a + b) / loginTimes.length)
                .toDouble()
            : 0.0;

    final double loginSuccessRate =
        _loginResults.isNotEmpty
            ? (_loginResults.where((r) => r['success']).length /
                    _loginResults.length)
                .toDouble()
            : 0.0;

    // Signup metrics
    final signupTimes =
        _signupResults
            .where((r) => r['success'])
            .map((r) => r['timeMs'] as int)
            .toList();

    final double avgSignupTime =
        signupTimes.isNotEmpty
            ? (signupTimes.reduce((a, b) => a + b) / signupTimes.length)
                .toDouble()
            : 0.0;

    final double signupSuccessRate =
        _signupResults.isNotEmpty
            ? (_signupResults.where((r) => r['success']).length /
                    _signupResults.length)
                .toDouble()
            : 0.0;

    // Role selection metrics
    final roleSelectionTimes =
        _roleSelectionResults
            .where((r) => r['success'])
            .map((r) => r['timeMs'] as int)
            .toList();

    final double avgRoleSelectionTime =
        roleSelectionTimes.isNotEmpty
            ? (roleSelectionTimes.reduce((a, b) => a + b) /
                    roleSelectionTimes.length)
                .toDouble()
            : 0.0;

    final double roleSelectionSuccessRate =
        _roleSelectionResults.isNotEmpty
            ? (_roleSelectionResults.where((r) => r['success']).length /
                    _roleSelectionResults.length)
                .toDouble()
            : 0.0;

    return AuthTestResults(
      loginResults: _loginResults,
      signupResults: _signupResults,
      roleSelectionResults: _roleSelectionResults,
      averageLoginTimeMs: avgLoginTime,
      averageSignupTimeMs: avgSignupTime,
      averageRoleSelectionTimeMs: avgRoleSelectionTime,
      loginSuccessRate: loginSuccessRate,
      signupSuccessRate: signupSuccessRate,
      roleSelectionSuccessRate: roleSelectionSuccessRate,
    );
  }
}

/// Test account model
class TestAccount {
  final String email;
  final String password;
  final UserRole role;

  TestAccount({
    required this.email,
    required this.password,
    required this.role,
  });
}

/// Network condition enum
enum NetworkCondition { normal, limited, poor }

/// Authentication test results
class AuthTestResults {
  final List<Map<String, dynamic>> loginResults;
  final List<Map<String, dynamic>> signupResults;
  final List<Map<String, dynamic>> roleSelectionResults;
  final double averageLoginTimeMs;
  final double averageSignupTimeMs;
  final double averageRoleSelectionTimeMs;
  final double loginSuccessRate;
  final double signupSuccessRate;
  final double roleSelectionSuccessRate;

  AuthTestResults({
    required this.loginResults,
    required this.signupResults,
    required this.roleSelectionResults,
    required this.averageLoginTimeMs,
    required this.averageSignupTimeMs,
    required this.averageRoleSelectionTimeMs,
    required this.loginSuccessRate,
    required this.signupSuccessRate,
    required this.roleSelectionSuccessRate,
  });

  @override
  String toString() {
    return '''
Authentication Performance Test Results:
----------------------------------------
Login:
  Average Time: ${averageLoginTimeMs.toStringAsFixed(2)} ms
  Success Rate: ${(loginSuccessRate * 100).toStringAsFixed(2)}%

Signup:
  Average Time: ${averageSignupTimeMs.toStringAsFixed(2)} ms
  Success Rate: ${(signupSuccessRate * 100).toStringAsFixed(2)}%

Role Selection:
  Average Time: ${averageRoleSelectionTimeMs.toStringAsFixed(2)} ms
  Success Rate: ${(roleSelectionSuccessRate * 100).toStringAsFixed(2)}%
''';
  }
}
