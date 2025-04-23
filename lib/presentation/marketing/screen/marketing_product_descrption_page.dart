import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'package:kkpchatapp/data/repositories/product_repository.dart';
import 'package:kkpchatapp/presentation/common_widgets/colored_circles.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/marketing/screen/edit_product_screen.dart';

import '../../../config/theme/app_text_styles.dart';

class MarketingProductDescrptionPage extends StatefulWidget {
  final Product product;
  const MarketingProductDescrptionPage({super.key, required this.product});

  @override
  State<MarketingProductDescrptionPage> createState() =>
      _MarketingProductDescrptionPageState();
}

class _MarketingProductDescrptionPageState
    extends State<MarketingProductDescrptionPage> {
  Future<void> _removeProduct() async {
    Utils().showDialogWithActions(
      context,
      "Remove Product",
      "Are you sure you want to remove this product?",
      "Remove",
      () async {
        Navigator.pop(context); // Close the confirmation dialog

        final ProductRepository productRepository = ProductRepository();
        bool success =
            await productRepository.deleteProduct(widget.product.productId!);

        if (success) {
          if (mounted) {
            Utils().showSuccessDialog(
                context, "Product deleted successfully", true);
          }
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context);
              Navigator.pop(context, true); // Navigate back and refresh list
            }
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to delete product")),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, 100),
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, size: 30),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              widget.product.imageUrl,
              height: Utils().height(context) * 0.5,
              width: Utils().width(context),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 120),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.product.productName.toUpperCase(),
                      style: AppTextStyles.black22_600),
                  const SizedBox(height: 10),
                  // price and sizes row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Price : ₹${widget.product.price}",
                          style: AppTextStyles.black16_700),
                      Row(
                        children: [
                          Text("Sizes: ", style: AppTextStyles.black16_500),
                          ...widget.product.sizes.map((size) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                child: Text(size,
                                    style: AppTextStyles.black16_500),
                              )),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  Text(
                    'Available Colors:',
                    style: AppTextStyles.black16_500
                        .copyWith(color: Colors.black, fontSize: 17),
                  ),
                  const SizedBox(height: 5),

                  ColoredCircles(
                    colors: widget.product.colors.map((color) {
                      return Color(
                          int.parse(color.colorCode.replaceAll("#", "0xff")));
                    }).toList(),
                    size: 35,
                  ),
                  const SizedBox(height: 10),

                  Text(
                    widget.product.stock > 0
                        ? 'Only ${widget.product.stock} left in Stock'
                        : 'Out of Stock',
                    style: AppTextStyles.black12_400.copyWith(
                      color: widget.product.stock > 0
                          ? AppColors.activeGreen
                          : AppColors.inActiveRed,
                    ),
                  ),
                  Text(
                    "Description:",
                    style: AppTextStyles.black16_500,
                  ),
                  Text(
                    widget.product.description ?? "Not Available ",
                    style: AppTextStyles.black60alpha_12_500,
                    textAlign: TextAlign.justify,
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomButton(
                        text: 'Edit',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProductScreen(
                                product: widget.product,
                              ),
                            ),
                          );
                        },
                        width: Utils().width(context) * 0.43,
                        image:
                            Icon(Icons.edit, color: AppColors.blue, size: 20),
                        height: 35,
                        borderRadius: 5,
                        borderColor: AppColors.blue0056FB,
                        backgroundColor: Colors.white,
                        textColor: AppColors.blue0056FB,
                      ),
                      CustomButton(
                        text: 'Remove',
                        onPressed: _removeProduct,
                        image: Icon(Icons.delete,
                            color: AppColors.inActiveRed, size: 20),
                        width: Utils().width(context) * 0.43,
                        height: 35,
                        borderRadius: 5,
                        backgroundColor: Colors.white,
                        borderColor: AppColors.inActiveRed,
                        textColor: AppColors.inActiveRed,
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
