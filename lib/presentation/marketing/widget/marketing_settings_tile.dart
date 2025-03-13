import 'package:flutter/material.dart';

class MarketingSettingsTile extends StatefulWidget {
  final String title;
  final List<String> subTitles;
  final List<VoidCallback> onTapActions;
  final IconData leadingIcon;

  const MarketingSettingsTile({
    super.key,
    required this.title,
    required this.subTitles,
    required this.onTapActions,
    required this.leadingIcon,
  });

  @override
  State<MarketingSettingsTile> createState() => _MarketingSettingsTileState();
}

class _MarketingSettingsTileState extends State<MarketingSettingsTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(widget.leadingIcon, size: 28, color: Colors.black87),
          title: Text(
            widget.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          trailing: IconButton(
            icon: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 24,
            ),
            onPressed: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
          ),
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
        ),
        if (isExpanded)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(widget.subTitles.length, (index) {
              return GestureDetector(
                onTap: widget.onTapActions[index], // Handle tap action
                child: Padding(
                  padding: const EdgeInsets.only(left: 55, bottom: 8),
                  child: Text(
                    widget.subTitles[index],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue, // Change color if needed
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }
}
