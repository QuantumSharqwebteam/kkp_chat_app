import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/complaint_model.dart';

class ComplaintService {
  static const String baseUrl = "http://54.234.201.60:5000";

  Future<List<ComplaintModel>> getAllComplaints() async {
    final token = await LocalDbHelper.getToken();
    debugPrint('AuthToken: $token');
    final response = await http.get(
      Uri.parse('$baseUrl/complaint/getAll'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['message'] as List<dynamic>;
      return data.map((e) => ComplaintModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load complaints");
    }
  }

  Future<bool> submitComplaint(
      {required String subject, required String description}) async {
    final token = await LocalDbHelper.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/complaint/add'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "subject": subject,
        "description": description,
      }),
    );
    return response.statusCode == 200;
  }
}
