import 'package:flutter/material.dart';
import '../../models/ride_request_model.dart';
import '../../services/ride_request_service.dart';
import 'package:intl/intl.dart';

class RideRequestsScreen extends StatefulWidget {
  const RideRequestsScreen({super.key});

  @override
  State<RideRequestsScreen> createState() => _RideRequestsScreenState();
}

class _RideRequestsScreenState extends State<RideRequestsScreen> {
  final RideRequestService _rideRequestService = RideRequestService();
  List<RideRequest> _rideRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRideRequests();
  }

  Future<void> _loadRideRequests() async {
    setState(() {
      _isLoading = true;
    });

    // Listen for ride requests
    _rideRequestService.commuterRequests.listen((requests) {
      if (mounted) {
        setState(() {
          _rideRequests = requests;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Requests'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF1A1A1A)],
          ),
        ),
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.amber),
                )
                : _rideRequests.isEmpty
                ? const Center(
                  child: Text(
                    'No ride requests found',
                    style: TextStyle(color: Colors.white),
                  ),
                )
                : ListView.builder(
                  itemCount: _rideRequests.length,
                  itemBuilder: (context, index) {
                    final request = _rideRequests[index];
                    return _buildRideRequestCard(request);
                  },
                ),
      ),
    );
  }

  Widget _buildRideRequestCard(RideRequest request) {
    // Format the date
    final dateFormat = DateFormat('MMM d, h:mm a');
    final formattedDate = dateFormat.format(request.createdAt);

    // Get status color
    Color statusColor;
    switch (request.status) {
      case RideRequestStatus.pending:
        statusColor = Colors.amber;
        break;
      case RideRequestStatus.accepted:
        statusColor = Colors.green;
        break;
      case RideRequestStatus.boarding:
        statusColor = Colors.lightGreen;
        break;
      case RideRequestStatus.inTransit:
        statusColor = Colors.teal;
        break;
      case RideRequestStatus.arrived:
        statusColor = Colors.lightBlue;
        break;
      case RideRequestStatus.completed:
        statusColor = Colors.blue;
        break;
      case RideRequestStatus.paid:
        statusColor = Colors.deepPurple;
        break;
      case RideRequestStatus.rejected:
        statusColor = Colors.red;
        break;
      case RideRequestStatus.cancelled:
        statusColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withAlpha(153), // 0.6 opacity = 153 alpha (0.6 * 255)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withAlpha(128),
          width: 1,
        ), // 0.5 opacity = 128 alpha
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Request to ${request.driverName ?? 'Driver'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(
                      51,
                    ), // 0.2 opacity = 51 alpha (0.2 * 255)
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    request.status.displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getIconForPuvType(request.puvType),
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  request.puvType,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${request.distanceKm.toStringAsFixed(1)} km away',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${request.etaMinutes} min ETA',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Requested on $formattedDate',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            if (request.status == RideRequestStatus.pending)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _cancelRideRequest(request),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Cancel Request'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Get icon for PUV type
  IconData _getIconForPuvType(String type) {
    switch (type.toLowerCase()) {
      case 'bus':
        return Icons.directions_bus;
      case 'jeepney':
        return Icons.airport_shuttle;
      case 'multicab':
        return Icons.local_shipping;
      case 'motorela':
        return Icons.motorcycle;
      default:
        return Icons.directions_car;
    }
  }

  // Cancel a ride request
  Future<void> _cancelRideRequest(RideRequest request) async {
    try {
      await _rideRequestService.updateRequestStatus(
        request.id,
        RideRequestStatus.cancelled,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride request cancelled'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error cancelling ride request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling ride request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
