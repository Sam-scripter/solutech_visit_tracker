import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../../data/models/visit.dart';
import '../../data/models/customer.dart';
import '../../data/models/activity.dart';
import '../../data/services/api_service.dart';
import '../../data/repositories/visit_repository.dart';

/// [VisitFormScreen] allows a user to create and save a new visit.
///
/// It supports selecting a customer, specifying visit date & time, status,
/// location, activities, and optional notes. Visits are saved locally (offline)
/// and flagged for later sync to the backend.
class VisitFormScreen extends StatefulWidget {
  const VisitFormScreen({super.key});

  @override
  State<VisitFormScreen> createState() => _VisitFormScreenState();
}

class _VisitFormScreenState extends State<VisitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  Customer? _selectedCustomer;
  List<Activity> _selectedActivities = [];
  VisitStatus _status = VisitStatus.completed;
  DateTime _visitDate = DateTime.now();
  TimeOfDay _visitTime = TimeOfDay.now();
  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _isOnline = true;
  String? _errorMessage;

  List<Customer> _customers = [];
  List<Activity> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// Loads customers and activities from the repository.
  ///
  /// These are used to populate dropdowns and chips in the form.
  Future<void> _loadInitialData() async {
    final customerBox = Hive.box<Customer>('customers');
    final activityBox = Hive.box<Activity>('activities');

    try {
      final connectivity = await Connectivity().checkConnectivity();
      _isOnline = connectivity[0] == ConnectivityResult.mobile || connectivity[0] == ConnectivityResult.wifi;
      final repo = VisitRepository(ApiService());

      try {
        final fetchedCustomers = await repo.getCustomers();
        await customerBox.clear();
        await customerBox.addAll(fetchedCustomers);
      } catch (e) {
        debugPrint('Customer fetch failed: $e');
      }

      try {
        final fetchedActivities = await repo.getActivities();
        await activityBox.clear();
        await activityBox.addAll(fetchedActivities);
      } catch (e) {
        debugPrint('Activity fetch failed: $e');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load initial data: ${e.toString()}';
      });
    } finally {
      _customers = customerBox.values.toList();
      _activities = activityBox.values.toList();
      if (_customers.isNotEmpty) _selectedCustomer = _customers.first;

      if (mounted) setState(() => _isLoading = false);
    }
  }


  /// Validates the form, constructs a [Visit], and saves it to local storage (Hive).
  ///
  /// The visit is flagged as `isSynced: false` for background sync.
  Future<void> _submitVisit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      setState(() => _errorMessage = 'Please select a customer');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final visit = Visit(
        customerId: _selectedCustomer!.id,
        visitDate: DateTime(
          _visitDate.year,
          _visitDate.month,
          _visitDate.day,
          _visitTime.hour,
          _visitTime.minute,
        ),
        status: _status,
        location: _locationController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        activitiesDone: _selectedActivities.map((a) => a.id).toList(),
      );

      final box = await Hive.openBox<Visit>('visits');
      final result = await Connectivity().checkConnectivity();
      print('Connectivity: $result');

      if (result[0] == ConnectivityResult.mobile ||
          result[0] == ConnectivityResult.wifi) {
        // Try to upload to Supabase immediately
        final repo = VisitRepository(ApiService());
        print("REPO: $repo");
        print("ATTEMPTING SUCCESS....");
        final success = await repo.submitVisit(visit);
        print("SUCCESSFUL: $success");
        debugPrint('Visit upload success: $success');

        if (success) {
          // Add to local store as synced for reference/history
          await box.add(visit.copyWith(isSynced: true));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Visit synced successfully!')),
          );
        } else {
          // Save locally as unsynced
          print("UNSUCCESSFUL: $success");
          await box.add(visit.copyWith(isSynced: false));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved locally. Will sync later.')),
          );
        }
      } else {
        // Offline – save locally
        print("DID NOT SAVE ONLINE, JUST SAVING OFFLINE");
        await box.add(visit.copyWith(isSynced: false));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline: saved locally. Will sync when online.'),
          ),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _errorMessage = 'Submission failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Prompts the user to select a new visit date.
  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() => _visitDate = pickedDate);
    }
  }

  /// Prompts the user to select a new visit time.
  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _visitTime,
    );
    if (pickedTime != null) {
      setState(() => _visitTime = pickedTime);
    }
  }
  Widget _buildOfflineBanner() {
    if (_isOnline) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: const [
          Icon(Icons.wifi_off, color: Colors.red),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are offline. Visit will be saved locally and synced when back online.',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null && _customers.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Visit')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Visit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(

          key: _formKey,
          child: ListView(
            children: [
              _buildOfflineBanner(),
              SizedBox(height: 10),

              /// Dropdown to select a customer
              DropdownButtonFormField<Customer>(
                value: _selectedCustomer,
                decoration: const InputDecoration(
                  labelText: 'Customer',
                  border: OutlineInputBorder(),
                ),
                items:
                    _customers
                        .map(
                          (customer) => DropdownMenuItem(
                            value: customer,
                            child: Text(customer.name),
                          ),
                        )
                        .toList(),
                onChanged:
                    (customer) => setState(() => _selectedCustomer = customer),
                validator:
                    (value) =>
                        value == null ? 'Please select a customer' : null,
              ),
              const SizedBox(height: 20),

              /// Date & Time selectors
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Visit Date'),
                        Text(DateFormat.yMMMd().format(_visitDate)),
                        ElevatedButton(
                          onPressed: _pickDate,
                          child: const Text('Select Date'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Visit Time'),
                        Text(_visitTime.format(context)),
                        ElevatedButton(
                          onPressed: _pickTime,
                          child: const Text('Select Time'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              /// Dropdown to select visit status
              DropdownButtonFormField<VisitStatus>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items:
                    VisitStatus.values
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                onChanged:
                    (status) => setState(
                      () => _status = status ?? VisitStatus.completed,
                    ),
              ),
              const SizedBox(height: 20),

              /// Text input for location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              /// Activity selector using chips
              const Text('Activities:'),
              Wrap(
                spacing: 8,
                children:
                    _activities
                        .map(
                          (activity) => FilterChip(
                            label: Text(activity.description),
                            selected: _selectedActivities.any(
                              (a) => a.id == activity.id,
                            ),
                            onSelected:
                                (selected) => setState(() {
                                  if (selected) {
                                    _selectedActivities = [
                                      ..._selectedActivities,
                                      activity,
                                    ];
                                  } else {
                                    _selectedActivities =
                                        _selectedActivities
                                            .where((a) => a.id != activity.id)
                                            .toList();
                                  }
                                }),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 20),

              ///notes input
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator:
                    (value) =>
                value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              /// Error message display
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),

              /// Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitVisit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child:
                    _isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text('SUBMIT VISIT'),
              ),
            ],
          ),

        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
