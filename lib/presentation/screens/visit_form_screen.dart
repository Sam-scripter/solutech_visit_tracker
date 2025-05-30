import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../../data/models/visit.dart';
import '../../data/models/customer.dart';
import '../../data/models/activity.dart';
import '../../data/services/api_service.dart';
import '../../data/repositories/visit_repository.dart';

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
  String? _errorMessage;

  List<Customer> _customers = [];
  List<Activity> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// Loads customer and activity data.
  /// Ideally these would use local cache with fallback to remote fetch.
  Future<void> _loadInitialData() async {
    try {
      final repo = VisitRepository(ApiService());
      _customers = await repo.getCustomers();
      _activities = await repo.getActivities();
      if (_customers.isNotEmpty) _selectedCustomer = _customers.first;
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load initial data: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Saves a visit locally and marks it as unsynced for background sync.
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
        isSynced: false, // Mark visit as unsynced initially
      );

      final box = await Hive.openBox<Visit>('visits');
      await box.add(visit);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit saved locally. Will sync when online.')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _errorMessage = 'Submission failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _visitTime,
    );
    if (pickedTime != null) {
      setState(() => _visitTime = pickedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
              DropdownButtonFormField<Customer>(
                value: _selectedCustomer,
                decoration: const InputDecoration(
                  labelText: 'Customer',
                  border: OutlineInputBorder(),
                ),
                items: _customers
                    .map((customer) => DropdownMenuItem(
                  value: customer,
                  child: Text(customer.name),
                ))
                    .toList(),
                onChanged: (customer) =>
                    setState(() => _selectedCustomer = customer),
                validator: (value) =>
                value == null ? 'Please select a customer' : null,
              ),
              const SizedBox(height: 20),

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

              DropdownButtonFormField<VisitStatus>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: VisitStatus.values
                    .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(
                    status.name.toUpperCase(),
                  ),
                ))
                    .toList(),
                onChanged: (status) =>
                    setState(() => _status = status ?? VisitStatus.completed),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              const Text('Activities:'),
              Wrap(
                spacing: 8,
                children: _activities
                    .map((activity) => FilterChip(
                  label: Text(activity.description),
                  selected: _selectedActivities
                      .any((a) => a.id == activity.id),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _selectedActivities = [..._selectedActivities, activity];
                    } else {
                      _selectedActivities = _selectedActivities
                          .where((a) => a.id != activity.id)
                          .toList();
                    }
                  }),
                ))
                    .toList(),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style:
                    TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitVisit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSubmitting
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
