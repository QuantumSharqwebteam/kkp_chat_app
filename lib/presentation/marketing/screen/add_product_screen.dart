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
import 'package:kkpchatapp/logic/agent/add_product_provider.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:kkpchatapp/presentation/common_widgets/full_screen_loader.dart';
import 'package:provider/provider.dart';

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AddProductProvider>(
      create: (_) => AddProductProvider(
        productService: ProductService(),
        s3UploadService: S3UploadService(),
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: const Text("Add Product"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<AddProductProvider>(
          builder: (context, provider, _) {
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImagePickerContainer(context, provider),
                      const SizedBox(height: 10),
                      _buildProductDetails(context, provider),
                      const SizedBox(height: 10),
                      CustomButton(
                        onPressed: () async {
                          bool success = await provider.addProduct();
                          if (context.mounted) {
                            if (!success) {
                              Utils().showSuccessDialog(context,
                                  "Please fill all fields correctly!", false);
                              return;
                            }
                          }
                          if (context.mounted) {
                            Utils().showSuccessDialog(
                                context, "Product added successfully!", true);
                          }
                          Future.delayed(const Duration(seconds: 2), () {
                            if (context.mounted) {
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(
                                  context, true); // Go back with success
                            }
                          });
                        },
                        text: "Add Product",
                        fontSize: 18,
                        borderColor: AppColors.blue00ABE9,
                        backgroundColor: AppColors.blue00ABE9,
                      ),
                    ],
                  ),
                ),
                if (provider.isLoading) const FullScreenLoader(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildImagePickerContainer(
      BuildContext context, AddProductProvider provider) {
    return SizedBox(
      width: double.maxFinite,
      child: GestureDetector(
        onTap: () async {
          final pickedFile =
              await ImagePicker().pickImage(source: ImageSource.gallery);
          if (pickedFile != null) {
            provider.pickImage(File(pickedFile.path));
          }
        },
        child: Card(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: DottedBorder(
              color: AppColors.greyAAAAAA.withOpacity(0.67),
              strokeWidth: 2,
              dashPattern: const [6, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(5),
                  child: provider.selectedImage == null
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
                              onPressed: () async {
                                final pickedFile = await ImagePicker()
                                    .pickImage(source: ImageSource.gallery);
                                if (pickedFile != null) {
                                  provider.pickImage(File(pickedFile.path));
                                }
                              },
                              textColor: AppColors.blue,
                              borderColor: AppColors.background,
                              text: "Choose File",
                            ),
                          ],
                        )
                      : ClipRRect(
                          clipBehavior: Clip.antiAlias,
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            provider.selectedImage!,
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
    );
  }

  Widget _buildProductDetails(
      BuildContext context, AddProductProvider provider) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 3,
            spreadRadius: 0,
            offset: const Offset(0, 1),
            color: Colors.black.withOpacity(0.15),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Product Name", style: AppTextStyles.black14_600),
          CustomTextField(
            controller: provider.nameController,
            hintText: 'Name',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text("Price", style: AppTextStyles.black14_600)),
              Expanded(child: Text("Size", style: AppTextStyles.black14_600)),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: provider.priceController,
                  hintText: "₹0.00",
                  keyboardType: TextInputType.number,
                ),
              ),
              Expanded(child: _buildSizeSelection(provider)),
            ],
          ),
          const SizedBox(height: 10),
          Text("Color", style: AppTextStyles.black14_600),
          const SizedBox(height: 5),
          _buildColorPickerWidget(context, provider),
          const SizedBox(height: 10),
          Text("Stock Available", style: AppTextStyles.black14_600),
          CustomTextField(
            controller: provider.stockController,
            hintText: "2000",
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 10),
          Text("Description", style: AppTextStyles.black14_600),
          CustomTextField(
            controller: provider.descriptionController,
            hintText: "Describe about the product....... ",
            maxLines: 8,
            height: 100,
            minLines: 2,
          )
        ],
      ),
    );
  }

  Widget _buildSizeSelection(AddProductProvider provider) {
    return Wrap(
      spacing: 5,
      children: provider.availableSizes.map((size) {
        bool isSelected = provider.selectedSizes.contains(size);
        return GestureDetector(
          onTap: () => provider.toggleSize(size),
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

  Widget _buildColorPickerWidget(
      BuildContext context, AddProductProvider provider) {
    return Wrap(
      spacing: 8.0,
      children: [
        ...provider.selectedColors.map((color) {
          return GestureDetector(
            onTap: () => provider.removeColor(color),
            child: CircleAvatar(
              backgroundColor: color,
              radius: 14,
            ),
          );
        }),
        GestureDetector(
          onTap: () async {
            Color pickedColor = provider.selectedColors.isNotEmpty
                ? provider.selectedColors.last
                : Colors.black;

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
                      labelTypes: const [ColorLabelType.rgb],
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
              provider.addColor(newColor);
            }
          },
          child: const CircleAvatar(
            backgroundColor: Colors.grey,
            radius: 14,
            child: Icon(Icons.add, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}
