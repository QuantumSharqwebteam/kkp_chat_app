import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/config/theme/image_constants.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/presentation/common_widgets/profile_avatar.dart';

class ManageCustomers extends StatefulWidget {
  const ManageCustomers({super.key});

  @override
  State<ManageCustomers> createState() => _ManageCustomersState();
}

class _ManageCustomersState extends State<ManageCustomers> {
  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> customers = [
      {
        "name": "Shyam Mohan",
        "role": "Customer",
        "image": "assets/images/user1.png",
        "isActive": true
      },
      {
        "name": "Krishna Deor",
        "role": "Customer",
        "image": "assets/images/user2.png",
        "isActive": false
      },
      {
        "name": "Ramesh Textile",
        "role": "Customer",
        "image": "assets/images/user3.png",
        "isActive": true
      },
      {
        "name": "K.N Cottons",
        "role": "Customer",
        "image": "assets/images/user4.png",
        "isActive": false
      },
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        title: Text(
          "View and manage customers ",
          style: AppTextStyles.black16_500,
        ),
        actions: [
          CircleAvatar(
            backgroundImage: AssetImage(ImageConstants.userImage),
            radius: 20,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 10,
              bottom: 10,
            ),
            child: Text(
              " Customers List",
              style: AppTextStyles.blue4A76CD_24_600.copyWith(
                color: AppColors.grey525252,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: customers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final customer = customers[index];
                return Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  elevation: 5,
                  child: ListTile(
                    tileColor: Colors.white,
                    leading: ProfileAvatar(
                        image: customer["image"],
                        isActive: customer["isActive"]),
                    title: Text(
                      customer['name'],
                      style: AppTextStyles.black14_600,
                    ),
                    subtitle: Text(
                      customer['role'],
                      style: AppTextStyles.grey12_600,
                    ),
                    trailing: PopupMenuButton<int>(
                      color: Colors.white,
                      surfaceTintColor: Colors.white,
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 1) {
                          Utils().showSuccessDialog(context, "Blocked", true);
                        } else if (value == 2) {}
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 1,
                          child: Text('Block Chat'),
                        ),
                        const PopupMenuItem(
                          value: 2,
                          child: Text('Remove Chat'),
                        ),
                        const PopupMenuItem(
                          value: 3,
                          child: Text('More details'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
