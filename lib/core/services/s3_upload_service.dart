import 'dart:async';
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

/// An upload failure that names the stage it happened in, so the UI can tell
/// the user *why* rather than just "upload failed".
class UploadException implements Exception {
  UploadException(this.stage, this.message, {this.detail, this.location});

  /// Which step broke: "Config", "AWS keys", "Read file", "Compression",
  /// "Network", or "S3".
  final String stage;

  /// Short, user-facing sentence.
  final String message;

  /// Technical specifics — status codes, S3 error codes, exception text.
  final String? detail;

  /// The method that threw, e.g. `S3UploadService._putToS3 (timeout)`. Lets a
  /// pasted report point at the exact place in app code, not just the symptom.
  final String? location;

  @override
  String toString() {
    final where = location == null ? '' : ' at $location';
    return detail == null
        ? '[$stage]$where $message'
        : '[$stage]$where $message — $detail';
  }
}

class S3UploadService {
  /// Lazy, not a field initializer. `dotenv.env[...]!` in a field initializer
  /// threw during *construction* if the key was missing, which took down the
  /// whole screen before any error handling could run.
  String get bucketName {
    final name = dotenv.env["AWS_BUCKET_NAME"];
    if (name == null || name.isEmpty) {
      throw UploadException(
        'Config',
        'Storage bucket is not configured in this build.',
        detail: 'AWS_BUCKET_NAME missing from .env',
        location: 'S3UploadService.bucketName (AWS_BUCKET_NAME missing)',
      );
    }
    return name;
  }

