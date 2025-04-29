import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Full white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'About Us',
          style: AppTextStyles.black18_600,
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KKP',
              style: AppTextStyles.black16_700,
            ),
            const SizedBox(height: 8),
            const Text(
              'KKP is a leading name in the textile industry, known for quality yarn production and smart supply chain management. '
              'With years of trusted service, we bring transparency, innovation, and reliability to every process.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Who We Are',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("We’re a textile-focused company delivering:"),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• Premium quality yarn"),
                  Text("• Timely deliveries"),
                  Text("• Transparent operations"),
                  Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text(
                      "Our platform connects agents, buyers, and mills in one unified system — "
                      "making order management easier than ever.",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Our Mission',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'To simplify textile operations with speed, clarity, and digital tools.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Our Vision',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'To be the leading tech-powered solution in the textile industry.',
            ),
          ],
        ),
      ),
    );
  }
}
