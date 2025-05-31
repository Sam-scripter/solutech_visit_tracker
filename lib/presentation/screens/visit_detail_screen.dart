import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../../data/models/visit.dart';
import '../../data/models/activity.dart';
import '../../data/services/api_service.dart';
import '../../data/models/customer.dart';

/// VisitDetailScreen displays detailed information about a specific visit.
class VisitDetailScreen extends StatefulWidget {
  final Visit visit;
  const VisitDetailScreen({super.key, required this.visit});

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  List<Activity> _activities = [];
  Customer? _customer;
  bool _isLoading = true;
  bool _isOnline = true;
  String? _error;

  /// Fetches activities and customer for detailed display.
   Future<void> _loadDetails() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity[0] == ConnectivityResult.mobile || connectivity[0] == ConnectivityResult.wifi;
      setState(() => _isOnline = isOnline);

      if (isOnline) {
        final api = ApiService();
        _activities = await api.fetchActivities();
        final customers = await api.fetchCustomers();
        _customer = customers.firstWhere(
              (c) => c.id == widget.visit.customerId,
          orElse: () => Customer(id: -1, name: 'Unknown Customer'),
        );
      } else {
        final customerBox = await Hive.openBox<Customer>('customers');
        final activityBox = await Hive.openBox<Activity>('activities');

        _activities = activityBox.values.toList();
        _customer = customerBox.values.firstWhere(
              (c) => c.id == widget.visit.customerId,
          orElse: () => Customer(id: -1, name: 'Unknown Customer'),
        );
      }
    } catch (e) {
      _error = 'Failed to load visit details.';
    } finally {
      setState(() => _isLoading = false);
    }
  }


  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;

    return Scaffold(
      appBar: AppBar(title: const Text('Visit Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildConnectivityBanner(),
            Expanded(
              child: ListView(
                children: [
                  _buildDetailRow('Customer', _customer?.name ?? 'Loading...'),
                  _buildDetailRow('Date', DateFormat.yMMMEd().add_jm().format(visit.visitDate)),
                  _buildDetailRow('Location', visit.location),
                  _buildDetailRow('Status', visit.status.name.toUpperCase()),
                  const SizedBox(height: 16),

                  const Text(
                    'Activities Done:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),

                  if (visit.activitiesDone != null && _activities.isNotEmpty)
                    ...visit.activitiesDone!.map((id) {
                      final matched = _activities.firstWhere(
                            (a) => a.id == id,
                        orElse: () => Activity(id: id, description: 'Unknown Activity'),
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text('• ${matched.description}'),
                      );
                    }),

                  const SizedBox(height: 24),

                  if (visit.notes != null && visit.notes!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            visit.notes!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to build a labeled row with some spacing and styling.
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectivityBanner() {
    if (_isOnline) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: const [
          Icon(Icons.wifi_off, color: Colors.red),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are viewing offline data',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

}
