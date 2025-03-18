import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/presentation/common_widgets/colored_circles.dart';

import '../../../data/models/product_model.dart';

class ProductItem extends StatelessWidget {
  const ProductItem({super.key, required this.product, required this.onTap});

  final Product product;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        elevation: 5,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          width: 170,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: 5, end: 5, start: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      product.imageUrl, // Fetching from API
                      height: 150,
                      width: double.maxFinite,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 120);
                      },
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    product.productName,
                    style: AppTextStyles.black16_500,
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Color ',
                        style: AppTextStyles.black10_500
                            .copyWith(color: Colors.grey.shade500),
                      ),
                      ColoredCircles(
                        colors: product.colors.map((color) {
                          return Color(int.parse(color.colorCode.replaceAll(
                              "#", "0xff"))); // Convert hex to Color
                        }).toList(),
                        size: 15,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: product.stock > 0
                                  ? AppColors.activeGreen
                                  : AppColors.inActiveRed,
                              width: 2.0,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: product.stock > 0
                                    ? AppColors.activeGreen
                                    : AppColors.inActiveRed,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          product.stock > 0 ? " In Stock" : " Out of Stock",
                          style: AppTextStyles.black8_500.copyWith(
                            fontSize: 8,
                            color: product.stock > 0
                                ? AppColors.activeGreen
                                : AppColors.errorRed,
                          ),
                        ),
                      ],
                    ),
                    product.stock > 0
                        ? Text(
                            '(${product.stock} units available)',
                            style: AppTextStyles.black8_500
                                .copyWith(color: Colors.grey.shade600),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
