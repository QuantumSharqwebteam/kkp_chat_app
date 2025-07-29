import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
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
    final double width = Utils().width(context);
    final double height = Utils().height(context);
    final bool isTablet = width >= 600;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Responsive container width
    double containerWidth =
        isTablet ? (isLandscape ? width * 0.28 : width * 0.42) : width * 0.44;

    return GestureDetector(
      onTap: onTap,
      child: Material(
        elevation: 5,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: containerWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade400,
                offset: const Offset(0.2, 0.4),
                blurRadius: 1,
              )
            ],
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.44,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade300,
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image, size: 60),
                    )),
              ),

              const SizedBox(height: 8),

              // Product name
              Text(
                product.productName,
                style: isTablet
                    ? AppTextStyles.black20_500
                    : AppTextStyles.black16_500.copyWith(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // Color list
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      'Color ',
                      style: isTablet
                          ? AppTextStyles.grey12_600.copyWith(fontSize: 16)
                          : AppTextStyles.grey12_600.copyWith(fontSize: 10),
                    ),
                    ColoredCircles(
                      colors: product.colors
                          .map((c) => Color(
                              int.parse(c.colorCode.replaceAll('#', '0xff'))))
                          .toList(),
                      size: 16,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Stock status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StockDot(inStock: product.stock > 0),
                  if (product.stock > 0)
                    Text(
                      '(${product.stock} available)',
                      style: isTablet
                          ? AppTextStyles.greyAAAAAA_10_400
                              .copyWith(fontSize: 14)
                          : AppTextStyles.greyAAAAAA_10_400
                              .copyWith(fontSize: 7),
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
    final bool isTablet = MediaQuery.of(context).size.width >= 600;
    final Color color = inStock ? AppColors.activeGreen : AppColors.errorRed;

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          inStock ? 'In Stock' : 'Out of Stock',
          style: AppTextStyles.black8_500.copyWith(
            color: color,
            fontSize: isTablet ? 16 : 12,
          ),
        ),
      ],
    );
  }
}
