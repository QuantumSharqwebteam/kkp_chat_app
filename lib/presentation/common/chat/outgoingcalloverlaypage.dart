import 'package:flutter/material.dart';
import 'package:kkpchatapp/presentation/common/chat/outgoing_call_ui.dart';

class OutgoingCallOverlayPage extends StatelessWidget {
  final VoidCallback onTap;

  const OutgoingCallOverlayPage({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: OutgoingCallUI(onTap: onTap),
        ),
      ),
    );
  }
}
