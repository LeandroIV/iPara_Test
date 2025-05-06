import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'screens/home_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/commuter/commuter_home_screen.dart';
import 'screens/driver/driver_home_screen.dart';
import 'screens/operator/operator_home_screen.dart';
import 'services/user_service.dart';
import 'services/notification_service.dart';
import 'models/user_role.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Debug flags - set these to false to skip initialization steps
const bool INITIALIZE_FIREBASE = true;
const bool INITIALIZE_NOTIFICATIONS = false; // Try disabling this first
const int SPLASH_SCREEN_DELAY = 1; // Reduced from 2 seconds

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🔍 DEBUG: App starting...');

  // Check connectivity first
  debugPrint('🔍 DEBUG: Checking connectivity...');
  var connectivityResult = await Connectivity().checkConnectivity();
  debugPrint('🔍 DEBUG: Connectivity result: $connectivityResult');

  if (INITIALIZE_FIREBASE) {
    try {
      debugPrint('🔍 DEBUG: Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('🔍 DEBUG: Firebase initialized successfully');
    } catch (e) {
      debugPrint('🔍 DEBUG: Firebase initialization error: $e');
    }
  } else {
    debugPrint('🔍 DEBUG: Skipping Firebase initialization');
  }

  // Navigator key is already defined at the top
  debugPrint('🔍 DEBUG: Navigator key set up');

  // Initialize notification service
  if (INITIALIZE_NOTIFICATIONS) {
    try {
      debugPrint('🔍 DEBUG: Initializing notification service...');
      await NotificationService().initialize();
      debugPrint('🔍 DEBUG: Notification service initialized successfully');
    } catch (e) {
      debugPrint('🔍 DEBUG: Notification service initialization error: $e');
    }
  } else {
    debugPrint('🔍 DEBUG: Skipping notification service initialization');
  }

  debugPrint('🔍 DEBUG: Starting app...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 DEBUG: Building MyApp');
    return MaterialApp(
      title: 'iPara Debug',
      debugShowCheckedModeBanner: true, // Show debug banner
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const DebugSplashScreen(),
        '/': (context) => const DebugHomeScreen(),
        '/login': (context) => const DebugHomeScreen(),
        '/home': (context) => const DebugHomeScreen(),
      },
    );
  }
}

class DebugSplashScreen extends StatefulWidget {
  const DebugSplashScreen({super.key});

  @override
  State<DebugSplashScreen> createState() => _DebugSplashScreenState();
}

class _DebugSplashScreenState extends State<DebugSplashScreen> {
  String _statusMessage = 'Starting...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    try {
      setState(() => _statusMessage = 'Checking Firebase status...');

      // Check Firebase status
      if (INITIALIZE_FIREBASE) {
        final isFirebaseInitialized = Firebase.apps.isNotEmpty;
        setState(
          () => _statusMessage = 'Firebase initialized: $isFirebaseInitialized',
        );
        await Future.delayed(Duration(seconds: 1));
      }

      // Check auth status
      setState(() => _statusMessage = 'Checking authentication...');
      final user = FirebaseAuth.instance.currentUser;
      setState(() => _statusMessage = 'User authenticated: ${user != null}');
      await Future.delayed(Duration(seconds: 1));

      // Navigate to home
      setState(() => _statusMessage = 'Loading complete!');
      await Future.delayed(Duration(seconds: SPLASH_SCREEN_DELAY));

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF1A1A1A)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', width: 150, height: 150),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.amber),
              const SizedBox(height: 20),
              Text(
                _statusMessage,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 40),
              Text(
                'DEBUG MODE',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DebugHomeScreen extends StatelessWidget {
  const DebugHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('iPara Debug Mode')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Debug Home Screen', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            Text(
              'App initialized successfully!',
              style: TextStyle(fontSize: 16, color: Colors.green),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/splash');
              },
              child: Text('Restart'),
            ),
          ],
        ),
      ),
    );
  }
}
