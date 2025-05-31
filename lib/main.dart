import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:visits_tracker_app/presentation/screens/home_screen.dart';
import 'package:visits_tracker_app/presentation/state/connectivity_provider.dart';
import 'package:visits_tracker_app/presentation/state/visit_provider.dart';

import 'data/models/activity.dart';
import 'data/models/customer.dart';
import 'data/models/visit.dart';

/// The entry point of the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and register custom adapters.
  await Hive.initFlutter();
  Hive.registerAdapter(VisitStatusAdapter());
  Hive.registerAdapter(VisitAdapter());
  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(ActivityAdapter());

  // Open the 'visits, customers and activities' Hive box to store visit data locally.
  await Hive.openBox<Visit>('visits');
  await Hive.openBox<Customer>('customers');
  await Hive.openBox<Activity>('activities');

  // Launch the app wrapped with Riverpod's ProviderScope.
  runApp(
    ProviderScope(
      observers: [SyncOnConnectivityObserver()],
      child: const MyApp(),
    ),
  );
}

/// Root widget of the app.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

/// [SyncOnConnectivityObserver] listens to connectivity changes
/// and triggers syncing of unsynced visits when network becomes available.
///
/// This allows background sync to happen automatically when online.
class SyncOnConnectivityObserver extends ProviderObserver {
  @override
  void didAddProvider(ProviderBase provider, Object? value, ProviderContainer container) {
    if (provider.name == 'connectivityProvider') {
      container.listen<AsyncValue<ConnectivityResult>>(
        connectivityProvider,
            (prev, next) {
          final result = next.asData?.value;
          if (result == ConnectivityResult.wifi || result == ConnectivityResult.mobile) {
            container.read(visitListProvider.notifier).syncAndRefreshIfOnline(container.read);
          }
        },
        fireImmediately: true,
      );
    }
  }
}

