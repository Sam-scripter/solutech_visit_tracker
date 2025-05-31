import 'package:flutter/material.dart';
import 'package:visits_tracker_app/presentation/screens/visit_form_screen.dart';
import 'visit_list_screen.dart';

/// [HomeScreen] serves as the landing page of the Visit Tracker app.
///
/// It provides two main actions for the user:
/// - Navigate to the form for adding a new visit.
/// - Navigate to the screen that lists all existing visits.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Tracker Home'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Button to navigate to the [VisitFormScreen] for adding a new visit.
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VisitFormScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Visit'),
            ),

            const SizedBox(height: 16),

            /// Button to navigate to the [VisitListScreen] to view all visits.
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VisitListScreen()),
                );
              },
              icon: const Icon(Icons.list),
              label: const Text('Go to Visit List'),
            ),
          ],
        ),
      ),
    );
  }
}
