import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For now, we'll use mock data since the actual notifications collection might not exist yet
      // In a real implementation, you would fetch from Firestore
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      setState(() {
        _notifications = _getMockNotifications();
        _isLoading = false;
      });
      
      // Uncomment this code when you have a real notifications collection
      /*
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final querySnapshot = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .get();
            
        final notifications = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? 'Notification',
            'message': data['message'] ?? '',
            'timestamp': data['timestamp'] as Timestamp,
            'isRead': data['isRead'] ?? false,
            'type': data['type'] ?? 'general',
          };
        }).toList();
        
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
      */
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getMockNotifications() {
    // Create some mock notification data
    return [
      {
        'id': '1',
        'title': 'Route Update',
        'message': 'Route R2 has been updated with new stops.',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
        'isRead': false,
        'type': 'route_update',
      },
      {
        'id': '2',
        'title': 'Service Disruption',
        'message': 'Bus services on Route R3 are experiencing delays due to road construction.',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'isRead': true,
        'type': 'service_alert',
      },
      {
        'id': '3',
        'title': 'Fare Update',
        'message': 'Fares for Motorela routes will increase by ₱2 starting next week.',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
        'isRead': false,
        'type': 'fare_update',
      },
      {
        'id': '4',
        'title': 'New Feature',
        'message': 'You can now track your family members in real-time with our new Family Group feature!',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
        'isRead': true,
        'type': 'app_update',
      },
      {
        'id': '5',
        'title': 'Welcome to iPara',
        'message': 'Thank you for joining iPara! Explore our features to make your commute easier.',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
        'isRead': true,
        'type': 'welcome',
      },
    ];
  }

  Future<void> _markAsRead(String notificationId) async {
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
      }
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        // In a real app, update the notification in Firestore
        // await _firestore.collection('notifications').doc(notificationId).update({
        //   'isRead': true,
        // });
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        // In a real app, update all notifications in Firestore
        // final batch = _firestore.batch();
        // for (var notification in _notifications) {
        //   final docRef = _firestore.collection('notifications').doc(notification['id']);
        //   batch.update(docRef, {'isRead': true});
        // }
        // await batch.commit();
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'route_update':
        return Icons.route;
      case 'service_alert':
        return Icons.warning_amber;
      case 'fare_update':
        return Icons.attach_money;
      case 'app_update':
        return Icons.system_update;
      case 'welcome':
        return Icons.celebration;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'route_update':
        return Colors.blue;
      case 'service_alert':
        return Colors.orange;
      case 'fare_update':
        return Colors.green;
      case 'app_update':
        return Colors.purple;
      case 'welcome':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['isRead']).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text('Mark all as read'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.amber,
              ),
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 64, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      const Text(
                        'No notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You\'ll receive notifications about route updates and more',
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
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return _buildNotificationCard(notification);
                  },
                ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final bool isRead = notification['isRead'];
    final IconData icon = _getNotificationIcon(notification['type']);
    final Color iconColor = _getNotificationColor(notification['type']);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isRead ? Colors.grey[900] : Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRead 
            ? BorderSide.none 
            : BorderSide(color: iconColor.withOpacity(0.5), width: 1),
      ),
      child: InkWell(
        onTap: () {
          if (!isRead) {
            _markAsRead(notification['id']);
          }
          // TODO: Handle notification tap (e.g., navigate to relevant screen)
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: iconColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'],
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(notification['timestamp']),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
