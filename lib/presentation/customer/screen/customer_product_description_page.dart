import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/colored_circles.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';

import '../../../data/models/product_model.dart';

class CustomerProductDescriptionPage extends StatelessWidget {
  final Product product; // Accepts a product object

  const CustomerProductDescriptionPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity, 100),
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back,
                  size: 30,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display product image from API
            Image.network(
              product.imageUrl,
              height: Utils().height(context) * 0.6,
              width: Utils().width(context),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, size: 120);
              },
            ),
            Padding(
              padding:
                  const EdgeInsets.only(top: 10, right: 8, left: 8, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.productName,
                    style: AppTextStyles.black22_600,
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 8),
                  //   child: Text(
                  //     product.description,
                  //     style: AppTextStyles.black12_400,
                  //   ),
                  // ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Price : ₹${product.price.toString()}",
                              style: AppTextStyles.black16_500,
                            ),
                            Text(
                              "Sizes: ${product.sizes.toString()}",
                              style: AppTextStyles.black16_500,
                            )
                          ],
                        ),
                        SizedBox(height: 8),
                        // Available Colors
                        Text(
                          'Available Colors',
                          style: AppTextStyles.black16_500.copyWith(
                            color: Colors.black,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 5),
                        ColoredCircles(
                          colors: product.colors.map((color) {
                            return Color(int.parse(
                                color.colorCode.replaceAll("#", "0xff")));
                          }).toList(),
                          size: 35,
                        ),
                        const SizedBox(height: 5),
                        // Stock Info
                        Text(
                          product.stock > 0
                              ? 'Only ${product.stock} left in Stock'
                              : 'Out of Stock',
                          style: AppTextStyles.black12_400.copyWith(
                            color: product.stock > 0
                                ? AppColors.activeGreen
                                : AppColors.inActiveRed,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomButton(
                              text: product.stock > 0
                                  ? 'Available'
                                  : 'Out of Stock',
                              onPressed: () {},
                              width: Utils().width(context) * 0.43,
                              height: 35,
                              borderRadius: 5,
                              backgroundColor: Colors.white,
                              textColor: product.stock > 0
                                  ? AppColors.blue
                                  : Colors.grey,
                            ),
                            CustomButton(
                              text: 'Notify Me',
                              onPressed: () {
                                // Implement Notify Me functionality
                              },
                              width: Utils().width(context) * 0.43,
                              height: 35,
                              borderRadius: 5,
                              backgroundColor: Colors.white,
                              textColor: Colors.black,
                            ),
                          ],
                        )
                      ],
                    ),
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
