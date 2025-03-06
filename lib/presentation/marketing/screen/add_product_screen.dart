import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
    Colors.red,
    Colors.blue,
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
                Colors.grey
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
      appBar: AppBar(
        title: const Text("Add Product"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImagePickerWidget(
                selectedImage: selectedImage, pickImage: pickImage),
            const SizedBox(height: 16),
            ProductTextField(controller: nameController, label: "Product Name"),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: ProductTextField(
                        controller: priceController,
                        label: "Price",
                        isNumeric: true)),
                const SizedBox(width: 16),
                Expanded(
                    child: ProductTextField(
                        controller: reviewController,
                        label: "Review",
                        isNumeric: true)),
              ],
            ),
            const SizedBox(height: 16),
            const Text("Color"),
            ColorPickerWidget(
                selectedColors: selectedColors, pickColor: pickColor),
            const SizedBox(height: 16),
            ProductTextField(
                controller: stockController, label: "Stock Available"),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text("Add Product"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImagePickerWidget extends StatelessWidget {
  final String? selectedImage;
  final VoidCallback pickImage;

  const ImagePickerWidget(
      {super.key, required this.selectedImage, required this.pickImage});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[200],
        ),
        child: selectedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
                  const Text("Upload Product Image"),
                  TextButton(
                    onPressed: pickImage,
                    child: const Text("Choose File"),
                  )
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(10.0),
                child: ClipRRect(
                  clipBehavior: Clip.antiAlias,
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(selectedImage!),
                    fit: BoxFit.fitWidth,
                    height: 100,
                  ),
                ),
              ),
      ),
    );
  }
}

class ProductTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isNumeric;

  const ProductTextField(
      {super.key,
      required this.controller,
      required this.label,
      this.isNumeric = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class ColorPickerWidget extends StatelessWidget {
  final List<Color> selectedColors;
  final VoidCallback pickColor;

  const ColorPickerWidget(
      {super.key, required this.selectedColors, required this.pickColor});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      children: selectedColors
          .map((color) => GestureDetector(
                onTap: () {
                  selectedColors.remove(color);
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
}
