import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/visit.dart';
import '../../data/models/activity.dart';
import '../../data/services/api_service.dart';

class VisitDetailScreen extends StatefulWidget {
  final Visit visit;

  const VisitDetailScreen({super.key, required this.visit});

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  List<Activity> _activities = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      final api = ApiService();
      _activities = await api.fetchActivities();
    } catch (e) {
      _error = 'Failed to load activity descriptions';
    } finally {
      setState(() => _isLoading = false);
    }
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
        child: ListView(
          children: [
            Text('Date: ${DateFormat.yMMMEd().add_jm().format(visit.visitDate)}'),
            Text('Location: ${visit.location}'),
            Text('Status: ${visit.status.name.toUpperCase()}'),
            const SizedBox(height: 16),
            const Text('Activities Done:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (visit.activitiesDone != null && _activities.isNotEmpty)
              ...visit.activitiesDone!.map((id) {
                final matched = _activities.firstWhere(
                      (a) => a.id == id,
                  orElse: () => Activity(id: id, description: 'Unknown Activity'),
                );
                return Text('• ${matched.description}');
              }),
            const SizedBox(height: 16),
            if (visit.notes != null && visit.notes!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(visit.notes!),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
