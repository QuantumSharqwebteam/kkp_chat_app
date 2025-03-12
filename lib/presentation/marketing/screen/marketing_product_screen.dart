import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/marketing_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_search_bar.dart';
import 'package:kkp_chat_app/presentation/customer/widget/product_item.dart';

class MarketingProductScreen extends StatefulWidget {
  const MarketingProductScreen({super.key});

  @override
  State<MarketingProductScreen> createState() => _MarketingProductScreenState();
}

class _MarketingProductScreenState extends State<MarketingProductScreen> {
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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProductsList(),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        height: 110,
        width: 110,
        child: FloatingActionButton(
          elevation: 10,
          tooltip: "Upload new product here",
          onPressed: () {
            Navigator.pushNamed(context, MarketingRoutes.addProductScreen);
          },
          backgroundColor: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.cloud_upload, size: 80, color: AppColors.grey7B7B7B),
              Text("Upload Product", style: AppTextStyles.black10_600),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: Utils().height(context) * 0.14,
      backgroundColor: AppColors.background,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Product",
                style: AppTextStyles.black20_600,
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(
                      context, MarketingRoutes.marketingNotifications);
                },
                icon: Icon(
                  Icons.notifications_active_outlined,
                ),
                iconSize: 25,
              ),
            ],
          ),
          CustomSearchBar(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          padding: EdgeInsets.only(bottom: 5),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            maxCrossAxisExtent: 250,
            mainAxisExtent: 200,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductItem(
              product: product,
              onTap: () {
                Navigator.pushNamed(
                    context, MarketingRoutes.marketingProductDescription);
              },
            );
          },
        ),
      ],
    );
  }

  // Widget _buildUploadProductContainer() {
  //   return GestureDetector(
  //     onTap: () {
  //       Navigator.pushNamed(context, MarketingRoutes.addProductScreen);
  //     },
  //     child: Card(
  //       color: Colors.white,
  //       surfaceTintColor: Colors.white,
  //       elevation: 5,
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Icon(Icons.cloud_upload, size: 100, color: AppColors.grey7B7B7B),
  //           SizedBox(height: 10),
  //           Text("Upload Product", style: TextStyle(fontSize: 14)),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
