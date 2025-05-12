import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTestScreen extends StatefulWidget {
  const FirestoreTestScreen({super.key});

  @override
  State<FirestoreTestScreen> createState() => _FirestoreTestScreenState();
}

class _FirestoreTestScreenState extends State<FirestoreTestScreen> {
  bool _isLoading = false;
  String _resultText = 'No test run yet';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _testFirestore() async {
    setState(() {
      _isLoading = true;
      _resultText = 'Testing Firestore connection...';
    });

    try {
      // Test 1: Get all collections
      final collections = await _firestore.collectionGroup('').get();
      _resultText = 'Collections found: ${collections.docs.length}\n\n';

      // Test 2: Try to get routes collection
      final routesSnapshot = await _firestore.collection('routes').get();
      _resultText += 'Routes collection documents: ${routesSnapshot.docs.length}\n\n';

      if (routesSnapshot.docs.isNotEmpty) {
        _resultText += 'Sample route documents:\n';
        for (var doc in routesSnapshot.docs.take(3)) {
          _resultText += '- ${doc.id}: ${doc.data().keys.join(', ')}\n';
          
          // Check if isActive field exists
          if (doc.data().containsKey('isActive')) {
            _resultText += '  isActive: ${doc.data()['isActive']}\n';
          } else {
            _resultText += '  isActive field missing!\n';
          }
          
          // Check if routeCode field exists
          if (doc.data().containsKey('routeCode')) {
            _resultText += '  routeCode: ${doc.data()['routeCode']}\n';
          } else {
            _resultText += '  routeCode field missing!\n';
          }
        }
      } else {
        _resultText += 'No documents found in routes collection.\n';
      }

      // Test 3: Try to get active routes
      final activeRoutesSnapshot = await _firestore
          .collection('routes')
          .where('isActive', isEqualTo: true)
          .get();
      
      _resultText += '\nActive routes: ${activeRoutesSnapshot.docs.length}\n';
      
      if (activeRoutesSnapshot.docs.isNotEmpty) {
        _resultText += 'Sample active routes:\n';
        for (var doc in activeRoutesSnapshot.docs.take(3)) {
          _resultText += '- ${doc.id}: ${doc.data()['routeCode'] ?? 'No code'}\n';
        }
      }
    } catch (e) {
      _resultText = 'Error testing Firestore: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Test'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testFirestore,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text('Test Firestore Connection'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Text(_resultText),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
