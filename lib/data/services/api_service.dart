import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity.dart';
import '../models/customer.dart';
import '../models/visit.dart';

class ApiService {
  static const String baseUrl = 'https://kqgbftwsodpttpqgqnbh.supabase.co/rest/v1';
  static const Map<String, String> headers = {
    'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtxZ2JmdHdzb2RwdHRwcWdxbmJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU5ODk5OTksImV4cCI6MjA2MTU2NTk5OX0.rwJSY4bJaNdB8jDn3YJJu_gKtznzm-dUKQb4OvRtP6c',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtxZ2JmdHdzb2RwdHRwcWdxbmJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU5ODk5OTksImV4cCI6MjA2MTU2NTk5OX0.rwJSY4bJaNdB8jDn3YJJu_gKtznzm-dUKQb4OvRtP6c',
    'Content-Type': 'application/json',
  };

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
