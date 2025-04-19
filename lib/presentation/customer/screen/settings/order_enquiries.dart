import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_search_field.dart';

class OrderEnquiries extends StatelessWidget {
  OrderEnquiries({super.key});
  final _searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        title: Text(
          'Order Enquiries',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: Utils().width(context),
              color: AppColors.background,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: CustomSearchBar(
                width: Utils().width(context),
                enable: true,
                controller: _searchController,
                hintText: 'Search',
              ),
            ),
            ListTile(
              horizontalTitleGap: 40,
              isThreeLine: true,
              leading: Image.asset(
                'assets/images/description.png',
                height: 100,
                fit: BoxFit.contain,
              ),
              title: Text(
                'Cotton T-Shirt',
                style: AppTextStyles.black16_600,
              ),
              subtitle: Text(
                'Size:L, Color:Blue\nQty:2',
                style: AppTextStyles.black14_400,
              ),
            ),
            Divider(
              color: Colors.black,
              thickness: 1,
            ),
            ListTile(
              horizontalTitleGap: 40,
              isThreeLine: true,
              leading: Image.asset(
                'assets/images/description.png',
                height: 100,
                fit: BoxFit.contain,
              ),
              title: Text(
                'Cotton T-Shirt',
                style: AppTextStyles.black16_600,
              ),
              subtitle: Text(
                'Size:L, Color:Blue\nQty:2',
                style: AppTextStyles.black14_400,
              ),
            ),
            Divider(
              color: Colors.black,
              thickness: 1,
            ),
          ],
        ),
      ),
    );
  }
}
