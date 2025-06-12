import 'package:kkpchatapp/core/network/auth_api.dart';
import 'package:kkpchatapp/data/models/address_model.dart';
import 'package:kkpchatapp/data/models/agent.dart';
import 'package:kkpchatapp/data/models/notification_model.dart';

class AuthRepository {
  final AuthApi _authApi;

  AuthRepository({AuthApi? authApi}) : _authApi = authApi ?? AuthApi();

  Future<Map<String, dynamic>> signup(
      {
        required String email,
       required String password,
       }) {
    return _authApi.signup(email: email, password: password);
  }

  Future<Map<String, dynamic>> login(
      {required String email, required String password}) {
    return _authApi.login(email: email, password: password);
  }

  Future<Map<String, dynamic>> updateUserDetails({
    String? name,
    String? number,
    String? customerType,
    String? gstNo,
    String? panNo,
    String? profileUrl,
    Address? address,
  }) {
    return _authApi.updateDetails(
      name: name,
      number: number,
      customerType: customerType,
      address: address,
      gstNo: gstNo,
      panNo: panNo,
      profileUrl: profileUrl,
    );
  }

  Future<Map<String, dynamic>> forgotPassword(
      {required String email, required String password}) {
    return _authApi.forgetPassword(email: email, password: password);
  }

  Future<Map<String, dynamic>> sendOtp({required String email}) {
    return _authApi.sendOtp(email: email);
  }

  Future<dynamic> getUserInfo() async {
    return await _authApi.getUserInfo();
  }

  Future<Map<String, dynamic>> verifyOtp(
      {required String email, required int otp}) {
    return _authApi.verifyOtp(email: email, otp: otp);
  }

  Future<Map<String, dynamic>> updatePassword(
      {required String currentPassword,
      required String newPassword,
      required String email}) {
    return _authApi.updatePasswordFromSettings(
        currentPassword, newPassword, email);
  }

  Future<Map<String, dynamic>> deleteAgentAccount(
      {required String agentEmail}) async {
    return _authApi.deleteAgent(agentEmail);
  }

  // to fetch list of users by agnetId for that particular agent
  Future<List<dynamic>> fetchUsersByAgentId(String agentEmail) async {
    return _authApi.getUsersByAgentId(agentEmail: agentEmail);
  }

  // to fetch list of users by role = "User", agnet , admin , "agnetHead"
  Future<List<dynamic>> fetchUsersByRole(String role) async {
    return _authApi.getUsersByRole(role: role);
  }

  Future<List<NotificationModel>> getParsedNotifications() async {
    final response = await _authApi.getNotifications();
    final List<dynamic> notificationsJson = response['notifications'] ?? [];
    return notificationsJson
        .map((json) => NotificationModel.fromJson(json))
        .toList();
  }

  Future<Map<String, dynamic>> updateNotificationRead(
      String notificationId) async {
    return await _authApi.updateNotificationRead(
        notificationId: notificationId);
  }

  Future<Map<String, dynamic>> updateFCMToken(String fcmToken) async {
    return await _authApi.updateFCMToken(fcmToken);
  }

  Future<Map<String, dynamic>> refreshToken(String oldToken) async {
    return await _authApi.refreshToken(oldToken);
  }

  Future<List<Agent>> getAgent() async {
    return await _authApi.getAgent();
  }

  Future<List<String>> fetchAssignedAgentList() async {
    return await _authApi.fetchAssignedAgentList();
  }

  Future<Map<String, dynamic>> addAgent(
      {required Map<String, dynamic> body}) async {
    return _authApi.addAgent(body: body);
  }

  Future<Map<String, dynamic>> assignAgent({required String email}) async {
    return _authApi.assignAgent(email: email);
  }

  Future<bool> removeAssignedAgent({required String email}) async {
    return _authApi.removeAssignedAgent(email: email);
  }

  Future<Map<String, dynamic>> deleteUserAccount(
      String email, String password, String feedback) async {
    return _authApi.deleteUserAccount(email, password, feedback);
  }
}
