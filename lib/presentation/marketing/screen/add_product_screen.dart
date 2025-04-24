import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/services/product_service.dart';
import 'package:kkpchatapp/core/services/s3_upload_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:kkpchatapp/presentation/common_widgets/full_screen_loader.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ProductService productService = ProductService();
  final S3UploadService s3UploadService = S3UploadService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController reviewController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  List<String> availableSizes = ["S", "M", "L", "XL"];
  Set<String> selectedSizes = {}; // Store selected sizes

  File? selectedImage;
  List<Color> selectedColors = [
    Colors.black, //default color
  ];
  bool isLoading = false;
  // Controls loader visibility
  void pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path); // Store as File
      });
      debugPrint('File Picked up : $selectedImage');
    }
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

  void addProduct() async {
    if (nameController.text.isEmpty ||
        priceController.text.isEmpty ||
        stockController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        selectedSizes.isEmpty ||
        selectedColors.isEmpty ||
        selectedImage == null) {
      Utils().showSuccessDialog(context, "Please fill all fields!", false);
      return;
    }
    setState(() {
      isLoading = true;
    }); // Show loading dialog

    //Upload Image to S3

    String? imageUrl = await s3UploadService.uploadFile(selectedImage!);
    if (imageUrl != null) {
      debugPrint("Uploaded Image URL: $imageUrl"); // This is a String
    }

    // Navigator.pop(context); // Hide loading dialog
    setState(() {
      isLoading = false;
    });
    if (imageUrl == null) {
      if (mounted) {
        Utils().showSuccessDialog(context,
            "Image upload failed. Try uploading different image.", false);
      }
      return;
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

    // Create Product model
    Product newProduct = Product(
      productName: nameController.text,
      imageUrl: imageUrl, // here needs an actual url
      colors: colorList,
      sizes: selectedSizes.toList(),
      stock: int.parse(stockController.text),
      price: double.parse(priceController.text),
      // productId: "",
      description: descriptionController.text,
    );

    bool success = await productService.addProduct(newProduct);

    if (success) {
      if (mounted) {
        Utils().showSuccessDialog(context, "Product added successfully!", true);
      }
      // Auto-close the dialog after 2 seconds and navigate back
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context); // Close success dialog
          Navigator.pop(context, true); // Navigate back with result
        }
      });
    } else {
      if (mounted) {
        Utils().showSuccessDialog(
            context, "Failed to add product.Try Again later!", false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text("Add Product"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePickerContainer(selectedImage, pickImage),
                _buildProductDetails(),
                CustomButton(
                  onPressed: addProduct,
                  text: "Add Product",
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
                  keyboardType: TextInputType.number,
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
            hintText: "2000",
            keyboardType: TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          //description filed
          Text("Description", style: AppTextStyles.black14_600),
          CustomTextField(
            controller: descriptionController,
            hintText: "Describe about the product....... ",
            maxLines: 8,
            height: 100,
            minLines: 2,
          )
        ],
      ),
    );
  }

  Widget _buildSizeSelection() {
    return Wrap(
      spacing: 5,
      children: availableSizes.map((size) {
        bool isSelected = selectedSizes.contains(size);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedSizes.remove(size);
              } else {
                selectedSizes.add(size);
              }
            });
          },
          child: Container(
            height: 42,
            width: 30,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.grey707070 : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.greyE5E7EB : Colors.grey,
              ),
            ),
            child: Center(
              child: Text(
                size,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? Colors.white : AppColors.greyAAAAAA,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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
    return SizedBox(
      width: double.maxFinite,
      child: GestureDetector(
        onTap: pickImage,
        child: Card(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: DottedBorder(
              color:
                  AppColors.greyAAAAAA.withValues(alpha: 0.67), // Border color
              strokeWidth: 2, // Border width
              dashPattern: [6, 4], // Dotted pattern (adjust as needed)
              borderType: BorderType.RRect,
              radius: Radius.circular(12),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(5),
                  child: selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload_rounded,
                                size: 50, color: AppColors.grey7B7B7B),
                            Text(
                              "Upload Product Image",
                              style: AppTextStyles.black16_500.copyWith(
                                color: AppColors.grey7B7B7B,
                              ),
                            ),
                            CustomButton(
                                width: Utils().width(context) * 0.35,
                                fontSize: 13,
                                backgroundColor: AppColors.background,
                                onPressed: pickImage,
                                textColor: AppColors.blue,
                                borderColor: AppColors.background,
                                text: "Choose File")
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.all(0),
                          child: ClipRRect(
                            clipBehavior: Clip.antiAlias,
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              selectedImage,
                              fit: BoxFit.fitWidth,
                              height: 180,
                              width: double.infinity,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
