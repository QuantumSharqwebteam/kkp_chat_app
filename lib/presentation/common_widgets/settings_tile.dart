import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final int numberOfTiles;
  final List<IconData> leadingIcons;
  final List<String> titles;
  final List<String?>? subtitles;
  final String? description;
  final List<VoidCallback?>? onTaps;

  const SettingsTile({
    super.key,
    required this.title,
    required this.numberOfTiles,
    required this.leadingIcons,
    required this.titles,
    this.subtitles,
    this.description,
    this.onTaps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
          ),
        ),
        Column(
          children: List.generate(numberOfTiles, (index) {
            return ListTile(
              onTap: onTaps?[index],
              leading: Icon(
                leadingIcons[index],
                size: 30,
                color: Colors.black,
              ),
              title: Text(
                titles[index],
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              subtitle: subtitles?[index] != null
                  ? Text(
                      subtitles![index]!,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.black),
                    )
                  : null,
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 20,
                color: Colors.black,
              ),
            );
          }).toList(),
        ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              description!,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black),
            ),
          ),
      ],
    );
  }
}
