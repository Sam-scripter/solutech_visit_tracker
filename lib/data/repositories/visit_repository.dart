import 'package:hive/hive.dart';

import '../models/activity.dart';
import '../models/customer.dart';
import '../models/visit.dart';
import '../services/api_service.dart';

class VisitRepository {
  final ApiService _apiService;

  VisitRepository(this._apiService);

  Future<bool> submitVisit(Visit visit) async {
    try {
      return await _apiService.postVisit(visit);
    } catch (e) {
      print('Visit submission failed: $e');
      return false;
    }
  }

  Future<List<Customer>> getCustomers() async {
    return await _apiService.fetchCustomers();
  }

  Future<List<Activity>> getActivities() async {
    return await _apiService.fetchActivities();
  }

  Future<List<Visit>> getVisits() async {
    return await _apiService.fetchVisits();
  }

  Future<void> saveVisitLocally(Visit visit) async {
    final box = Hive.box<Visit>('visits');
    await box.add(visit);
  }

  Future<List<Visit>> getAllLocalVisits() async {
    final box = Hive.box<Visit>('visits');
    return box.values.toList();
  }

  Future<void> syncUnsyncedVisits() async {
    final box = Hive.box<Visit>('visits');
    final unsynced = box.values.where((v) => !v.isSynced).toList();
    for (final visit in unsynced) {
      try {
        final success = await _apiService.postVisit(visit);
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
          await visit.delete(); // remove old
          await box.add(updated); // add synced version
        }
      } catch (_) {
        // keep unsynced
      }
    }
  }

}
