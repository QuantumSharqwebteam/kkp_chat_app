import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/customer_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/presentation/customer/widget/product_item.dart';

class CustomerHomePage extends StatelessWidget {
  CustomerHomePage({super.key});

  final List<String> imageUrls = [
    "assets/images/carousel_image1.png",
    "assets/images/carousel_image1.png",
    "assets/images/carousel_image1.png",
  ];

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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, 100),
        child: SafeArea(
          child: _customAppBar(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 10),
              _carousel(),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(15),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _enquirySupport(onTap: () {
                      Navigator.pushNamed(
                          context, CustomerRoutes.customerSupportChat);
                    }),
                    SizedBox(height: 20),
                    Text(
                      'New Products',
                      style: AppTextStyles.black18_600,
                    ),
                    // ProductItem(product: products[0]),
                    SizedBox(
                      height: 200, // Set a fixed height for the scrollable list
                      child: ListView.builder(
                        padding: EdgeInsets.only(bottom: 5),
                        scrollDirection: Axis.horizontal,
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: ProductItem(product: product),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Previous Products',
                      style: AppTextStyles.black18_600,
                    ),
                    // ProductItem(product: products[0]),
                    SizedBox(
                      height: 200, // Set a fixed height for the scrollable list
                      child: ListView.builder(
                        padding: EdgeInsets.only(bottom: 5),
                        scrollDirection: Axis.horizontal,
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: ProductItem(product: product),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customAppBar(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      leading: CircleAvatar(
        radius: 26,
        backgroundImage: AssetImage("assets/images/profile.png"),
      ),
      title: Text("John", style: AppTextStyles.black16_500),
      subtitle:
          Text("Let's find latest messages", style: AppTextStyles.black12_400),
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: IconButton(
          onPressed: () {
            Navigator.pushNamed(context, CustomerRoutes.customerNotification);
          },
          icon: const Icon(
            Icons.notifications_active_outlined,
            color: Colors.black,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _carousel() {
    return CarouselSlider(
      options: CarouselOptions(
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 16 / 6,
        viewportFraction: 1,
      ),
      items: imageUrls.map((imageUrl) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(imageUrl, fit: BoxFit.fill),
        );
      }).toList(),
    );
  }
}

Widget _enquirySupport({VoidCallback? onTap}) {
  return Card(
    color: Colors.white,
    elevation: 5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    child: ListTile(
      onTap: onTap,
      leading: Stack(children: [
        CircleAvatar(
          radius: 25,
          backgroundImage: AssetImage("assets/images/user4.png"),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Material(
            elevation: 5,
            color: Colors.transparent,
            type: MaterialType.circle,
            child: Container(
              height: 12,
              width: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: AppColors.activeGreen,
              ),
            ),
          ),
        ),
      ]),
      title: Text(
        'Product Enquirers',
        style: AppTextStyles.black16_600,
      ),
      subtitle: Text(
        'How may I Help you?',
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.black12_400,
      ),
      trailing: Text(
        '2m',
        style: AppTextStyles.black12_700,
      ),
    ),
  );
}
