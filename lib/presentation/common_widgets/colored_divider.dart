import 'package:flutter/material.dart';

class ColoredDivider extends StatelessWidget {
  const ColoredDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      height: 4,
      decoration: BoxDecoration(
          color: Color(0xffF2F2F2),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              spreadRadius: 0,
              blurRadius: 4,
              color: Color(0xffF2F2F2),
            )
          ]),
    );
  }
}
