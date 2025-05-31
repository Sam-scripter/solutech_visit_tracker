import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/models/visit.dart';
import '../state/connectivity_provider.dart';
import '../state/visit_provider.dart';
import '../widgets/visit_card.dart';

/// [VisitListScreen] displays all visits with options to filter, search, and sync.
///
/// Features:
/// - Filtering by status, date, sync, and keyword
/// - Search bar to match visit location or notes
/// - Date range picker
/// - Sync status indicator
/// - Summary stats for visit statuses
class VisitListScreen extends ConsumerStatefulWidget {
  const VisitListScreen({super.key});

  @override
  ConsumerState<VisitListScreen> createState() => _VisitListScreenState();
}

class _VisitListScreenState extends ConsumerState<VisitListScreen> {
  bool _showOnlySynced = false;
  bool _showOnlyUnsynced = false;
  bool _hasConnectedListener = false;


  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(visitListProvider.notifier).loadVisitsAndMaybeSync(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityProvider);
    final result = connectivity.asData?.value;
    final isOnline = result == ConnectivityResult.wifi || result == ConnectivityResult.mobile;

    if (!_hasConnectedListener) {
      _hasConnectedListener = true;
      ref.listen<AsyncValue<ConnectivityResult>>(connectivityProvider, (prev, next) {
        final result = next.asData?.value;

        if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
          ref.read(visitListProvider.notifier).syncUnsyncedVisits(ref.read);
        }
      });
    }

    final visits = ref.watch(visitListProvider);
    final filter = ref.watch(visitFilterProvider);
    final query = ref.watch(visitSearchQueryProvider);
    final dateRange = ref.watch(visitDateRangeProvider);
    final isSyncing = ref.watch(isSyncingProvider);

    final filteredVisits = visits.where((v) {
      final matchesStatus = filter == null || v.status == filter;
      final matchesQuery = query.isEmpty ||
          v.location.toLowerCase().contains(query.toLowerCase()) ||
          v.notes?.toLowerCase().contains(query.toLowerCase()) == true;
      final matchesDate = dateRange == null ||
          (v.visitDate.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
              v.visitDate.isBefore(dateRange.end.add(const Duration(days: 1))));
      final matchesSync = _showOnlySynced ? v.isSynced : !_showOnlyUnsynced || !v.isSynced;
      return matchesStatus && matchesQuery && matchesDate && matchesSync;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Visits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final query = await showSearch(
                context: context,
                delegate: VisitSearchDelegate(ref),
              );
              if (query != null) {
                ref.read(visitSearchQueryProvider.notifier).state = query;
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _showOnlySynced = value == 'Synced';
                _showOnlyUnsynced = value == 'Unsynced';
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              const PopupMenuItem(value: 'Synced', child: Text('Only Synced')),
              const PopupMenuItem(value: 'Unsynced', child: Text('Only Unsynced')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(visitListProvider.notifier).syncAndRefresh(ref);
        },
        child: Column(
          children: [
            isOnline ? const SizedBox.shrink() : _buildConnectivityBanner(),
            if (isSyncing)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Syncing visits...'),
                  ],
                ),
              ),
            _buildStatsCard(visits),
            if (filter != null || query.isNotEmpty || dateRange != null || _showOnlySynced || _showOnlyUnsynced)
              TextButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
                onPressed: () {
                  ref.read(visitFilterProvider.notifier).state = null;
                  ref.read(visitSearchQueryProvider.notifier).state = '';
                  ref.read(visitDateRangeProvider.notifier).state = null;
                  setState(() {
                    _showOnlySynced = false;
                    _showOnlyUnsynced = false;
                  });
                },
              ),
            Expanded(
              child: filteredVisits.isEmpty
                  ? const Center(child: Text('No visits match this filter.'))
                  : ListView.builder(
                itemCount: filteredVisits.length,
                itemBuilder: (context, index) {
                  return VisitCard(visit: filteredVisits[index]);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.date_range),
        label: const Text('Filter by Date'),
        onPressed: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2022),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            ref.read(visitDateRangeProvider.notifier).state = picked;
          }
        },
      ),
    );
  }

  Widget _buildStatsCard(List<Visit> visits) {
    final total = visits.length;
    final completed = visits.where((v) => v.status == VisitStatus.completed).length;
    final pending = visits.where((v) => v.status == VisitStatus.pending).length;
    final cancelled = visits.where((v) => v.status == VisitStatus.cancelled).length;

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatTile(Icons.list, 'Total', total, Colors.grey, () {
              ref.read(visitFilterProvider.notifier).state = null;
            }, ref.watch(visitFilterProvider) == null),
            _buildStatTile(Icons.check_circle, 'Completed', completed, Colors.green, () {
              ref.read(visitFilterProvider.notifier).state = VisitStatus.completed;
            }, ref.watch(visitFilterProvider) == VisitStatus.completed),
            _buildStatTile(Icons.schedule, 'Pending', pending, Colors.orange, () {
              ref.read(visitFilterProvider.notifier).state = VisitStatus.pending;
            }, ref.watch(visitFilterProvider) == VisitStatus.pending),
            _buildStatTile(Icons.cancel, 'Cancelled', cancelled, Colors.red, () {
              ref.read(visitFilterProvider.notifier).state = VisitStatus.cancelled;
            }, ref.watch(visitFilterProvider) == VisitStatus.cancelled),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(IconData icon, String label, int count, Color color, VoidCallback onTap, bool selected) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: selected
            ? BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        )
            : null,
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectivityBanner() {

    return Container(
      width: double.infinity,
      color: Colors.red.shade100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Offline mode',
            style: TextStyle(
              color: Colors.red.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

}

/// [VisitSearchDelegate] provides in-app search for visits by location or notes.
class VisitSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;
  VisitSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => query = '',
    ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, ''),
  );

  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return const SizedBox();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final allVisits = ref.watch(visitListProvider);
    final suggestions = allVisits.where((v) =>
    v.location.toLowerCase().contains(query.toLowerCase()) ||
        v.notes?.toLowerCase().contains(query.toLowerCase()) == true);

    return ListView(
      children: suggestions
          .map((v) => ListTile(
        title: Text(v.location),
        subtitle: Text(v.notes ?? ''),
        onTap: () {
          query = v.location;
          showResults(context);
        },
      ))
          .toList(),
    );
  }
}