import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_textfield.dart';

import '../../../config/theme/app_text_styles.dart';

class EditProductScreen extends StatefulWidget {
  final String productName;
  final double price;
  final String stock;
  final String? image;
  final Set<String> selectedSizes;
  final List<Color> selectedColors;

  const EditProductScreen({
    super.key,
    required this.productName,
    required this.price,
    required this.stock,
    this.image,
    required this.selectedSizes,
    required this.selectedColors,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController stockController;
  late Set<String> selectedSizes;
  late List<Color> selectedColors;
  String? selectedImage;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.productName);
    priceController = TextEditingController(text: widget.price.toString());
    stockController = TextEditingController(text: widget.stock);
    selectedSizes = widget.selectedSizes;
    selectedColors = widget.selectedColors;
    selectedImage = widget.image;
  }

  void pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = pickedFile.path;
      });
    }
  }

  void saveProduct() {
    // Save edited product logic
    if (kDebugMode) {
      print("Product Saved: ${nameController.text}");
    }
    Utils().showSuccessDialog(context, "Product details updated");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text("Edit Product"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 20,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePickerContainer(selectedImage, pickImage),
            _buildProductDetails(),
            const SizedBox(height: 20),
            CustomButton(
              onPressed: saveProduct,
              text: "Update Product",
              fontSize: 18,
              borderColor: AppColors.blue00ABE9,
              backgroundColor: AppColors.blue00ABE9,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              blurRadius: 3,
              spreadRadius: 0,
              offset: Offset(0, 1),
              color: Colors.black.withValues(alpha: 0.15),
            )
          ]),
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //product name
          Text("Product Name", style: AppTextStyles.black14_600),
          CustomTextField(
            controller: nameController,
            hintText: 'Name',
          ),
          // price and review textfields
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: Text("Price", style: AppTextStyles.black14_600),
              ),
              Expanded(
                child: Text("Size", style: AppTextStyles.black14_600),
              ),
            ],
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: CustomTextField(
                  controller: priceController,
                  hintText: "₹0.00",
                ),
              ),
              Expanded(
                child: _buildSizeSelection(),
              ),
            ],
          ),
          Text("Color", style: AppTextStyles.black14_600),
          //color selector list
          _buildColorPickerWidget(),
          Text("Stock Availaible", style: AppTextStyles.black14_600),
          CustomTextField(
            controller: stockController,
            hintText: "2000 Stocks Available",
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSelection() {
    List<String> availableSizes = ["S", "M", "L", "XL"];
    return Wrap(
      spacing: 5,
      children: availableSizes.map((size) {
        bool isSelected = selectedSizes.contains(size);
        return GestureDetector(
          onTap: () {
            setState(() {
              isSelected ? selectedSizes.remove(size) : selectedSizes.add(size);
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: Text(size,
                style:
                    TextStyle(color: isSelected ? Colors.white : Colors.black)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorPickerWidget() {
    return Wrap(
      spacing: 8.0,
      children: selectedColors.map((color) {
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedColors.remove(color);
            });
          },
          child: CircleAvatar(backgroundColor: color, radius: 14),
        );
      }).toList()
        ..add(
          GestureDetector(
            onTap: pickColor,
            child: const CircleAvatar(
              backgroundColor: Colors.grey,
              radius: 14,
              child: Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ),
    );
  }

  Widget _buildImagePickerContainer(
      String? selectedImage, VoidCallback pickImage) {
    return GestureDetector(
      onTap: pickImage,
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: selectedImage == null
              ? Column(
                  children: [
                    const Icon(Icons.cloud_upload_rounded,
                        size: 50, color: Colors.grey),
                    const Text("Upload Product Image"),
                    ElevatedButton(
                      onPressed: pickImage,
                      child: const Text("Choose File"),
                    ),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: selectedImage.startsWith("assets/")
                      ? Image.asset(
                          // Display asset image
                          selectedImage,
                          fit: BoxFit.cover,
                          height: 120,
                          width: double.infinity,
                        )
                      : Image.file(
                          // Display file image
                          File(selectedImage),
                          fit: BoxFit.cover,
                          height: 120,
                          width: double.infinity,
                        ),
                ),
        ),
      ),
    );
  }

  void pickColor() async {
    Color? pickedColor = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pick a Color"),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: Colors.black,
              onColorChanged: (color) {
                Navigator.pop(context, color);
              },
            ),
          ),
        );
      },
    );
    if (pickedColor != null) {
      setState(() {
        selectedColors.add(pickedColor);
      });
    }
  }
}
