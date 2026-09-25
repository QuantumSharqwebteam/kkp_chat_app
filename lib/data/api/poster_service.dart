import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kkpchatapp/data/api/api_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/poster_model.dart';

class PosterService {
  final String? baseUrl = dotenv.env['BASE_URL'];
  final http.Client client;

  PosterService({http.Client? httpClient})
      : client = httpClient ?? ApiClient.create();

  /// Fetches all posters from the backend
  Future<List<PosterModel>> getAllPosters() async {
    final url = Uri.parse('$baseUrl/poster/getAll');
    final token = await LocalDbHelper.getToken();

    if (token == null) {
      debugPrint('⚠️ Token not found. Returning empty poster list.');
      return [];
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await client.get(url, headers: headers);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['message'];

        if (data is List) {
          return data.map((e) => PosterModel.fromJson(e)).toList();
        } else {
          debugPrint('⚠️ Unexpected response format: $body');
          return [];
        }
      } else {
        debugPrint(
            '❌ Failed to fetch posters. Status: ${response.statusCode}, Body: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Exception while fetching posters: $e');
      return [];
    }
  }

  /// Add a new poster
  Future<bool> addPoster(String mediaUrl) async {
    final url = Uri.parse('$baseUrl/poster/add');
    final token = await LocalDbHelper.getToken();

    if (token == null) {
      debugPrint('⚠️ Token not found. Cannot add poster.');
      return false;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'mediaUrl': mediaUrl,
    });

    try {
      final response = await client.post(url, headers: headers, body: body);

      if (response.statusCode == 201) {
        debugPrint('✅ Poster added successfully.');
        return true;
      } else {
        debugPrint(
            '❌ Failed to add poster. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception while adding poster: $e');
      return false;
    }
  }

  /// Delete a poster by its ID
  Future<bool> deletePoster(String id) async {
    final url = Uri.parse('$baseUrl/poster/delete/$id');
    final token = await LocalDbHelper.getToken();

    if (token == null) {
      debugPrint('⚠️ Token not found. Cannot delete poster.');
      return false;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await client.delete(url, headers: headers);

      if (response.statusCode == 200) {
        debugPrint('✅ Poster deleted successfully.');
        return true;
      } else {
        debugPrint(
            '❌ Failed to delete poster. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception while deleting poster: $e');
      return false;
    }
  }
}
