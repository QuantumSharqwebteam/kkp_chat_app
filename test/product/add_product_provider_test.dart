// test/add_product_provider_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'fake_add_product_provider.dart';
import 'fake_product_service.dart';
import 'fake_s3_upload_service.dart';

void main() {
  late FakeProductService fakeProductService;
  late FakeS3UploadService fakeS3UploadService;
  late FakeAddProductProvider provider;

  setUp(() {
    fakeProductService = FakeProductService();
    fakeS3UploadService = FakeS3UploadService();
    provider = FakeAddProductProvider(
      productService: fakeProductService,
      s3UploadService: fakeS3UploadService,
    );
  });

  test('should return false if fields are missing', () async {
    final result = await provider.addProduct();
    expect(result, false);
  });

  test('should return false if upload fails', () async {
    provider.nameController.text = 'Shirt';
    provider.priceController.text = '29.99';
    provider.stockController.text = '15';
    provider.descriptionController.text = 'Cool shirt';
    provider.selectedSizes.add('M');
    provider.selectedImage = File('dummy.jpg');
    fakeS3UploadService.shouldSucceed = false;

    final result = await provider.addProduct();
    expect(result, false);
  });

  test('should return true on successful addProduct', () async {
    provider.nameController.text = 'Shirt';
    provider.priceController.text = '29.99';
    provider.stockController.text = '15';
    provider.descriptionController.text = 'Cool shirt';
    provider.selectedSizes.add('M');
    provider.selectedImage = File('dummy.jpg');
    fakeS3UploadService.shouldSucceed = true;
    fakeProductService.shouldSucceed = true;

    final result = await provider.addProduct();
    expect(result, true);
  });

  test('should return false if productService fails even if upload succeeds',
      () async {
    provider.nameController.text = 'Shirt';
    provider.priceController.text = '29.99';
    provider.stockController.text = '15';
    provider.descriptionController.text = 'Cool shirt';
    provider.selectedSizes.add('M');
    provider.selectedImage = File('dummy.jpg');
    fakeS3UploadService.shouldSucceed = true;
    fakeProductService.shouldSucceed = false;

    final result = await provider.addProduct();
    expect(result, false);
  });
}
