import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Privacy Policy",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ), // Back button color
      ),
      body: SizedBox(
        width: double.maxFinite,
        height: Utils().height(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: const Text(
                  "At KKP chat app, we respect your privacy and are committed to protecting your personal information. "
                  "This Privacy Policy explains how we collect, use, share, and safeguard your data when you use our chat application. "
                  "By using our services, you agree to the terms outlined in this policy.\n\n"
                  "The collected data is used to provide seamless messaging services, enhance app security, analyze usage patterns, and improve customer support. "
                  "Your messages are end-to-end encrypted to maintain confidentiality, and we implement security measures like secure cloud storage and restricted data access to protect your information. "
                  "We do not sell or share your personal data with third-party advertisers. However, data may be shared with legal authorities if required by law or to prevent fraud and security threats.\n\n"
                  "For any questions or concerns regarding this Privacy Policy, you can contact us at [support@kkpchatpp.com]. "
                  "By continuing to use [Chat App Name], you acknowledge and agree to the terms outlined in this policy.",
                  style: AppTextStyles.grey12_600,
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.black10_600.copyWith(
                      color: Color(0xff121927), fontWeight: FontWeight.w500),
                  children: [
                    const TextSpan(
                        text: "By using KKP chat application, you agree\n"),
                    TextSpan(
                        text: "to the Terms and Privacy Policy",
                        style: AppTextStyles.black10_600
                            .copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
