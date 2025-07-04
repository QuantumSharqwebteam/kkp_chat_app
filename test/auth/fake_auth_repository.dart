import 'package:flutter_test/flutter_test.dart';
import 'package:kkpchatapp/data/models/address_model.dart';
import 'package:kkpchatapp/data/models/notification_model.dart';

class FakeAuthRepository {
  Future<Map<String, dynamic>> login(
      {required String email, required String password}) async {
    // Simulate different login responses
    if (email == "valid@example.com" && password == "validpassword") {
      return {
        'message': 'User logged in successfully',
        'token': 'fakeToken',
        'role': '0'
      };
    } else if (email == "invalid@example.com") {
      return {
        'message': 'Invalid email',
      };
    } else if (password == "wrongpassword") {
      return {
        'message': 'Invalid password',
      };
    } else {
      return {
        'message': 'Unknown error',
      };
    }
  }

  Future<Map<String, dynamic>> signup(
      {required String email, required String password}) async {
    // Simulate different signup responses
    if (email == "valid@example.com" && password == "validpassword") {
      return {
        'message': 'User signed up successfully',
        'token': 'fakeToken',
      };
    } else if (email == "exists@example.com") {
      return {
        'status': 400,
        'message': 'Email already exists',
      };
    } else {
      return {
        'message': 'Unknown error',
      };
    }
  }

  Future<Map<String, dynamic>> sendOtp({required String email}) async {
    // Simulate sending OTP
    if (email == "valid@example.com") {
      return {
        'message': 'OTP sent',
      };
    } else {
      return {
        'message': 'Failed to send OTP',
      };
    }
  }

  Future<Map<String, dynamic>> updateUserDetails({
    String? name,
    String? number,
    String? customerType,
    String? gstNo,
    String? panNo,
    String? profileUrl,
    Address? address,
  }) async {
    // Simulate updating user details
    if (name != null) {
      return {
        'message': 'Item updated successfully',
        'data': {'name': name},
      };
    } else {
      return {
        'message': 'Failed to update user details',
      };
    }
  }

  Future<Map<String, dynamic>> verifyOtp(
      {required String email, required int otp}) async {
    // Simulate different OTP verification responses
    if (otp == 123456) {
      return {
        'message': 'OTP Verified Successfully!',
      };
    } else {
      return {
        'message': 'Invalid OTP',
      };
    }
  }

  List<NotificationModel> fakeNotifications = [
    NotificationModel(id: '1', title: 'Test 1', viewed: false),
    NotificationModel(id: '2', title: 'Test 2', viewed: true),
  ];

  Future<List<NotificationModel>> getParsedNotifications() async {
    return fakeNotifications;
  }

  Future<Map<String, dynamic>> updateNotificationRead(String id) async {
    fakeNotifications = fakeNotifications.map((n) {
      if (n.id == id) {
        return NotificationModel(
          id: n.id,
          title: n.title,
          viewed: true,
        );
      }
      return n;
    }).toList();
    return {'status': 'success'};
  }
}
