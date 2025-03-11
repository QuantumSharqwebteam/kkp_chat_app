import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/presentation/admin/widgets/agent_avatar.dart';

class AgentManagementListTile extends StatelessWidget {
  final String title;
  final String subtitle;

  final String image;
  final String status;
  const AgentManagementListTile(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.image,
      required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.maxFinite,
        decoration: BoxDecoration(color: Colors.white),
        child: ListTile(
          leading: AgentAvatar(image: image, status: status),
          title: Text(
            title,
            style: AppTextStyles.black16_500,
          ),
          subtitle: Text(
            subtitle,
            style: AppTextStyles.grey5C5C5C_16_600,
          ),
        ));
  }
}
