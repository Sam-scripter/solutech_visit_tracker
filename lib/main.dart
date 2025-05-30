import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:visits_tracker_app/presentation/screens/home_screen.dart';
import 'package:visits_tracker_app/presentation/screens/visit_form_screen.dart';
import 'package:visits_tracker_app/presentation/screens/visit_list_screen.dart';
import 'package:visits_tracker_app/presentation/state/connectivity_provider.dart';
import 'package:visits_tracker_app/presentation/state/visit_provider.dart';

import 'data/models/visit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(VisitStatusAdapter());
  Hive.registerAdapter(VisitAdapter());
  await Hive.openBox<Visit>('visits');
  runApp(
      ProviderScope(
          observers: [SyncOnConnectivityObserver()],
          child: const MyApp()));
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class SyncOnConnectivityObserver extends ProviderObserver {
  @override
  void didAddProvider(ProviderBase provider, Object? value, ProviderContainer container) {
    if (provider == connectivityProvider) {
      container.listen<AsyncValue<ConnectivityResult>>(
        connectivityProvider,
            (prev, next) {
          if (next.value == ConnectivityResult.wifi || next.value == ConnectivityResult.mobile) {
            container.read(visitListProvider.notifier).syncUnsyncedVisits(container.read);
          }
        },
        fireImmediately: true,
      );

    }
  }
}

