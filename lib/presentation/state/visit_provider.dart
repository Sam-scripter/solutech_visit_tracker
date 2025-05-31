import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/models/visit.dart';
import '../../data/repositories/visit_repository.dart';
import '../../data/services/api_service.dart';


/// Provides the list of visits (synced and local) managed by [VisitNotifier].
final visitListProvider = StateNotifierProvider<VisitNotifier, List<Visit>>((ref) {
  return VisitNotifier();
});

/// Indicates if the app is currently syncing unsynced visits.
final isSyncingProvider = StateProvider<bool>((ref) => false);

/// Holds a user-visible message about the sync result (success/failure).
final syncStatusProvider = StateProvider<String?>((ref) => null);

typedef Reader = T Function<T>(ProviderListenable<T>);

/// A notifier that manages the list of visits, including loading from remote,
/// adding new visits locally, and syncing offline visits to the backend.
class VisitNotifier extends StateNotifier<List<Visit>> {
  VisitNotifier() : super([]);

  final _repo = VisitRepository(ApiService());

  /// Loads visits from local Hive storage first.
  /// Then optionally syncs with remote if needed (handled elsewhere).
  Future<void> loadVisits() async {
    final box = await Hive.openBox<Visit>('visits');
    state = box.values.toList();
  }

  Future<void> loadVisitsAndMaybeSync(WidgetRef ref) async {
    final box = await Hive.openBox<Visit>('visits');
    state = box.values.toList();

    final result = await Connectivity().checkConnectivity();
    if (result[0] == ConnectivityResult.mobile || result[0] == ConnectivityResult.wifi) {
      await syncAndRefresh(ref);
    }
  }

  /// Adds a visit to the local Hive database and updates the UI state.
  Future<void> addVisit(Visit visit) async {
    final box = Hive.box<Visit>('visits');
    await box.add(visit);
    state = box.values.toList();
  }

  /// Syncs unsynced visits to Supabase, fetches latest from Supabase, updates Hive
  Future<void> syncAndRefresh(WidgetRef ref) async {
    final syncing = ref.read(isSyncingProvider.notifier);
    final syncMsg = ref.read(syncStatusProvider.notifier);
    syncing.state = true;
    syncMsg.state = null;

    final box = await Hive.openBox<Visit>('visits');
    final unsynced = box.values.where((v) => !v.isSynced).toList();

    int uploaded = 0;
    for (final visit in unsynced) {
      try {
        final success = await _repo.submitVisit(visit);
        if (success) {
          await visit.delete();
          await box.add(visit.copyWith(isSynced: true));
          uploaded++;
        }
      } catch (_) {}
    }

    try {
      final remoteVisits = await _repo.getVisits();
      await box.clear();
      for (final v in remoteVisits) {
        await box.add(v);
      }
      state = box.values.toList();
      syncMsg.state = uploaded > 0
          ? 'Synced $uploaded visits and refreshed.'
          : 'Refreshed from server.';
    } catch (e) {
      syncMsg.state = 'Failed to fetch latest visits.';
    } finally {
      syncing.state = false;
    }
  }

  /// Attempts to sync all unsynced visits in local storage to the backend.
  ///
  /// Updates UI state and notifies the user via [syncStatusProvider].
  Future<void> syncUnsyncedVisits(void Function(ProviderListenable<Object?>) read) async {
    final syncingController = read(isSyncingProvider.notifier) as StateController<bool>;
    final syncStatusController = read(syncStatusProvider.notifier) as StateController<String?>;

    syncingController.state = true;
    syncStatusController.state = null;

    final box = Hive.box<Visit>('visits');
    final unsynced = box.values.where((v) => !v.isSynced).toList();

    int successCount = 0;
    int failCount = 0;

    for (final visit in unsynced) {
      try {
        final success = await _repo.submitVisit(visit);
        if (success) {
          final updated = Visit(
            id: visit.id,
            customerId: visit.customerId,
            visitDate: visit.visitDate,
            status: visit.status,
            location: visit.location,
            notes: visit.notes,
            activitiesDone: visit.activitiesDone,
            isSynced: true,
          );
          await visit.delete(); // Delete the old unsynced entry
          await box.add(updated); // Save the synced entry
          successCount++;
        } else {
          failCount++;
        }
      } catch (_) {
        failCount++;
      }
    }

    // Refresh state with updated visits
    state = box.values.toList();
    syncingController.state = false;

    // Update user-visible sync message
    if (successCount > 0 && failCount == 0) {
      syncStatusController.state = 'Visits synced successfully';
    } else if (successCount > 0 && failCount > 0) {
      syncStatusController.state = 'Some visits synced, some failed';
    } else if (failCount > 0) {
      syncStatusController.state = 'Visit sync failed';
    }
  }

  Future<void> syncAndRefreshIfOnline(Reader read) async {
    final connectivity = await Connectivity().checkConnectivity();
    print("connectivity: $connectivity");
    if (connectivity[0] != ConnectivityResult.mobile ||
        connectivity[0] != ConnectivityResult.wifi) {
      return; // Don't sync if offline
    }

    await syncUnsyncedVisits(read); // Step 1: Upload unsynced visits

    try {
      final remoteVisits = await _repo.getVisits(); // Step 2: Get fresh from Supabase
      final box = await Hive.openBox<Visit>('visits');
      await box.clear();
      await box.addAll(remoteVisits);
      state = box.values.toList();
    } catch (e) {
      read(syncStatusProvider.notifier).state = 'Synced, but refresh failed.';
    }
  }


}



/// Filter provider for visit status (e.g., completed, pending, cancelled).
final visitFilterProvider = StateProvider<VisitStatus?>((ref) => null);

/// Search query string for filtering visits by location or notes.
final visitSearchQueryProvider = StateProvider<String>((ref) => '');

/// Date range filter for visits.
final visitDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);



