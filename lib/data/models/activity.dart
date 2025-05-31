import 'package:hive/hive.dart';

part 'activity.g.dart';


/// the activity model
@HiveType(typeId: 3)
class Activity {

  @HiveField(0)
  final int id;

  @HiveField(1)
  final String description;

  Activity({required this.id, required this.description});

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      description: json['description'],
    );
  }
}
