import 'package:hive/hive.dart';

part 'customer.g.dart';


/// the customer model
@HiveType(typeId: 2)
class Customer extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  Customer({required this.id, required this.name});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
    );
  }
}
