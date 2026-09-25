import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/presentation/common/chat/call_history_screen.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';

class CustomAppBar extends StatefulWidget {
  const CustomAppBar({
    super.key,
    this.name,
    this.profileUrl,
    this.notificationCount,
    this.onNotificationTap,
  });
  final String? name;
  final String? profileUrl;
  final int? notificationCount;
  final VoidCallback? onNotificationTap;

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      onTap: () {
        // Navigator.pushNamed(context, CustomerRoutes.customerProfileSetup);
      },
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(70),
        child: _buildAvatar(),
      ),
      title: Text(widget.name ?? "", style: AppTextStyles.black16_500),
      subtitle:
          Text("Let's find latest messages", style: AppTextStyles.black12_400),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CallHistoryScreen()),
              );
            },
            icon: Icon(
              Icons.call_outlined,
              color: Colors.black,
              size: 28,
            ),
          ),
          _buildNotificationIcon(),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    final count = widget.notificationCount;
    final hasCount = count != null && count > 0;

    return IconButton(
      onPressed: widget.onNotificationTap ??
          () {
            Navigator.pushNamed(context, CustomerRoutes.customerNotification);
          },
      icon: hasCount
          ? Badge(
              label: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.red,
              child: const Icon(
                Icons.notifications_active_outlined,
                color: Colors.black,
                size: 28,
              ),
            )
          : const Icon(
              Icons.notifications_active_outlined,
              color: Colors.black,
              size: 28,
            ),
    );
  }

  Widget _buildAvatar() {
    final url = widget.profileUrl;
    if (url != null && url.isNotEmpty && url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: 20,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => Initicon(
          text: widget.name ?? "",
          size: 40,
        ),
        errorWidget: (context, url, error) => Initicon(
          text: widget.name ?? "",
          size: 40,
        ),
      );
    }
    return Initicon(
      text: widget.name ?? "",
      size: 40,
    );
  }
}
