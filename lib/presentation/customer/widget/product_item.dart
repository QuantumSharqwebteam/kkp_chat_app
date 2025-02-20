import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';

class ProductItem extends StatelessWidget {
  const ProductItem({super.key, required this.product});
  final Map<String, String> product;
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 239, 239, 239),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.only(top: 8, end: 8, start: 8),
          child: Column(
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(15), // Set the desired border radius
                child: Image.asset(
                  product['imageUrl']!,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 5),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  product['title']!,
                  style: AppTextStyles.black16_500,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Color ',
                    style: AppTextStyles.black12_400
                        .copyWith(color: Colors.grey.shade700),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.black54, width: 1),
                    ),
                    height: 12,
                    width: 12,
                  ),
                  SizedBox(width: 2),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.black54, width: 1),
                    ),
                    height: 12,
                    width: 12,
                  ),
                  SizedBox(width: 2),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.black54, width: 1),
                    ),
                    height: 12,
                    width: 12,
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: product['inStock'] == 'true'
                        ? AppColors.activeGreen
                        : AppColors.errorRed,
                  ),
                  Text(
                    product['inStock'] == 'true' ? "In Stock" : "Out of Stock",
                    style: AppTextStyles.black8_500.copyWith(
                        color: product['inStock'] == 'true'
                            ? AppColors.activeGreen
                            : AppColors.errorRed),
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
