import 'package:hive/hive.dart';

part 'visit.g.dart';

@HiveType(typeId: 0)
enum VisitStatus {
  @HiveField(0)
  completed,
  @HiveField(1)
  pending,
  @HiveField(2)
  cancelled,
}

extension VisitStatusExtension on VisitStatus {
  String toApiString() {
    final name = this.name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }
}

@HiveType(typeId: 1)
class Visit extends HiveObject {
  @HiveField(0)
  final int? id;

  @HiveField(1)
  final int customerId;

  @HiveField(2)
  final DateTime visitDate;

  @HiveField(3)
  final VisitStatus status;

  @HiveField(4)
  final String location;

  @HiveField(5)
  final String? notes;

  @HiveField(6)
  final List<int>? activitiesDone;

  @HiveField(7)
  final bool isSynced;

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
      isSynced: true,
    );
  }
}
