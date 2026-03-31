import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/image_constants.dart';

class EmptyInquriesWidget extends StatelessWidget {
  const EmptyInquriesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            ImageConstants.emptyInquries,
            width: 300,
            height: 300,
          ),
          const SizedBox(height: 20),
          Text(
            "No inquries yet.",
            style: TextStyle(fontSize: 18),
          )
        ],
      ),
    );
  }
}
