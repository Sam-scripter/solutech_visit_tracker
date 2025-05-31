import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../models/activity.dart';
import '../models/customer.dart';
import '../models/visit.dart';

/// [ApiService] handles all HTTP interactions with the Supabase backend.
/// It provides methods for CRUD operations on visits, customers, and activities.
class ApiService {

  /// Sends a POST request to create a new visit in the backend.
  ///
  /// Returns `true` if the visit was successfully created (HTTP 200 or 201).
  /// Returns `false` otherwise and prints the error response.
  Future<bool> postVisit(Visit visit) async {
    final url = Uri.parse('$baseUrl/visits');
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(visit.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      print('Failed to post visit: ${response.body}');
      return false;
    }
  }

  /// Fetches a list of all customers from the Supabase API.
  ///
  /// Returns a `List<Customer>` on success.
  /// Throws an [Exception] if the request fails.
  Future<List<Customer>> fetchCustomers() async {
    final url = Uri.parse('$baseUrl/customers');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Customer.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load customers');
    }
  }

  /// Fetches a list of all activities from the Supabase API.
  ///
  /// Returns a `List<Activity>` on success.
  /// Throws an [Exception] if the request fails.
  Future<List<Activity>> fetchActivities() async {
    final url = Uri.parse('$baseUrl/activities');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Activity.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load activities');
    }
  }

  /// Fetches all visits from the Supabase API, ordered by `visit_date` descending.
  ///
  /// Returns a `List<Visit>` on success.
  /// Throws an [Exception] if the request fails.
  Future<List<Visit>> fetchVisits() async {
    final url = Uri.parse('$baseUrl/visits?order=visit_date.desc');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Visit.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load visits');
    }
  }
}
