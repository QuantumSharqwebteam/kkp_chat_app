import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';

class CustomSettingsTile extends StatelessWidget {
  final Text? title;
  final int numberOfTiles;
  final List<Widget>? leadingWidgets;
  final List<String>? titles;
  final List<String?>? subtitles;
  final String? description;
  final List<VoidCallback?>? onTaps;
  final bool isDense;
  final bool showDividerAfterTitle;

  // Optional style customizations
  final TextStyle? titleStyle;
  final TextStyle? tileTitleStyle;
  final TextStyle? tileSubtitleStyle;
  final TextStyle? descriptionStyle;
  final Color? trailingIconColor;

  const CustomSettingsTile({
    super.key,
    this.title,
    required this.numberOfTiles,
    this.leadingWidgets = const [],
    this.titles = const [],
    this.subtitles,
    this.description,
    this.onTaps,
    this.isDense = false,
    this.titleStyle,
    this.tileTitleStyle,
    this.tileSubtitleStyle,
    this.descriptionStyle,
    this.trailingIconColor,
    this.showDividerAfterTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: title!,
          ),
          if (showDividerAfterTitle)
            Divider(
              thickness: 1,
              height: 0,
              color: AppColors.greyE5E7EB, // light gray
            ),
        ],
        Column(
          children: List.generate(numberOfTiles, (index) {
            return ListTile(
              visualDensity: VisualDensity.compact,
              dense: isDense,
              onTap: onTaps?[index],
              leading: leadingWidgets != null && index < leadingWidgets!.length
                  ? leadingWidgets![index]
                  : null,
              title: titles != null && index < titles!.length
                  ? Text(
                      titles![index],
                      style: tileTitleStyle ??
                          const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                    )
                  : null,
              subtitle: subtitles != null &&
                      index < subtitles!.length &&
                      subtitles![index] != null
                  ? Text(
                      subtitles![index]!,
                      style: tileSubtitleStyle ??
                          const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                    )
                  : null,
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 20,
                color: trailingIconColor ?? Colors.black,
              ),
            );
          }),
        ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              description!,
              style: descriptionStyle ??
                  const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
            ),
          ),
      ],
    );
  }
}
