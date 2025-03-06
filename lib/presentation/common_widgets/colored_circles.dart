import 'package:flutter/material.dart';

class ColoredCircles extends StatelessWidget {
  final List<Color> colors;
  final double size;

  const ColoredCircles({
    super.key,
    required this.colors,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(colors.length, (index) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colors[index],
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.black54, width: 1),
                ),
                height: size,
                width: size,
              ),
              if (index < colors.length - 1)
                SizedBox(width: 5), // Add spacing between circles
            ],
          ),
        );
      }).toList(),
    );
  }
}
