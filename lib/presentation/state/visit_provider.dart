import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/models/visit.dart';
import '../../data/repositories/visit_repository.dart';
import '../../data/services/api_service.dart';

final visitListProvider = StateNotifierProvider<VisitNotifier, List<Visit>>((ref) {
  return VisitNotifier();
});
final isSyncingProvider = StateProvider<bool>((ref) => false);
final syncStatusProvider = StateProvider<String?>((ref) => null);


class VisitNotifier extends StateNotifier<List<Visit>> {
  VisitNotifier() : super([]);

  final _repo = VisitRepository(ApiService());

  Future<void> loadVisits() async {
    final repo = VisitRepository(ApiService());
    final visits = await repo.getVisits();
    state = visits;
  }

  Future<void> addVisit(Visit visit) async {
    final box = Hive.box<Visit>('visits');
    await box.add(visit);
    state = box.values.toList(); // Update UI state
  }

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
          await visit.delete();
          await box.add(updated);
          successCount++;
        } else {
          failCount++;
        }
      } catch (_) {
        failCount++;
      }
    }

    state = box.values.toList();
    syncingController.state = false;

    if (successCount > 0 && failCount == 0) {
      syncStatusController.state = 'Visits synced successfully';
    } else if (successCount > 0 && failCount > 0) {
      syncStatusController.state = 'Some visits synced, some failed';
    } else if (failCount > 0) {
      syncStatusController.state = 'Visit sync failed';
    }
  }





}

final visitFilterProvider = StateProvider<VisitStatus?>((ref) => null);
final visitSearchQueryProvider = StateProvider<String>((ref) => '');
final visitDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);