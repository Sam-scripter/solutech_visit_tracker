class Activity {
  final int id;
  final String description;

  Activity({required this.id, required this.description});

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      description: json['description'],
    );
  }
}
