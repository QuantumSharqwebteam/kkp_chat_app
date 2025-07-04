import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'fake_product_service.dart';
import 'fake_s3_upload_service.dart';

class FakeEditProductProvider extends ChangeNotifier {
  final FakeProductService productService;
  final FakeS3UploadService s3UploadService;

  FakeEditProductProvider({
    required this.productService,
    required this.s3UploadService,
    required Product product,
  }) {
    _initialize(product);
  }

  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController stockController;
  late TextEditingController descriptionController;

  Set<String> selectedSizes = {};
  List<Color> selectedColors = [];
  File? selectedImage;
  String? productImage;
  bool isLoading = false;

  void _initialize(Product product) {
    nameController = TextEditingController(text: product.productName);
    priceController = TextEditingController(text: product.price.toString());
    stockController = TextEditingController(text: product.stock.toString());
    descriptionController = TextEditingController(text: product.description);
    selectedSizes = product.sizes.toSet();
    selectedColors = product.colors.map((color) {
      return Color.fromRGBO(
        int.parse(color.colorCode.substring(1, 3), radix: 16),
        int.parse(color.colorCode.substring(3, 5), radix: 16),
        int.parse(color.colorCode.substring(5, 7), radix: 16),
        1,
      );
    }).toList();
    productImage = product.imageUrl;
  }

  Future<bool> updateProduct(String productId) async {
    isLoading = true;
    notifyListeners();

    String? imageUrl = productImage;
    if (selectedImage != null) {
      imageUrl = await s3UploadService.uploadFile(selectedImage!);
      if (imageUrl == null) {
        isLoading = false;
        notifyListeners();
        return false;
      }
    }

    List<ProductColor> colorList = selectedColors.map((color) {
      return ProductColor(
        colorName: color.toString(),
        colorCode:
            '#${color.red.toRadixString(16).padLeft(2, '0')}${color.green.toRadixString(16).padLeft(2, '0')}${color.blue.toRadixString(16).padLeft(2, '0')}',
      );
    }).toList();

    Map<String, dynamic> updatedData = {
      "productName": nameController.text,
      "sizes": selectedSizes.toList(),
      "stock": int.tryParse(stockController.text) ?? 0,
      "price": double.tryParse(priceController.text) ?? 0.0,
      "imageUrl": imageUrl,
      "colors": colorList,
      "description": descriptionController.text,
    };

    bool success = await productService.updateProduct(productId, updatedData);

    isLoading = false;
    notifyListeners();
    return success;
  }
}
