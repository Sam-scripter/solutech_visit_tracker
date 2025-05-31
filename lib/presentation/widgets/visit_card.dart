import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/visit.dart';
import '../screens/visit_detail_screen.dart';

class VisitCard extends StatelessWidget {
  final Visit visit;

  const VisitCard({super.key, required this.visit});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: visit.isSynced
            ? const Icon(Icons.cloud_done, color: Colors.green)
            : const Icon(Icons.sync_problem, color: Colors.orange),

        title: Text(
          DateFormat.yMMMEd().format(visit.visitDate),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Status: ${visit.status.name} • Location: ${visit.location}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VisitDetailScreen(visit: visit),
            ),
          );
        },
      ),
    );
  }
}
