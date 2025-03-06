import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/colored_circles.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';

class CustomerProductDescriptionPage extends StatelessWidget {
  const CustomerProductDescriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, 100),
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
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
            Image.asset(
              'assets/images/description.png',
              height: Utils().height(context) * 0.6,
              width: Utils().width(context),
              fit: BoxFit.cover,
            ),
            Padding(
              padding:
                  const EdgeInsets.only(top: 10, right: 8, left: 8, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Men\'s wear. Raymond T-shirts',
                    style: AppTextStyles.black22_600,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'apparel and accessories for men. cloth, especially wool, used for men\'s and often women\'s tailored garments..details',
                      style: AppTextStyles.black12_400,
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Colors',
                          style: AppTextStyles.black16_500
                              .copyWith(color: Colors.black, fontSize: 17),
                        ),
                        SizedBox(height: 5),
                        ColoredCircles(colors: [
                          Colors.red,
                          Colors.yellow,
                          Colors.blue,
                          Colors.white,
                          Colors.green,
                        ], size: 35),
                        SizedBox(height: 5),
                        Text(
                          'Only 50 left in Stock',
                          style: AppTextStyles.black8_500
                              .copyWith(color: AppColors.inActiveRed),
                        ),
                        SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomButton(
                              text: 'Available',
                              onPressed: () {},
                              width: Utils().width(context) * 0.43,
                              height: 35,
                              borderRadius: 5,
                              backgroundColor: Colors.white,
                              textColor: AppColors.blue,
                            ),
                            CustomButton(
                              text: 'Notify Me',
                              onPressed: () {},
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
