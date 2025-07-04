import 'dart:io';

class FakeS3UploadService {
  bool shouldSucceed = true;

  Future<String?> uploadFile(File file) async {
    return shouldSucceed ? 'https://fakeurl.com/image.png' : null;
  }
}
