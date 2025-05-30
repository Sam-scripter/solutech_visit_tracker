import 'package:flutter/material.dart';
import 'package:visits_tracker_app/presentation/screens/visit_form_screen.dart';
import 'visit_list_screen.dart';

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
