import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/models/product_model.dart';
import 'package:kkp_chat_app/data/repositories/product_repository.dart';
import 'package:kkp_chat_app/presentation/common_widgets/colored_circles.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/edit_product_screen.dart';

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
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    size: 30,
                  )),
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
              height: Utils().height(context) * 0.6,
              width: Utils().width(context),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, size: 120);
              },
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 10, right: 12, left: 12, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.productName,
                    style: AppTextStyles.black22_600,
                  ),
                  const SizedBox(height: 10),
                  //price and size details row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Price : ₹${widget.product.price.toString()}",
                        style: AppTextStyles.black16_500,
                      ),
                      Text(
                        "Sizes: ${widget.product.sizes.toString()}",
                        style: AppTextStyles.black16_500,
                      )
                    ],
                  ),
                  SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Colors',
                        style: AppTextStyles.black16_500
                            .copyWith(color: Colors.black, fontSize: 17),
                      ),
                      SizedBox(height: 5),
                      ColoredCircles(
                        colors: widget.product.colors.map((color) {
                          return Color(int.parse(
                              color.colorCode.replaceAll("#", "0xff")));
                        }).toList(),
                        size: 35,
                      ),
                      SizedBox(height: 10),
                      // Stock Info
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
                      SizedBox(height: 20),
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
                                    productName: "Men's Wear - Raymond",
                                    price: 600.00,
                                    stock: "50 Stocks Available",
                                    image: "assets/images/description.png",
                                    selectedSizes: {"M", "L"},
                                    selectedColors: [
                                      Colors.red,
                                      Colors.green,
                                      Colors.blue
                                    ],
                                  ),
                                ),
                              );
                            },
                            width: Utils().width(context) * 0.43,
                            image: Icon(Icons.edit_document,
                                color: AppColors.blue, size: 20),
                            height: 35,
                            borderRadius: 5,
                            borderColor: AppColors.blue0056FB,
                            backgroundColor: Colors.white,
                            textColor: AppColors.blue0056FB,
                          ),
                          CustomButton(
                            text: 'Remove',
                            onPressed: () {
                              Utils().showRemoveProductDialog(
                                context,
                                "Remove Product",
                                "Are you sure you want to remove this product?",
                                "remove",
                                () async {
                                  Navigator.pop(context); // Close the dialog

                                  final ProductRepository productRepository =
                                      ProductRepository();
                                  bool success = await productRepository
                                      .deleteProduct(widget.product.productId);

                                  if (success) {
                                    if (context.mounted) {
                                      Utils().showSuccessDialog(context,
                                          "Product deleted successfully");
                                    }
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    } // Navigate back to the previous page
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "Failed to delete product")),
                                      );
                                    }
                                  }
                                },
                              );
                            },
                            image: Icon(
                              Icons.delete_rounded,
                              color: AppColors.inActiveRed,
                              size: 20,
                            ),
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
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
