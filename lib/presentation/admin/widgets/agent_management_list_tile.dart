import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/presentation/admin/widgets/agent_avatar.dart';

class AgentManagementListTile extends StatelessWidget {
  final String title;
  final String subtitle;

  final String name;
  final bool isOnline;
  const AgentManagementListTile(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.name,
      required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.maxFinite,
        decoration: BoxDecoration(color: Colors.white),
        child: ListTile(
          leading: AgentAvatar(name: name, isOnline: isOnline),
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
