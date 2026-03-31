import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Full white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.aboutUs,
          style: AppTextStyles.black18_600,
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.kKP,
              style: AppTextStyles.black16_700,
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.kKPDescription),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.whoWeAre,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.whoWeAreDescription),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.premiumQualityYarn),
                  Text(AppLocalizations.of(context)!.timelyDeliveries),
                  Text(AppLocalizations.of(context)!.transparentOperations),
                  Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text(
                      AppLocalizations.of(context)!.platformDescription,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.ourMission,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.missionStatement,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.ourVision,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.visionStatement,
            ),
          ],
        ),
      ),
    );
  }
}
