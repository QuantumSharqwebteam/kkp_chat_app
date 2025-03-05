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
          padding: EdgeInsetsDirectional.only(top: 5, end: 5, start: 5),
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  product['title']!,
                  style: AppTextStyles.black16_500,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Color ',
                    style: AppTextStyles.black10_500
                        .copyWith(color: Colors.grey.shade500),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.black54, width: 1),
                    ),
                    height: 15,
                    width: 15,
                  ),
                  SizedBox(width: 2),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.black54, width: 1),
                    ),
                    height: 15,
                    width: 15,
                  ),
                  SizedBox(width: 2),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.black54, width: 1),
                    ),
                    height: 15,
                    width: 15,
                  ),
                ],
              ),
              Spacer(),
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
                            color: product['inStock'] == 'true'
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
                              color: product['inStock'] == 'true'
                                  ? AppColors.activeGreen
                                  : AppColors.inActiveRed,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        product['inStock'] == 'true'
                            ? " In Stock"
                            : " Out of Stock",
                        style: AppTextStyles.black8_500.copyWith(
                            fontSize: 8,
                            color: product['inStock'] == 'true'
                                ? AppColors.activeGreen
                                : AppColors.errorRed),
                      ),
                    ],
                  ),
                  product['inStock'] == 'true'
                      ? Text(
                          '(100 units available)',
                          style: AppTextStyles.black8_500
                              .copyWith(color: Colors.grey.shade600),
                        )
                      : SizedBox.shrink(),
                ],
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
