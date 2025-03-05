import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/customer_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_search_field.dart';
import 'package:kkp_chat_app/presentation/customer/widget/product_item.dart';

class CustomerProductsPage extends StatelessWidget {
  CustomerProductsPage({super.key});

  final List<Map<String, String>> products = [
    {
      'imageUrl': 'assets/images/product1.png',
      'title': 'Denim Jacket',
      'inStock': 'true'
    },
    {
      'imageUrl': 'assets/images/product1.png',
      'title': 'T-Shirt',
      'inStock': 'false'
    },
    {
      'imageUrl': 'assets/images/product1.png',
      'title': 'Sneakers',
      'inStock': 'true'
    },
    // Add more products as needed
  ];

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        title: Text(
          'Product',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(
                    context, CustomerRoutes.customerNotification);
              },
              icon: const Icon(
                Icons.notifications_active_outlined,
                color: Colors.black,
                size: 28,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: Utils().width(context),
              color: AppColors.background,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: CustomSearchBar(
                  width: Utils().width(context),
                  enable: true,
                  controller: searchController,
                  hintText: 'Search Here...'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Previous Products',
                        style: AppTextStyles.black18_600,
                      ),
                      InkWell(
                        onTap: () {},
                        child: Text(
                          'See All',
                          style: AppTextStyles.black12_400.copyWith(
                              color: AppColors.helperOrange,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  GridView.builder(
                    padding: EdgeInsets.only(bottom: 5),
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        maxCrossAxisExtent: 250,
                        mainAxisExtent: 200),
                    itemCount: 2, //products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductItem(product: product);
                    },
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fashion',
                        style: AppTextStyles.black18_600,
                      ),
                      InkWell(
                        onTap: () {},
                        child: Text(
                          'See All',
                          style: AppTextStyles.black12_400.copyWith(
                              color: AppColors.helperOrange,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  GridView.builder(
                    padding: EdgeInsets.only(bottom: 5),
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        maxCrossAxisExtent: 250,
                        mainAxisExtent: 200),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductItem(product: product);
                    },
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
