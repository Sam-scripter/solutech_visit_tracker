import 'package:hive/hive.dart';

part 'visit.g.dart';

/// Enumeration representing the status of a visit.
@HiveType(typeId: 0)
enum VisitStatus {
  @HiveField(0)
  completed,

  @HiveField(1)
  pending,

  @HiveField(2)
  cancelled,
}

/// Extension to convert VisitStatus enum to an API-compatible string.
extension VisitStatusExtension on VisitStatus {
  /// Converts the enum value to PascalCase string expected by the API.
  /// e.g., VisitStatus.completed → "Completed"
  String toApiString() {
    final name = this.name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }
}

/// Hive-storable model representing a customer visit.
@HiveType(typeId: 1)
class Visit extends HiveObject {
  /// Optional unique identifier for the visit (usually from the backend).
  @HiveField(0)
  final int? id;

  /// ID of the customer associated with the visit.
  @HiveField(1)
  final int customerId;

  /// Date and time of the visit.
  @HiveField(2)
  final DateTime visitDate;

  /// Status of the visit (completed, pending, cancelled).
  @HiveField(3)
  final VisitStatus status;

  /// Location where the visit took place.
  @HiveField(4)
  final String location;

  /// Optional notes taken during or after the visit.
  @HiveField(5)
  final String? notes;

  /// List of activity IDs completed during the visit.
  @HiveField(6)
  final List<int>? activitiesDone;

  /// Indicates whether this visit has been synced with the remote API.
  @HiveField(7)
  final bool isSynced;

  /// Constructor to create a Visit instance.
  Visit({
    this.id,
    required this.customerId,
    required this.visitDate,
    required this.status,
    required this.location,
    this.notes,
    this.activitiesDone,
    this.isSynced = true,
  });

  /// Converts this Visit to a JSON-compatible map for API submission.
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'customer_id': customerId,
    'visit_date': visitDate.toUtc().toIso8601String(),
    'status': status.toApiString(),
    'location': location,
    if (notes != null) 'notes': notes,
    if (activitiesDone != null)
      'activities_done': activitiesDone!.map((e) => e.toString()).toList(),
  };

  /// Creates a Visit instance from a JSON map (usually from the API).
  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'],
      customerId: json['customer_id'],
      visitDate: DateTime.parse(json['visit_date']).toLocal(),
      status: VisitStatus.values.firstWhere(
            (e) => e.name.toLowerCase() == json['status'].toString().toLowerCase(),
        orElse: () => VisitStatus.pending,
      ),
      location: json['location'],
      notes: json['notes'],
      activitiesDone: (json['activities_done'] as List<dynamic>?)
          ?.map((e) => int.tryParse(e.toString()) ?? -1)
          .where((id) => id > 0)
          .toList(),
      isSynced: true, // Default to true for data from API
    );
  }
}
/// Extension to add copyWith functionality to the Visit model.
extension VisitCopy on Visit {
  Visit copyWith({
    int? id,
    int? customerId,
    DateTime? visitDate,
    VisitStatus? status,
    String? location,
    String? notes,
    List<int>? activitiesDone,
    bool? isSynced,
  }) {
    return Visit(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      visitDate: visitDate ?? this.visitDate,
      status: status ?? this.status,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      activitiesDone: activitiesDone ?? this.activitiesDone,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
