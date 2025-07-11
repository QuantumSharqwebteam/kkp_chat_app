import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'package:kkpchatapp/presentation/common_widgets/colored_circles.dart';

class ProductItem extends StatelessWidget {
  const ProductItem({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        elevation: 5,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.shade400,
                  offset: Offset(0.2, 0.4),
                  blurRadius: 1)
            ],
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.44,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 60),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                product.productName,
                style: AppTextStyles.black16_500,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 06),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text('Color ',
                        style: AppTextStyles.black10_500
                            .copyWith(color: Colors.grey.shade500)),
                    ColoredCircles(
                      colors: product.colors
                          .map((c) => Color(
                              int.parse(c.colorCode.replaceAll('#', '0xff'))))
                          .toList(),
                      size: 14,
                    ),
                  ],
                ),
              ),
              // const Spacer(),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StockDot(inStock: product.stock > 0),
                  if (product.stock > 0)
                    Text(
                      '(${product.stock} available)',
                      style: AppTextStyles.black8_500
                          .copyWith(color: Colors.grey.shade600),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockDot extends StatelessWidget {
  const _StockDot({required this.inStock});
  final bool inStock;

  @override
  Widget build(BuildContext context) {
    final Color color = inStock ? AppColors.activeGreen : AppColors.errorRed;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              shape: BoxShape.circle, border: Border.all(color: color)),
          child: Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
        ),
        Text(
          inStock ? ' In Stock' : ' Out of Stock',
          style: AppTextStyles.black8_500.copyWith(color: color, fontSize: 9),
        ),
      ],
    );
  }
}
