import 'package:flutter/material.dart';

class OutgoingCallUI extends StatelessWidget {
  final VoidCallback onTap;

  const OutgoingCallUI({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Ongoing Call',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Icon(Icons.call, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
