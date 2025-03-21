import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/core/services/product_service.dart';
import 'package:kkp_chat_app/core/services/s3_upload_service.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/models/product_model.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_textfield.dart';
import 'package:kkp_chat_app/presentation/common_widgets/full_screen_loader.dart';

import '../../../config/theme/app_text_styles.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final ProductService productService = ProductService();
  final S3UploadService s3UploadService = S3UploadService();
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController stockController;
  late TextEditingController descriptionController;
  Set<String> selectedSizes = {};
  List<Color> selectedColors = [];
  File? selectedImage;
  bool isLoading = false;
  String? productImage;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product.productName);
    priceController =
        TextEditingController(text: widget.product.price.toString());
    stockController =
        TextEditingController(text: widget.product.stock.toString());
    descriptionController =
        TextEditingController(text: widget.product.description.toString());
    selectedSizes = widget.product.sizes.toSet();
    selectedColors = widget.product.colors.map((color) {
      return Color.fromRGBO(
        int.parse(color.colorCode.substring(1, 3), radix: 16),
        int.parse(color.colorCode.substring(3, 5), radix: 16),
        int.parse(color.colorCode.substring(5, 7), radix: 16),
        1, // Full opacity
      );
    }).toList();
    productImage = widget.product.imageUrl;
  }

  void pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  void updateProduct() async {
    setState(() {
      isLoading = true;
    });

    // If a new image is selected, upload it
    String? imageUrl = productImage;
    if (selectedImage != null) {
      imageUrl = await s3UploadService.uploadFile(selectedImage!);
      if (imageUrl == null) {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          Utils().showSuccessDialog(context, "Image upload failed. Try again.");
        }
        return;
      }
    }

    // Convert colors to hex format
    List<ProductColor> colorList = selectedColors.map((color) {
      return ProductColor(
        colorName: color.toString(), // You may replace this with proper names
        colorCode:
            '#${(color.r * 255).toInt().toRadixString(16).padLeft(2, '0')}' // Red
            '${(color.g * 255).toInt().toRadixString(16).padLeft(2, '0')}' // Green
            '${(color.b * 255).toInt().toRadixString(16).padLeft(2, '0')}', // Blue
      );
    }).toList();

    // Prepare data for API
    Map<String, dynamic> updatedData = {
      "productName": nameController.text,
      "sizes": selectedSizes.toList(),
      "stock": int.parse(stockController.text),
      "price": double.parse(priceController.text),
      "imageUrl": imageUrl,
      "colors": colorList,
      "description": descriptionController.text,
    };

    // Call update API
    bool success = await productService.updateProduct(
        widget.product.productId, updatedData);

    setState(() {
      isLoading = false;
    });

    if (success) {
      if (mounted) {
        Utils().showSuccessDialog(context, "Product updated successfully!");
      }
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context, true);
        } // Close with success
      });
    } else {
      if (mounted) {
        Utils().showSuccessDialog(
            context, "Failed to update product. Try again later!");
      }
    }
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              spacing: 20,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePickerContainer(selectedImage, pickImage),
                _buildProductDetails(),
                const SizedBox(height: 20),
                CustomButton(
                  onPressed: updateProduct,
                  text: "Update Product",
                  fontSize: 18,
                  borderColor: AppColors.blue00ABE9,
                  backgroundColor: AppColors.blue00ABE9,
                ),
              ],
            ),
          ),
          if (isLoading) FullScreenLoader(), // Loader overlay
        ],
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
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
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
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          //description field
          Text("Description", style: AppTextStyles.black14_600),
          CustomTextField(
            controller: descriptionController,
            hintText: "Describe about the product....... ",
            maxLines: 8,
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
      children: selectedColors
          .map((color) => GestureDetector(
                onTap: () {
                  setState(() {
                    selectedColors.remove(color);
                  });
                },
                child: CircleAvatar(
                  backgroundColor: color,
                  radius: 14,
                ),
              ))
          .toList()
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
      File? selectedImage, VoidCallback pickImage) {
    return GestureDetector(
      onTap: pickImage,
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: selectedImage == null
              ? (productImage != null && productImage!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        productImage!,
                        fit: BoxFit.cover,
                        height: 180,
                        width: double.infinity,
                      ),
                    )
                  : Column(
                      children: [
                        const Icon(Icons.cloud_upload_rounded,
                            size: 50, color: Colors.grey),
                        const Text("Upload Product Image"),
                        ElevatedButton(
                          onPressed: pickImage,
                          child: const Text("Choose File"),
                        ),
                      ],
                    ))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    selectedImage,
                    fit: BoxFit.fitWidth,
                    height: 170,
                    width: double.infinity,
                  ),
                ),
        ),
      ),
    );
  }

  void pickColor() async {
    Color pickedColor =
        selectedColors.isNotEmpty ? selectedColors.last : Colors.black;

    Color? newColor = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pick a Color"),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickedColor,
              onColorChanged: (color) {
                pickedColor = color;
              },
              labelTypes: [
                ColorLabelType.rgb,
              ],
              pickerAreaBorderRadius: BorderRadius.circular(10),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Select"),
              onPressed: () => Navigator.pop(context, pickedColor),
            ),
          ],
        );
      },
    );

    if (newColor != null) {
      setState(() {
        selectedColors.add(newColor);
      });
    }
  }
}