  /// Set when compression was skipped, so a later failure report can say the
  /// original file was uploaded instead of a compressed one.
  String? _compressionNote;
  String? get compressionNote => _compressionNote;

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
      throw UploadException(
        'AWS keys',
        'Storage credentials are missing. Sign out and sign in again.',
        detail: 'prefetchAwsKeys() did not run or returned null '
            '(accessKey=${_accessKey != null}, secretKey=${_secretKey != null}, '
            'region=${_region ?? "null"})',
        location: 'S3UploadService._loadKeys (credentials null)',
      );
    }
  }

  /// Null on any failure — kept for the chat/voice callers that treat upload as
  /// best-effort. Use [uploadFileOrThrow] when the reason matters.
  Future<String?> uploadFile(File file, {bool isVoiceMessage = false}) async {
    try {
      return await uploadFileOrThrow(file, isVoiceMessage: isVoiceMessage);
    } catch (e) {
      debugPrint("Upload Error: $e");
      return null;
    }
  }

  /// Same upload, but throws [UploadException] naming the stage that failed.
  Future<String> uploadFileOrThrow(File file,
      {bool isVoiceMessage = false}) async {
    _compressionNote = null;
    _loadKeys();

    // Pre-flight: a picked image lives in a cache directory the OS can clear,
    // and on Android 13 a denied media permission yields a path that is not
    // actually readable. Both used to surface as a generic failure.
    if (!await file.exists()) {
      throw UploadException(
        'Read file',
        'The selected image is no longer available. Pick it again.',
        detail: 'File does not exist: ${file.path}',
        location: 'S3UploadService.uploadFileOrThrow (file.exists)',
      );
    }

    final int sourceLength;
    try {
      sourceLength = await file.length();
    } catch (e) {
      throw UploadException(
        'Read file',
        'The selected image could not be read. Check app photo permissions.',
        detail: '${file.path} — $e',
        location: 'S3UploadService.uploadFileOrThrow (file.length)',
      );
    }

    if (sourceLength == 0) {
      throw UploadException(
        'Read file',
        'The selected image is empty (0 bytes).',
        detail: file.path,
        location: 'S3UploadService.uploadFileOrThrow (zero bytes)',
      );
    }

    File fileToUpload = file;

    if (!isVoiceMessage) {
      // Compression is an optimisation, never a gate.
      //
      // flutter_image_compress fails on some devices and formats (HEIC from
      // certain camera apps, unusual colour spaces) and used to abort the whole
      // upload. The picker already caps images at 512x512 / quality 80, so the
      // original is a perfectly acceptable payload — fall back to it and record
      // that we did, instead of failing.
      try {
        final compressedFile = await compressImage(file, quality: 80);
        if (compressedFile != null) {
          fileToUpload = compressedFile;
        } else {
          _compressionNote = 'compression skipped: '
              'flutter_image_compress returned null for '
              '${lookupMimeType(file.path) ?? "unknown type"} '
              '($sourceLength bytes) — uploading original';
          debugPrint(_compressionNote!);
        }
      } catch (e) {
        _compressionNote =
            'compression skipped: ${e.runtimeType} — $e — uploading original';
        debugPrint(_compressionNote!);
      }
    }

    return await _putToS3(fileToUpload);
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

  Future<String> _putToS3(File file) async {
    final String isoDate = _getIsoDate();
    final String shortDate = isoDate.substring(0, 8);
    final String sanitizedFileName =
        file.path.split('/').last.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final String destinationKey =
        "uploads/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName";

    const String service = "s3";
    final String host = "$bucketName.s3.$_region.amazonaws.com";
    final String endpoint = "https://$host/$destinationKey";

    final mimeType = lookupMimeType(file.path) ?? "application/octet-stream";
    final List<int> fileBytes;
    try {
      fileBytes = await file.readAsBytes();
    } catch (e) {
      throw UploadException(
        'Read file',
        'The processed image could not be read back from storage.',
        detail: '${file.path} — $e',
        location: 'S3UploadService._putToS3 (file.readAsBytes)',
      );
    }
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

    final http.Response response;
    try {
      response = await http
          .put(
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
          )
          .timeout(const Duration(seconds: 60));
    } on SocketException catch (e) {
      throw UploadException(
        'Network',
        'No internet connection while uploading.',
        detail: '$host — $e',
        location: 'S3UploadService._putToS3 (SocketException)',
      );
    } on TimeoutException catch (e) {
      throw UploadException(
        'Network',
        'Upload timed out after 60s. Check your connection and retry.',
        detail: '$host — ${fileBytes.length} bytes — $e',
        location: 'S3UploadService._putToS3 (TimeoutException)',
      );
    } catch (e) {
      throw UploadException(
        'Network',
        'Could not reach image storage.',
        detail: '$host — $e',
        location: 'S3UploadService._putToS3 (http.put threw)',
      );
    }

    if (response.statusCode == 200) return endpoint;

    // S3 replies with an XML body carrying the real reason. Surfacing it is the
    // difference between "upload failed" and "your device clock is wrong".
    final code =
        _xmlTag(response.body, 'Code') ?? 'HTTP ${response.statusCode}';
    final serverMessage = _xmlTag(response.body, 'Message') ?? response.body;

    throw UploadException(
      'S3',
      _explainS3Code(code, response.statusCode),
      detail: 'HTTP ${response.statusCode} $code: $serverMessage\n'
          'key=$destinationKey host=$host bytes=${fileBytes.length} '
          'deviceTime=$isoDate',
      location: 'S3UploadService._putToS3 (non-200 from S3)',
    );
  }

  static String? _xmlTag(String body, String tag) {
    final match = RegExp('<$tag>(.*?)</$tag>', dotAll: true).firstMatch(body);
    return match?.group(1)?.trim();
  }

  /// Plain-language cause for the S3 error codes this app can realistically hit.
  static String _explainS3Code(String code, int statusCode) {
    switch (code) {
      case 'RequestTimeTooSkewed':
        // The request is signed with the device clock; AWS rejects anything
        // more than ~15 minutes out. Common on phones with the clock set
        // manually or a dead battery-backed RTC.
        return "Your phone's date/time is wrong. Turn on automatic "
            'date & time in Settings, then try again.';
      case 'SignatureDoesNotMatch':
      case 'InvalidAccessKeyId':
        return 'Storage credentials were rejected. Sign out and sign in again.';
      case 'AccessDenied':
        return 'This account is not allowed to upload images.';
      case 'NoSuchBucket':
        return 'The storage bucket for this build does not exist.';
      case 'EntityTooLarge':
        return 'That image is too large to upload.';
      default:
        return 'Image storage rejected the upload (HTTP $statusCode).';
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
