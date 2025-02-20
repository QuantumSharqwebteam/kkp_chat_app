import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/customer_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';

class CustomerHomePage extends StatelessWidget {
  CustomerHomePage({super.key});

  final List<String> imageUrls = [
    "assets/images/carousel_image1.png",
    "assets/images/carousel_image1.png",
    "assets/images/carousel_image1.png",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _customAppBar(context),
            SizedBox(height: 10),
            _carousel(),
            SizedBox(height: 10),
            SizedBox(
              width: Utils().width(context) * 0.9,
              child: Column(
                children: [
                  _enquirySupport(),
                  SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      trailing: IconButton(
        onPressed: () {
          Navigator.pushNamed(context, CustomerRoutes.customerNotification);
        },
        icon: const Icon(
          Icons.notifications_active_outlined,
          color: Colors.black,
          size: 28,
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

Widget _enquirySupport() {
  return Card(
    color: Colors.white,
    elevation: 5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    child: ListTile(
      leading: Stack(children: [
        CircleAvatar(
          radius: 25,
          backgroundImage: AssetImage("assets/images/profile.png"),
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
