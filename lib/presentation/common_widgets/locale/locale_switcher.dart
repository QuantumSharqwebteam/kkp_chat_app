import 'package:flutter/material.dart';
import 'package:kkpchatapp/logic/locale/locale_provider.dart';
import 'package:provider/provider.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);

    return DropdownButton<Locale>(
      value: provider.locale,
      onChanged: (locale) {
        if (locale != null) {
          provider.setLocale(locale); // 👈 will save to Hive automatically
        }
      },
      items: const [
        DropdownMenuItem(
          value: Locale('en', 'US'),
          child: Text("English"),
        ),
        DropdownMenuItem(
          value: Locale('hi', 'IN'),
          child: Text("हिन्दी"),
        ),
      ],
    );
  }
}
