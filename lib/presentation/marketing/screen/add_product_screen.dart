import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_textfield.dart';
import 'package:dotted_border/dotted_border.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController reviewController = TextEditingController();
  final TextEditingController stockController =
      TextEditingController(text: "2000 Stocks Available");
  String? selectedImage;
  List<Color> selectedColors = [
    Colors.black, //default color
  ];

  void pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = pickedFile.path;
      });
    }
  }

  void pickColor() async {
    Color? pickedColor = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pick a Color"),
          content: SingleChildScrollView(
            child: BlockPicker(
              availableColors: [
                Colors.white,
                Colors.black,
                Colors.red,
                Colors.green,
                Colors.yellow,
                Colors.blue,
                Colors.grey,
                Colors.lightGreen,
              ],
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 20,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePickerContainer(selectedImage, pickImage),
            const SizedBox(height: 30),
            _buildProductDetails(),
            CustomButton(
              onPressed: () {
                Utils().showSuccessDialog(context, "Added Sucessfully");
              },
              text: "Add Product",
              fontSize: 18,
              borderColor: AppColors.blue,
              backgroundColor: AppColors.blue,
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
                child: Text("Review", style: AppTextStyles.black14_600),
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
                child: CustomTextField(
                  controller: reviewController,
                  hintText: "0",
                ),
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
      String? selectedImage, VoidCallback pickImage) {
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
                  padding: EdgeInsets.all(10),
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
                          padding: const EdgeInsets.all(10.0),
                          child: ClipRRect(
                            clipBehavior: Clip.antiAlias,
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(selectedImage),
                              fit: BoxFit.fitWidth,
                              height: 100,
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
