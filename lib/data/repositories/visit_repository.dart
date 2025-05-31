import 'package:hive/hive.dart';

import '../models/activity.dart';
import '../models/customer.dart';
import '../models/visit.dart';
import '../services/api_service.dart';

/// Repository class responsible for managing visit-related operations.
/// It abstracts API and local storage interactions.
class VisitRepository {
  final ApiService _apiService;

  /// Constructs a [VisitRepository] with a given [ApiService] instance.
  VisitRepository(this._apiService);

  /// Submits a visit to the remote server via API.
  ///
  /// Returns `true` if the request was successful, otherwise `false`.
  Future<bool> submitVisit(Visit visit) async {
    try {
      return await _apiService.postVisit(visit);
    } catch (e) {
      print('Visit submission failed: $e');
      return false;
    }
  }

  /// Fetches a list of customers from the API.
  ///
  /// Returns a list of [Customer] objects.
  Future<List<Customer>> getCustomers() async {
    return await _apiService.fetchCustomers();
  }

  /// Fetches a list of available activities from the API.
  ///
  /// Returns a list of [Activity] objects.
  Future<List<Activity>> getActivities() async {
    return await _apiService.fetchActivities();
  }

  /// Fetches all visits from the remote API.
  ///
  /// Returns a list of [Visit] objects.
  Future<List<Visit>> getVisits() async {
    return await _apiService.fetchVisits();
  }

  /// Saves a visit locally using Hive.
  ///
  /// This is used to support offline data persistence.
  Future<void> saveVisitLocally(Visit visit) async {
    final box = Hive.box<Visit>('visits');
    await box.add(visit);
  }

  /// Retrieves all visits stored locally from the Hive box.
  ///
  /// Returns a list of [Visit] objects saved offline.
  Future<List<Visit>> getAllLocalVisits() async {
    final box = Hive.box<Visit>('visits');
    return box.values.toList();
  }

  /// Syncs visits that were created offline and not yet sent to the server.
  ///
  /// This attempts to POST each unsynced visit. If successful, it replaces the
  /// unsynced entry with a synced version marked with `isSynced: true`.
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
          await visit.delete(); // Remove old unsynced visit
          await box.add(updated); // Add new synced visit
        }
      } catch (_) {
        // Ignore error; visit remains unsynced for future retries
      }
    }
  }
}
