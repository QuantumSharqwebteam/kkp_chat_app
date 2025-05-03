import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/config/theme/image_constants.dart';

class ManageCustomerListItem extends StatelessWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onMoreDetails;

  const ManageCustomerListItem(
      {super.key, required this.customer, required this.onMoreDetails});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 5,
      child: ListTile(
        tileColor: Colors.white,
        leading: CircleAvatar(
          backgroundImage: customer['profileUrl'] != null &&
                  customer['profileUrl'].isNotEmpty
              ? NetworkImage(customer['profileUrl'])
              : AssetImage(ImageConstants.profileAvatar)
                  as ImageProvider, // Replace with your placeholder image path
        ),
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
              //Utils().showSuccessDialog(context, "Blocked", true);
            } else if (value == 2) {
              // Handle remove chat
            } else if (value == 3) {
              onMoreDetails();
            }
          },
          itemBuilder: (context) => [
            // const PopupMenuItem(
            //   value: 1,
            //   child: Text('Block Chat'),
            // ),
            // const PopupMenuItem(
            //   value: 2,
            //   child: Text('Remove Chat'),
            // ),
            const PopupMenuItem(
              value: 3,
              child: Text('More details'),
            ),
          ],
        ),
      ),
    );
  }
}
