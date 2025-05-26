import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'fake_edit_provider.dart';
import 'fake_product_service.dart';
import 'fake_s3_upload_service.dart';

void main() {
  late FakeProductService fakeProductService;
  late FakeS3UploadService fakeS3UploadService;
  late FakeEditProductProvider provider;

  final mockProduct = Product(
    productName: "T-Shirt",
    price: 19.99,
    stock: 100,
    sizes: ["M", "L"],
    colors: [
      ProductColor(colorName: "Red", colorCode: "#ff0000"),
    ],
    imageUrl: "https://fakeurl.com/original.png",
    description: "A red t-shirt",
  );

  setUp(() {
    fakeProductService = FakeProductService();
    fakeS3UploadService = FakeS3UploadService();
    provider = FakeEditProductProvider(
      productService: fakeProductService,
      s3UploadService: fakeS3UploadService,
      product: mockProduct,
    );
  });

  test('should return true if update succeeds without new image', () async {
    fakeProductService.shouldSucceed = true;
    final result = await provider.updateProduct("123");
    expect(result, true);
  });

  test('should return false if update fails without new image', () async {
    fakeProductService.shouldSucceed = false;
    final result = await provider.updateProduct("123");
    expect(result, false);
  });

  test('should return false if image upload fails', () async {
    provider.selectedImage = File('fake_path.jpg');
    fakeS3UploadService.shouldSucceed = false;

    final result = await provider.updateProduct("123");
    expect(result, false);
  });

  test('should return true if image upload and update succeed', () async {
    provider.selectedImage = File('fake_path.jpg');
    fakeS3UploadService.shouldSucceed = true;
    fakeProductService.shouldSucceed = true;

    final result = await provider.updateProduct("123");
    expect(result, true);
  });

  test('should return false if update fails after successful image upload',
      () async {
    provider.selectedImage = File('fake_path.jpg');
    fakeS3UploadService.shouldSucceed = true;
    fakeProductService.shouldSucceed = false;

    final result = await provider.updateProduct("123");
    expect(result, false);
  });
}
