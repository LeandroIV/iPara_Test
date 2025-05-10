import 'package:flutter/material.dart';
import '../../models/emergency_contact_model.dart';
import '../../services/emergency_service.dart';
import 'package:intl/intl.dart';

class EmergencyHistoryScreen extends StatefulWidget {
  const EmergencyHistoryScreen({super.key});

  @override
  State<EmergencyHistoryScreen> createState() => _EmergencyHistoryScreenState();
}

class _EmergencyHistoryScreenState extends State<EmergencyHistoryScreen> {
  final EmergencyService _emergencyService = EmergencyService();
  bool _isLoading = true;
  List<EmergencyAlert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final alerts = await _emergencyService.getUserAlerts();
      setState(() {
        _alerts = alerts;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading emergency alerts: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAlertStatus(EmergencyAlert alert, EmergencyAlertStatus newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _emergencyService.updateAlertStatus(alert.id, newStatus);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alert marked as ${newStatus.name}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload alerts
        await _loadAlerts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update alert status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating alert status: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAlertDetails(EmergencyAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Alert Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status', alert.status.name),
              _buildDetailRow(
                'Time',
                DateFormat('MMM d, yyyy h:mm a').format(alert.timestamp.toLocal()),
              ),
              _buildDetailRow(
                'Location',
                '${alert.latitude.toStringAsFixed(6)}, ${alert.longitude.toStringAsFixed(6)}',
              ),
              if (alert.notes != null && alert.notes!.isNotEmpty)
                _buildDetailRow('Notes', alert.notes!),
              if (alert.notifiedContacts.isNotEmpty)
                _buildDetailRow(
                  'Notified Contacts',
                  '${alert.notifiedContacts.length} contacts',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (alert.status == EmergencyAlertStatus.active)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _updateAlertStatus(alert, EmergencyAlertStatus.resolved);
              },
              child: const Text('Mark as Resolved'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency History'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.red,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? _buildEmptyState()
              : _buildAlertsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Emergency Alerts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your emergency alert history will appear here',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(alert.status).withOpacity(0.2),
              child: Icon(
                _getStatusIcon(alert.status),
                color: _getStatusColor(alert.status),
              ),
            ),
            title: Text(
              'Emergency Alert',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM d, yyyy h:mm a').format(alert.timestamp.toLocal()),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(alert.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    alert.status.name,
                    style: TextStyle(
                      color: _getStatusColor(alert.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAlertDetails(alert),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Color _getStatusColor(EmergencyAlertStatus status) {
    switch (status) {
      case EmergencyAlertStatus.active:
        return Colors.red;
      case EmergencyAlertStatus.responded:
        return Colors.orange;
      case EmergencyAlertStatus.resolved:
        return Colors.green;
      case EmergencyAlertStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(EmergencyAlertStatus status) {
    switch (status) {
      case EmergencyAlertStatus.active:
        return Icons.warning_amber_rounded;
      case EmergencyAlertStatus.responded:
        return Icons.directions_run;
      case EmergencyAlertStatus.resolved:
        return Icons.check_circle;
      case EmergencyAlertStatus.cancelled:
        return Icons.cancel;
    }
  }
}
