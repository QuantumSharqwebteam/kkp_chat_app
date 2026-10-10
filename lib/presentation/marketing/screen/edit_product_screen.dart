import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/data/api/product_service.dart';
import 'package:kkpchatapp/core/services/s3_upload_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';
import 'package:kkpchatapp/presentation/common_widgets/full_screen_loader.dart';
import 'package:kkpchatapp/presentation/common_widgets/required_field_label.dart';

import '../../../config/theme/app_text_styles.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final productService = ProductService();
  final s3UploadService = S3UploadService();
  late final nameController =
      TextEditingController(text: widget.product.productName);
  late final priceController =
      TextEditingController(text: widget.product.price.toString());
  late final stockController =
      TextEditingController(text: widget.product.stock.toString());
  late final descriptionController =
      TextEditingController(text: widget.product.description.toString());
  late Set<String> selectedSizes = widget.product.sizes.toSet();
  late List<Color> selectedColors = widget.product.colors
      .map((c) =>
          Color(int.parse('FF${c.colorCode.substring(1, 7)}', radix: 16)))
      .toList();
  late String? productImage = widget.product.imageUrl;
  File? selectedImage;
  bool isLoading = false;

  @override
  void dispose() {
    for (final c in [
      nameController,
      priceController,
      stockController,
      descriptionController
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- Validation ----------
  String? _validate() {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim());
    if (name.isEmpty) return "Product name cannot be empty.";
    if (!RegExp(r'^[A-Za-z0-9 ]+$').hasMatch(name)) {
      return "Product name can only contain letters and numbers.";
    }
    if (price == null || price <= 0) return "Enter a valid price.";
    if (selectedSizes.isEmpty) return "Select at least one size.";
    if (selectedColors.isEmpty) return "Select at least one color.";
    if (int.tryParse(stockController.text.trim()) == null) {
      return "Enter a valid stock quantity.";
    }
    if (descriptionController.text.trim().isEmpty) {
      return "Description cannot be empty.";
    }
    return null;
  }

  void _showError(String msg) {
    if (!mounted) return;
    Utils().showSuccessDialog(context, msg, false);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) Navigator.pop(context);
    });
  }

  String _hex(Color c) => '#${[
        c.r,
        c.g,
        c.b
      ].map((v) => (v * 255).round().toRadixString(16).padLeft(2, '0')).join()}';

  void pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => selectedImage = File(picked.path));
  }

  void updateProduct() async {
    final error = _validate();
    if (error != null) return _showError(error);

    setState(() => isLoading = true);

    String? imageUrl = productImage;
    if (selectedImage != null) {
      imageUrl = await s3UploadService.uploadFile(selectedImage!);
      if (imageUrl == null) {
        if (mounted) setState(() => isLoading = false);
        return _showError("Image upload failed. Try again.");
      }
    }

    final success =
        await productService.updateProduct(widget.product.productId!, {
      "productName": nameController.text.trim(),
      "sizes": selectedSizes.toList(),
      "stock": int.parse(stockController.text.trim()),
      "price": double.parse(priceController.text.trim()),
      "imageUrl": imageUrl,
      "colors": selectedColors
          .map((c) => ProductColor(colorName: _hex(c), colorCode: _hex(c)))
          .toList(),
      "description": descriptionController.text.trim(),
    });

    if (!mounted) return;
    setState(() => isLoading = false);

    if (!success) {
      return _showError("Failed to update product. Try again later!");
    }

    Utils().showSuccessDialog(context, "Product updated successfully!", true);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context, true);
    });
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(locale.editProduct),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        bottom: Platform.isAndroid,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                spacing: 20,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImagePicker(),
                  _buildProductDetails(locale),
                  const SizedBox(height: 20),
                  CustomButton(
                    onPressed: isLoading ? null : updateProduct,
                    text: locale.updateProduct,
                    fontSize: 18,
                    borderColor: AppColors.blue00ABE9,
                    backgroundColor: AppColors.blue00ABE9,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            if (isLoading) FullScreenLoader(),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text.rich(TextSpan(
        text: text,
        style: AppTextStyles.black14_600,
        children: const [
          TextSpan(text: ' *', style: TextStyle(color: Colors.red))
        ],
      ));

  Widget _buildProductDetails(AppLocalizations locale) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              blurRadius: 3,
              offset: const Offset(0, 1),
              color: Colors.black.withValues(alpha: 0.15))
        ],
      ),
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RequiredFieldLabel(locale.productName),
          CustomTextField(
            controller: nameController,
            hintText: locale.name,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]'))
            ],
            condition: (v) => RegExp(r'^[A-Za-z0-9 ]+$').hasMatch(v.trim()),
          ),
          Row(spacing: 10, children: [
            Expanded(child: _label(locale.price)),
            Expanded(child: _label(locale.size))
          ]),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: CustomTextField(
                  controller: priceController,
                  hintText: "₹0.00",
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                  ],
                  condition: (v) => (double.tryParse(v) ?? 0) > 0,
                ),
              ),
              Expanded(child: _buildSizeSelection()),
            ],
          ),
          _label(locale.color),
          _buildColorPicker(),
          _label(locale.stockAvailable),
          CustomTextField(
            controller: stockController,
            hintText: "2000 Stocks Available",
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            condition: (v) => int.tryParse(v) != null,
          ),
          _label(locale.description),
          CustomTextField(
            controller: descriptionController,
            hintText: locale.describeProduct,
            maxLines: 16,
            minLines: 2,
            height: 120,
            condition: (v) => v.trim().isNotEmpty,
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSelection() {
    return Wrap(
      spacing: 5,
      children: ["S", "M", "L", "XL"].map((size) {
        final selected = selectedSizes.contains(size);
        return GestureDetector(
          onTap: () => setState(() =>
              selected ? selectedSizes.remove(size) : selectedSizes.add(size)),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selected ? Colors.blue : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: Text(size,
                style:
                    TextStyle(color: selected ? Colors.white : Colors.black)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 8,
      children: [
        ...selectedColors.map((c) => GestureDetector(
              onTap: () => setState(() => selectedColors.remove(c)),
              child: CircleAvatar(backgroundColor: c, radius: 14),
            )),
        GestureDetector(
          onTap: pickColor,
          child: const CircleAvatar(
            backgroundColor: Colors.grey,
            radius: 14,
            child: Icon(Icons.add, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    final locale = AppLocalizations.of(context)!;
    final hasNetwork = productImage?.isNotEmpty ?? false;
    Widget child;
    if (selectedImage != null) {
      child = Image.file(selectedImage!,
          fit: BoxFit.fitWidth, height: 170, width: double.infinity);
    } else if (hasNetwork) {
      child = Image.network(productImage!,
          fit: BoxFit.cover, height: 180, width: double.infinity);
    } else {
      child = Column(children: [
        const Icon(Icons.cloud_upload_rounded, size: 50, color: Colors.grey),
        Text(locale.uploadProductImage),
        ElevatedButton(onPressed: pickImage, child: Text(locale.chooseFile)),
      ]);
    }
    return GestureDetector(
      onTap: pickImage,
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: child is Column
              ? child
              : ClipRRect(
                  borderRadius: BorderRadius.circular(10), child: child),
        ),
      ),
    );
  }

  void pickColor() async {
    Color picked =
        selectedColors.isNotEmpty ? selectedColors.last : Colors.black;
    final newColor = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pick a Color"),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: picked,
            onColorChanged: (c) => picked = c,
            labelTypes: const [ColorLabelType.rgb],
            pickerAreaBorderRadius: BorderRadius.circular(10),
          ),
        ),
        actions: [
          TextButton(
              child: const Text("Cancel"), onPressed: () => Navigator.pop(ctx)),
          TextButton(
              child: const Text("Select"),
              onPressed: () => Navigator.pop(ctx, picked)),
        ],
      ),
    );
    if (newColor != null) setState(() => selectedColors.add(newColor));
  }
}
