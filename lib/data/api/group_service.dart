import 'package:kkpchatapp/core/network/api_helper.dart';
import 'package:kkpchatapp/core/services/logging_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';

class GroupService {
  final ApiHelper _apiHelper = ApiHelper();
  final LoggingService _logger = LoggingService.instance;

  Future<Map<String, String>> _authHeaders() async {
    final token = await LocalDbHelper.getToken();
    if (token == null) {
      throw Exception("No token found in storage");
    }
    return {"Authorization": "Bearer $token"};
  }

  /// 📝 Create a new group
  Future<ApiResponse<Map<String, dynamic>>> createGroup({
    required String groupName,
    required String groupDescription,
    required List<String> admins,
    required List<String> members,
    required String groupImage,
  }) async {
    final headers = await _authHeaders();
    final body = {
      "groupName": groupName,
      "groupDescription": groupDescription,
      "admins": admins,
      "members": members,
      "groupImage": groupImage,
    };
    _logger.logNetwork('Creating group: $groupName');
    return await _apiHelper.post<Map<String, dynamic>>(
      'group/add',
      body,
      headers: headers,
    );
  }

  /// 📋 Get all groups
  Future<ApiResponse<Map<String, dynamic>>> getAllGroups() async {
    final headers = await _authHeaders();
    _logger.logNetwork('Fetching all groups');
    return await _apiHelper.get<Map<String, dynamic>>(
      'group/getAll',
      headers: headers,
    );
  }

  /// 🔄 Update group
  Future<ApiResponse<Map<String, dynamic>>> updateGroup({
    required String id,
    String? groupName,
    String? groupDescription,
    String? groupImage,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{};
    if (groupName != null) body['groupName'] = groupName;
    if (groupDescription != null) body['groupDescription'] = groupDescription;
    if (groupImage != null) body['groupImage'] = groupImage;
    _logger.logNetwork('Updating group: $id');
    return await _apiHelper.put<Map<String, dynamic>>(
      'group/update/$id',
      body,
      headers: headers,
    );
  }

  /// 🗑️ Soft delete group
  Future<ApiResponse<Map<String, dynamic>>> deleteGroup(String id) async {
    final headers = await _authHeaders();
    _logger.logNetwork('Deleting group: $id');
    return await _apiHelper.delete<Map<String, dynamic>>(
      'group/delete/$id',
      headers: headers,
    );
  }

  /// 👥 Get user's groups
  Future<ApiResponse<Map<String, dynamic>>> getUsersGroups(String email) async {
    final headers = await _authHeaders();
    _logger.logNetwork('Fetching groups for user: $email');
    return await _apiHelper.get<Map<String, dynamic>>(
      'group/person/$email',
      headers: headers,
    );
  }

  /// 👤 Remove member from group
  Future<ApiResponse<Map<String, dynamic>>> removeMember({
    required String groupId,
    required String email,
  }) async {
    final headers = await _authHeaders();
    final body = {"userId": email};
    _logger.logNetwork('Removing member: $email from group: $groupId');
    return await _apiHelper.delete<Map<String, dynamic>>(
      'group/$groupId/member/remove',
      body: body,
      headers: headers,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> addMember({
    required String groupId,
    required String email,
  }) async {
    final headers = await _authHeaders();
    final body = {"userId": email};
    _logger.logNetwork('Adding member: $email to group: $groupId');
    return await _apiHelper.post<Map<String, dynamic>>(
      'group/$groupId/member/add',
      body,
      headers: headers,
    );
  }

  /// 👑 Add admin to group
  Future<ApiResponse<Map<String, dynamic>>> addAdmin({
    required String groupId,
    required String email,
  }) async {
    final headers = await _authHeaders();
    final body = {"userId": email};
    _logger.logNetwork('Adding admin: $email to group: $groupId');
    return await _apiHelper.post<Map<String, dynamic>>(
      'group/$groupId/admin/add',
      body,
      headers: headers,
    );
  }

  /// 👑 Remove admin from group
  Future<ApiResponse<Map<String, dynamic>>> removeAdmin({
    required String groupId,
    required String email,
  }) async {
    final headers = await _authHeaders();
    final body = {"userId": email};
    _logger.logNetwork('Removing admin: $email from group: $groupId');
    return await _apiHelper.delete<Map<String, dynamic>>(
      'group/$groupId/admin/remove',
      body: body,
      headers: headers,
    );
  }
}
