import 'dart:io';

import 'package:flutter/material.dart';

import 'package:kkpchatapp/core/services/product_service.dart';
import 'package:kkpchatapp/core/services/s3_upload_service.dart';
import 'package:kkpchatapp/data/models/product_model.dart';

class AddProductProvider extends ChangeNotifier {
  final ProductService productService;
  final S3UploadService s3UploadService;

  AddProductProvider({
    required this.productService,
    required this.s3UploadService,
  });

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController reviewController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  List<String> availableSizes = ["S", "M", "L", "XL"];
  Set<String> selectedSizes = {};

  File? selectedImage;
  List<Color> selectedColors = [Colors.black];

  bool isLoading = false;

  void pickImage(File? image) {
    selectedImage = image;
    notifyListeners();
  }

  void addColor(Color color) {
    selectedColors.add(color);
    notifyListeners();
  }

  void removeColor(Color color) {
    selectedColors.remove(color);
    notifyListeners();
  }

  void toggleSize(String size) {
    if (selectedSizes.contains(size)) {
      selectedSizes.remove(size);
    } else {
      selectedSizes.add(size);
    }
    notifyListeners();
  }

  Future<bool> addProduct() async {
    if (nameController.text.isEmpty ||
        priceController.text.isEmpty ||
        stockController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        selectedSizes.isEmpty ||
        selectedColors.isEmpty ||
        selectedImage == null) {
      return false;
    }

    isLoading = true;
    notifyListeners();

    String? imageUrl = await s3UploadService.uploadFile(selectedImage!);

    isLoading = false;
    notifyListeners();

    if (imageUrl == null) return false;

    List<ProductColor> colorList = selectedColors.map((color) {
      return ProductColor(
        colorName: color.toString(),
        colorCode: '#${(color.red).toRadixString(16).padLeft(2, '0')}' // Red
            '${(color.green).toRadixString(16).padLeft(2, '0')}' // Green
            '${(color.blue).toRadixString(16).padLeft(2, '0')}', // Blue
      );
    }).toList();

    Product newProduct = Product(
      productName: nameController.text,
      imageUrl: imageUrl,
      colors: colorList,
      sizes: selectedSizes.toList(),
      stock: int.parse(stockController.text),
      price: double.parse(priceController.text),
      description: descriptionController.text,
    );

    return await productService.addProduct(newProduct);
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    reviewController.dispose();
    stockController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
