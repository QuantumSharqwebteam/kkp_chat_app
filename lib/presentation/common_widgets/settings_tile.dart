import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final String? title;
  final int numberOfTiles;
  final List<IconData>? leadingIcons;
  final List<String>? titles;
  final List<String?>? subtitles;
  final String? description;
  final List<VoidCallback?>? onTaps;
  final bool isDense;

  const SettingsTile({
    super.key,
    this.title = '',
    required this.numberOfTiles,
    this.leadingIcons = const [],
    this.titles = const [],
    this.subtitles,
    this.description,
    this.onTaps,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title!,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black),
            ),
          ),
        Column(
          children: List.generate(numberOfTiles, (index) {
            return ListTile(
              visualDensity: VisualDensity.compact,
              dense: isDense,
              onTap: onTaps?[index],
              leading: leadingIcons != null && index < leadingIcons!.length
                  ? Icon(
                      leadingIcons![index],
                      size: 30,
                      color: Colors.black,
                    )
                  : null,
              title: titles != null && index < titles!.length
                  ? Text(
                      titles![index],
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black),
                    )
                  : null,
              subtitle: subtitles != null &&
                      index < subtitles!.length &&
                      subtitles![index] != null
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
