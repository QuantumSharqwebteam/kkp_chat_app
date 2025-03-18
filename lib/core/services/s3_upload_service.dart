import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

class S3UploadService {
  final String accessKey = dotenv.env["AWS_ACCESS_KEY"]!;
  final String secretKey = dotenv.env["AWS_SECRET_KEY"]!;
  final String region = dotenv.env["AWS_REGION"]!;
  final String bucketName = dotenv.env["AWS_BUCKET_NAME"]!;

  Future<String?> uploadFile(File file) async {
    try {
      final String isoDate = _getIsoDate();
      final String shortDate = isoDate.substring(0, 8);
      String sanitizedFileName = file.path.split('/').last.replaceAll(
          RegExp(r'[^a-zA-Z0-9._-]'),
          '_'); //to remove all the unncessary charactes from the path causing issues for uploading image
      final String destinationKey =
          "uploads/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName";

      final String service = "s3";
      final String host = "$bucketName.s3.$region.amazonaws.com";
      final String endpoint = "https://$host/$destinationKey";

      // Detect MIME type
      final mimeType = lookupMimeType(file.path) ?? "application/octet-stream";

      // Read file bytes
      final List<int> fileBytes = await file.readAsBytes();
      final String payloadHash = sha256.convert(fileBytes).toString();

      // Step 1: Create Canonical Request
      final canonicalRequest =
          'PUT\n/$destinationKey\n\nhost:$host\nx-amz-content-sha256:$payloadHash\nx-amz-date:$isoDate\n\nhost;x-amz-content-sha256;x-amz-date\n$payloadHash';

      // Step 2: Create String to Sign
      final String credentialScope = "$shortDate/$region/$service/aws4_request";
      final String stringToSign =
          'AWS4-HMAC-SHA256\n$isoDate\n$credentialScope\n${sha256.convert(utf8.encode(canonicalRequest))}';

      // Step 3: Generate Signing Key
      final List<int> signingKey =
          _getSignatureKey(secretKey, shortDate, region, service);
      final String signature = Hmac(sha256, signingKey)
          .convert(utf8.encode(stringToSign))
          .toString();

      // Step 4: Create Authorization Header
      final String authorizationHeader =
          "AWS4-HMAC-SHA256 Credential=$accessKey/$credentialScope, SignedHeaders=host;x-amz-content-sha256;x-amz-date, Signature=$signature";

      // Step 5: Make Request
      final response = await http.put(
        Uri.parse(endpoint),
        headers: {
          "Host": host,
          "x-amz-date": isoDate,
          "x-amz-content-sha256": payloadHash,
          "Authorization": authorizationHeader,
          "Content-Type": mimeType,
          "Content-Length": fileBytes.length.toString(),
        },
        body: fileBytes,
      );

      // Debugging Logs
      debugPrint("Response Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return endpoint; // Return uploaded file URL
      } else {
        debugPrint("Upload Failed: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
      return null;
    }
  }

  /// Generates HMAC signature key
  List<int> _getSignatureKey(
      String key, String date, String region, String service) {
    var kDate =
        Hmac(sha256, utf8.encode("AWS4$key")).convert(utf8.encode(date)).bytes;
    var kRegion = Hmac(sha256, kDate).convert(utf8.encode(region)).bytes;
    var kService = Hmac(sha256, kRegion).convert(utf8.encode(service)).bytes;
    return Hmac(sha256, kService).convert(utf8.encode("aws4_request")).bytes;
  }

  /// Returns ISO 8601 timestamp
  String _getIsoDate() {
    final DateTime now = DateTime.now().toUtc();
    return "${now.toIso8601String().replaceAll(RegExp(r'[:-]'), '').split('.')[0]}Z";
  }
}
