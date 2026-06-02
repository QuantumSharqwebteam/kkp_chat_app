import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';

class S3UploadService {
  final String bucketName = dotenv.env["AWS_BUCKET_NAME"]!;

  String? _accessKey;
  String? _secretKey;
  String? _region;

  void _loadKeys() {
    if (_accessKey != null) return;
    final keys = LocalDbHelper.getAwsKeys();
    _accessKey = keys.accessKey;
    _secretKey = keys.secretKey;
    _region = keys.region;

    if (_accessKey == null || _secretKey == null || _region == null) {
      throw Exception(
          'AWS keys not available. Ensure AuthApi.prefetchAwsKeys() ran at startup.');
    }
  }

  Future<String?> uploadFile(File file, {bool isVoiceMessage = false}) async {
    try {
      _loadKeys();

      File fileToUpload = file;

      if (!isVoiceMessage) {
        final compressedFile = await compressImage(file, quality: 80);
        if (compressedFile == null) {
          debugPrint("Image compression failed.");
          return null;
        }
        fileToUpload = compressedFile;
      }

      return await _putToS3(fileToUpload);
    } catch (e) {
      debugPrint("Upload Error: $e");
      return null;
    }
  }

  Future<String?> uploadDocument(File file) async {
    try {
      _loadKeys();
      return await _putToS3(file);
    } catch (e) {
      debugPrint("Upload Error: $e");
      return null;
    }
  }

  Future<String?> _putToS3(File file) async {
    final String isoDate = _getIsoDate();
    final String shortDate = isoDate.substring(0, 8);
    final String sanitizedFileName = file.path
        .split('/')
        .last
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final String destinationKey =
        "uploads/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName";

    const String service = "s3";
    final String host = "$bucketName.s3.$_region.amazonaws.com";
    final String endpoint = "https://$host/$destinationKey";

    final mimeType = lookupMimeType(file.path) ?? "application/octet-stream";
    final List<int> fileBytes = await file.readAsBytes();
    final String payloadHash = sha256.convert(fileBytes).toString();

    final canonicalRequest =
        'PUT\n/$destinationKey\n\nhost:$host\nx-amz-content-sha256:$payloadHash\nx-amz-date:$isoDate\n\nhost;x-amz-content-sha256;x-amz-date\n$payloadHash';

    final String credentialScope = "$shortDate/$_region/$service/aws4_request";
    final String stringToSign =
        'AWS4-HMAC-SHA256\n$isoDate\n$credentialScope\n${sha256.convert(utf8.encode(canonicalRequest))}';

    final List<int> signingKey =
        _getSignatureKey(_secretKey!, shortDate, _region!, service);
    final String signature =
        Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).toString();

    final String authorizationHeader =
        "AWS4-HMAC-SHA256 Credential=$_accessKey/$credentialScope, SignedHeaders=host;x-amz-content-sha256;x-amz-date, Signature=$signature";

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

    debugPrint("Response Code: ${response.statusCode}");
    debugPrint("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return endpoint;
    } else {
      debugPrint("Upload Failed: ${response.body}");
      return null;
    }
  }

  Future<File?> compressImage(File file, {int quality = 80}) async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    int rand = DateTime.now().millisecondsSinceEpoch;

    final XFile? compressedImageXFile =
        await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      '$path/img_$rand.jpg',
      quality: quality,
    );

    return compressedImageXFile != null
        ? File(compressedImageXFile.path)
        : null;
  }

  List<int> _getSignatureKey(
      String key, String date, String region, String service) {
    var kDate =
        Hmac(sha256, utf8.encode("AWS4$key")).convert(utf8.encode(date)).bytes;
    var kRegion = Hmac(sha256, kDate).convert(utf8.encode(region)).bytes;
    var kService = Hmac(sha256, kRegion).convert(utf8.encode(service)).bytes;
    return Hmac(sha256, kService).convert(utf8.encode("aws4_request")).bytes;
  }

  String _getIsoDate() {
    final DateTime now = DateTime.now().toUtc();
    return "${now.toIso8601String().replaceAll(RegExp(r'[:-]'), '').split('.')[0]}Z";
  }
}
