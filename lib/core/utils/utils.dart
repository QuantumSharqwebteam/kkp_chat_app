import 'package:flutter/material.dart';
import 'package:kkp_chat_app/presentation/common_widgets/sucees_dialog.dart';

class Utils {
  double width(context) {
    return MediaQuery.of(context).size.width;
  }

  double height(context) {
    return MediaQuery.of(context).size.height;
  }

  Orientation orientation(context) {
    return MediaQuery.of(context).orientation;
  }

  void showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => SuccessDialog(message: message),
    );
  }
}
