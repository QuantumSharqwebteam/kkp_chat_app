import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';

class MeetingService {
  final String? baseUrl = dotenv.env['BASE_URL'];
  final http.Client client;

  MeetingService({http.Client? httpClient}) : client = httpClient ?? http.Client();

  // get All

  /// create meeting

  // delete meeteing

  //update meeting
}
