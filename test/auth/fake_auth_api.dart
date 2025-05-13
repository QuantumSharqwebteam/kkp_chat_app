import 'dart:convert';

import 'package:kkpchatapp/core/network/auth_api.dart';
import 'package:http/http.dart' as http;
import 'package:kkpchatapp/data/models/address_model.dart';
import 'package:kkpchatapp/data/models/agent.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MockClient extends Mock implements http.Client {}

class FakeAuthApi extends AuthApi {
  final MockClient mockClient;

  FakeAuthApi({required this.mockClient}) : super(client: mockClient);

  @override
  Future<Map<String, dynamic>> login(
      {required String email, required String password}) async {
    final response = {
      'message': 'User logged in successfully',
      'token': 'sample_token',
      'role': '0'
    };

    when(mockClient.post(
      Uri.parse('${dotenv.env['BASE_URL']}/user/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    )).thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    return response;
  }

  @override
  Future<Map<String, dynamic>> signup(
      {required String email, required String password}) async {
    final response = {
      'message': 'User signed up successfully',
    };

    when(mockClient.post(
      Uri.parse('${dotenv.env['BASE_URL']}/user/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    )).thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    return response;
  }

  @override
  Future<Map<String, dynamic>> updateDetails({
    String? name,
    String? number,
    String? customerType,
    String? gstNo,
    String? panNo,
    String? profileUrl,
    Address? address,
  }) async {
    final response = {
      'message': 'User details updated successfully',
    };

    when(mockClient.put(
      Uri.parse('${dotenv.env['BASE_URL']}/user/updateUserDetails'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer sample_token',
      },
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    return response;
  }

  @override
  Future<Map<String, dynamic>> forgetPassword(
      {required String email, required String password}) async {
    final response = {
      'message': 'Password updated successfully',
    };

    when(mockClient.post(
      Uri.parse('${dotenv.env['BASE_URL']}/user/changePassword'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    )).thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    return response;
  }

  @override
  Future<Map<String, dynamic>> sendOtp({required String email}) async {
    final response = {
      'message': 'OTP sent successfully',
    };

    when(mockClient.get(
      Uri.parse('${dotenv.env['BASE_URL']}/user/getOTP/$email'),
      headers: {'Content-Type': 'application/json'},
    )).thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    return response;
  }

  @override
  Future<Profile> getUserInfo() async {
    final response = {
      'message': {'name': 'John Doe', 'email': 'john@example.com'},
    };

    when(mockClient.get(
      Uri.parse('${dotenv.env['BASE_URL']}/user/getInfo'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer sample_token',
      },
    )).thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    return Profile.fromJson(response['message']!);
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(
      {required String email, required int otp}) async {
    final response = {
      'message': 'OTP verified successfully',
    };

    when(mockClient.post(
      Uri.parse('${dotenv.env['BASE_URL']}/user/verifyOtp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    )).thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    return response;
  }

  @override
  Future<List<Agent>> getAgent() async {
    final response = {
      'message': [
        {'name': 'Agent 1', 'email': 'agent1@example.com'},
        {'name': 'Agent 2', 'email': 'agent2@example.com'},
      ],
    };

    when(mockClient.get(
      Uri.parse('${dotenv.env['BASE_URL']}/user/getAgent'),
      headers: {'Content-Type': 'application/json'},
    )).thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    return parseAgents(jsonEncode(response['message']));
  }

  @override
  Future<Map<String, dynamic>> addAgent(
      {required Map<String, dynamic> body}) async {
    final response = {
      'message': 'Agent added successfully',
    };

    when(mockClient.post(
      Uri.parse('${dotenv.env['BASE_URL']}/user/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    )).thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    return response;
  }

  @override
  Future<Map<String, dynamic>> assignAgent({required String email}) async {
    final response = {
      'message': 'Agent assigned successfully',
    };

    when(mockClient.post(
      Uri.parse('${dotenv.env['BASE_URL']}/user/assignAgent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'agentNames': [email]
      }),
    )).thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    return response;
  }

  @override
  Future<bool> removeAssignedAgent({required String email}) async {
    final response = {
      'status': 200,
      'message': 'Agent removed successfully',
    };

    when(mockClient.put(
      Uri.parse('${dotenv.env['BASE_URL']}/user/removeAgent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'agentNames': [email]
      }),
    )).thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    return true;
  }

  @override
  Future<List<dynamic>> getUsersByRole({required String role}) async {
    final response = {
      'message': [
        {'name': 'User 1', 'email': 'user1@example.com'},
        {'name': 'User 2', 'email': 'user2@example.com'},
      ],
    };

    when(mockClient.post(
      Uri.parse('${dotenv.env['BASE_URL']}/user/getByRole'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'role': role}),
    )).thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    return response['message']!;
  }

  @override
  Future<List<dynamic>> getUsersByAgentId({required String agentEmail}) async {
    final response = {
      'message': [
        {'name': 'User 1', 'email': 'user1@example.com'},
        {'name': 'User 2', 'email': 'user2@example.com'},
      ],
    };

    when(mockClient.get(
      Uri.parse('${dotenv.env['BASE_URL']}/user/getUsersByAgentId/$agentEmail'),
      headers: {'Content-Type': 'application/json'},
    )).thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    return response['message']!;
  }

  @override
  Future<Map<String, dynamic>> deleteUserAccount(
      String email, String password) async {
    final response = {
      'message': 'User account deleted successfully',
    };

    when(mockClient.delete(
      Uri.parse('${dotenv.env['BASE_URL']}/user/deleteUserAccount'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer sample_token',
      },
      body: jsonEncode({'email': email, 'password': password}),
    )).thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    return response;
  }

  @override
  Future<Map<String, dynamic>> deleteAgent(String email) async {
    final response = {
      'message': 'Agent deleted successfully',
    };

    when(mockClient.delete(
      Uri.parse('${dotenv.env['BASE_URL']}/agent/delete'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer sample_token',
      },
      body: jsonEncode({'email': email}),
    )).thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    return response;
  }

  @override
  Future<Map<String, dynamic>> getNotifications() async {
    final response = {
      'notifications': [
        {'id': '1', 'message': 'Notification 1'},
        {'id': '2', 'message': 'Notification 2'},
      ],
    };

    when(mockClient.get(
      Uri.parse('${dotenv.env['BASE_URL']}/user/getNotification'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer sample_token',
      },
    )).thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    return response;
  }

  @override
  Future<Map<String, dynamic>> updateNotificationRead(
      {required String notificationId}) async {
    final response = {
      'message': 'Notification marked as read',
    };

    when(mockClient.put(
      Uri.parse(
          '${dotenv.env['BASE_URL']}/user/updateNotification/$notificationId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer sample_token',
      },
    )).thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    return response;
  }
}
